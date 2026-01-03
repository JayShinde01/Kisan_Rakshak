// lib/screens/diagnose_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_config.dart';
import '../services/cloudinary_service.dart';

class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({Key? key}) : super(key: key);

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _lastPickedFile;
  Uint8List? _lastPickedBytes;
  String? _lastPickedFileName;

  bool _isUploading = false;
  String? _predictionLabel;
  double? _predictionConfidence;
  String? _predictionImageUrl;
  String? _error;

  List<Map<String, dynamic>> _history = [];

  late final String API_BASE;
  late final String API_PREDICT;
  late final String API_HISTORY; // kept for compatibility

  static const double _cardRadius = 18.0;

  // TTS
  late final FlutterTts _flutterTts;
  double _speechRate = 0.45;
  static const String _prefsSpeechRateKey = 'speech_rate';

  // ===== Solution fields (retrieved from backend) =====
  String? _solutionShortDesc;
  String? _solutionRecommendedTreatment;
  List<String> _solutionSteps = [];
  List<String> _solutionPreventive = [];
  String? _solutionNotes;

  // Optional: cache solutions map to avoid repeated network calls during same session
  Map<String, dynamic>? _solutionsCache;

  @override
  void initState() {
    super.initState();
    final base = (ApiConfig.baseUrl != null && ApiConfig.baseUrl!.isNotEmpty)
        ? ApiConfig.baseUrl!
        : 'http://localhost:5000';
    API_BASE = base;
    API_PREDICT = '$API_BASE/api/predict';
    API_HISTORY = '$API_BASE/api/history';

    _initTts();
    _ensureAuthThenLoadHistory();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_prefsSpeechRateKey);
      if (saved != null) _speechRate = saved;

      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(1.0);

      // set language from app locale (best-effort)
      final localeTag = _localeTagFromLocale(context.locale) ?? 'en-US';
      try {
        await _flutterTts.setLanguage(localeTag);
      } catch (_) {
        // ignore if not supported on this device
      }

      // optional handlers (debug)
      _flutterTts.setStartHandler(() => debugPrint('TTS started'));
      _flutterTts.setCompletionHandler(() => debugPrint('TTS completed'));
      _flutterTts.setErrorHandler((msg) => debugPrint('TTS error: $msg'));
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  @override
  void dispose() {
    try {
      _flutterTts.stop();
    } catch (_) {}
    super.dispose();
  }

  String? _localeTagFromLocale(Locale? locale) {
    if (locale == null) return 'en-US';
    final code = locale.languageCode.toLowerCase();
    return _localeTagForLang(code);
  }

  String? _localeTagForLang(String? lang) {
    if (lang == null) return 'en-US';
    final code = lang.toLowerCase();
    const mapping = {
      'en': 'en-US',
      'en_us': 'en-US',
      'en_gb': 'en-GB',
      'hi': 'hi-IN',
      'mr': 'mr-IN',
      'bn': 'bn-IN',
      'gu': 'gu-IN',
      'kn': 'kn-IN',
      'ml': 'ml-IN',
      'ta': 'ta-IN',
      'te': 'te-IN',
      'ur': 'ur-PK',
      'ar': 'ar-SA',
      'fr': 'fr-FR',
      'es': 'es-ES',
      'de': 'de-DE',
      'ru': 'ru-RU',
      'ja': 'ja-JP',
      'zh': 'zh-CN',
      'pt': 'pt-PT',
    };
    if (mapping.containsKey(code)) return mapping[code];
    if (lang.contains('-') || lang.contains('_')) return lang;
    return 'en-US';
  }

  Future<void> _speakDiagnosis() async {
    if (_predictionLabel == null) return;
    try {
      final label = _predictionLabel!;
      final confPercent = _predictionConfidence != null ? (_predictionConfidence! * 100).toStringAsFixed(1) : '0.0';
      final spoken = tr('speak_diagnosis', args: [label, confPercent], namedArgs: {
        'label': label,
        'confidence': confPercent,
      });
      final textToSpeak = (spoken == 'speak_diagnosis') // easy_localization returns key when not found
          ? '${tr('diagnosis')}: $label. ${tr('confidence')}: $confPercent%.'
          : spoken;

      // set language again (best-effort)
      final langTag = _localeTagFromLocale(context.locale);
      if (langTag != null) {
        try {
          await _flutterTts.setLanguage(langTag);
        } catch (_) {}
      }

      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      debugPrint('Error speaking diagnosis: $e');
    }
  }

  Future<void> _ensureAuthThenLoadHistory() async {
    try {
      final auth = FirebaseAuth.instance;
      if (kIsWeb) {
        // set web persistence (best-effort)
        try {
          await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
        } catch (_) {}
      }
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    } catch (e, st) {
      debugPrint('Auth ensure error: $e\n$st');
    } finally {
      await _loadHistoryFromFirestore();
    }
  }

  /// ===== Helper: fetch solutions JSON and populate solution fields =====
  /// Robust: supports Map or List JSON, normalizes label, case-insensitive fallback,
  /// and accepts a variety of field names for steps/preventive/treatment.
  Future<void> _fetchSolutionForLabel(String label) async {
    if (label.isEmpty) return;
    final normLabel = label.trim();
    try {
      debugPrint('Fetching solution for label="$normLabel" (cache present=${_solutionsCache != null})');

      // If we have cache, use it; otherwise fetch
      if (_solutionsCache == null) {
        final uri = Uri.parse('$API_BASE/api/solutions');
        debugPrint('GET $uri');
        final resp = await http.get(uri);
        debugPrint('Solutions HTTP ${resp.statusCode}');
        if (resp.statusCode != 200) {
          debugPrint('Solutions fetch failed: ${resp.statusCode} ${resp.body}');
          return;
        }

        final body = resp.body;
        dynamic parsed;
        try {
          parsed = json.decode(body);
        } catch (e) {
          debugPrint('Failed to decode solutions JSON: $e -- body: ${body.length > 200 ? body.substring(0, 200) : body}');
          return;
        }

        if (parsed is Map<String, dynamic>) {
          _solutionsCache = parsed;
        } else if (parsed is List) {
          final Map<String, dynamic> map = {};
          for (final item in parsed) {
            if (item is Map<String, dynamic>) {
              final keyCandidates = <String?>[
                item['label']?.toString(),
                item['name']?.toString(),
                item['disease']?.toString(),
                item['title']?.toString(),
              ];
              final k = keyCandidates.firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null);
              if (k != null) map[k.trim()] = item;
            }
          }
          _solutionsCache = map;
        } else {
          debugPrint('Unexpected solutions JSON root type: ${parsed.runtimeType}');
          return;
        }
        debugPrint('Solutions cache loaded with ${_solutionsCache!.length} entries');
      }

      // Try direct key match first, then case-insensitive fallback
      Map<String, dynamic>? entry;
      if (_solutionsCache!.containsKey(normLabel)) {
        final e = _solutionsCache![normLabel];
        if (e is Map<String, dynamic>) entry = e;
      } else {
        final foundKey = _solutionsCache!.keys.firstWhere(
          (k) => k.toString().trim().toLowerCase() == normLabel.toLowerCase(),
          orElse: () => '',
        );
        if (foundKey.isNotEmpty) {
          final e = _solutionsCache![foundKey];
          if (e is Map<String, dynamic>) entry = e;
        }
      }

      if (entry == null) {
        debugPrint('No solution entry for label="$normLabel" (checked ${_solutionsCache!.length} keys)');
        if (!mounted) return;
        setState(() {
          _solutionShortDesc = null;
          _solutionRecommendedTreatment = null;
          _solutionSteps = [];
          _solutionPreventive = [];
          _solutionNotes = null;
        });
        return;
      }

      // --- robust parsing + safe setState replacement ---
      if (!mounted) return;

      // Normalize entry into a Map<String, dynamic> if possible
      Map<String, dynamic>? entryMap;
      try {
        if (entry is Map<String, dynamic>) {
          entryMap = entry;
        } else if (entry is String && entry.isNotEmpty) {
          // sometimes backend returns a JSON-encoded string
          try {
            final decoded = json.decode(entry as String);
            if (decoded is Map<String, dynamic>) entryMap = decoded;
          } catch (_) {
            // leave as null and fall back to using entry.toString()
          }
        } else if (entry != null) {
          // best-effort: convert other Map types
          try {
            entryMap = Map<String, dynamic>.from(entry as Map);
          } catch (_) {
            entryMap = null;
          }
        }
      } catch (e, st) {
        debugPrint('Entry normalization failed: $e\n$st');
        entryMap = null;
      }

      // Extract values defensively
      final shortDesc = entryMap?['short_description']?.toString()
          ?? entryMap?['short']?.toString()
          ?? entryMap?['summary']?.toString()
          ?? (entry is String ? entry.toString() : null);

      final recommended = entryMap?['recommended_treatment']?.toString()
          ?? entryMap?['treatment']?.toString()
          ?? entryMap?['recommendation']?.toString();

      final notes = entryMap?['notes']?.toString() ?? entryMap?['note']?.toString();

      final stepsRaw = entryMap?['steps'] ?? entryMap?['procedure'] ?? entryMap?['how_to'] ?? entryMap?['instructions'];
      final parsedSteps = _asStringList(stepsRaw);

      final prevRaw = entryMap?['preventive_measures'] ?? entryMap?['preventive'] ?? entryMap?['prevention'] ?? entryMap?['prevention_measures'];
      final parsedPrev = _asStringList(prevRaw);

      // finally update state with prepared values
      setState(() {
        _solutionShortDesc = shortDesc;
        _solutionRecommendedTreatment = recommended;
        _solutionNotes = notes;
        _solutionSteps = parsedSteps;
        _solutionPreventive = parsedPrev;
      });

      debugPrint('Populated solution for "$normLabel": short=${_solutionShortDesc != null}, steps=${_solutionSteps.length}, prev=${_solutionPreventive.length}');
    } catch (e, st) {
      debugPrint('Error fetching solution for $label: $e\n$st');
    }
  }

  // Helper: convert many possible shapes into List<String>
  List<String> _asStringList(dynamic v) {
    if (v == null) return <String>[];

    // Already a List or Iterable
    if (v is List) {
      return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    if (v is Iterable) {
      return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }

    // String: try JSON decode, then common split heuristics
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return <String>[];

      // Try JSON array encoded as string: '["a","b"]'
      if (s.startsWith('[') && s.endsWith(']')) {
        try {
          final parsed = json.decode(s);
          if (parsed is List) {
            return parsed.map((e) => e?.toString() ?? '').where((x) => x.isNotEmpty).toList();
          }
        } catch (_) {
          // ignore and fall back
        }
      }

      // If string contains newlines, split on them
      if (s.contains('\n')) {
        return s.split('\n').map((e) => e.trim()).where((x) => x.isNotEmpty).toList();
      }

      // If comma-separated, split on commas
      if (s.contains(',')) {
        return s.split(',').map((e) => e.trim()).where((x) => x.isNotEmpty).toList();
      }

      // Single plain string
      return <String>[s];
    }

    // Fallback: single element from any other type
    try {
      final str = v.toString();
      return str.isEmpty ? <String>[] : <String>[str];
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isUploading) return;
    setState(() {
      _lastPickedFile = null;
      _lastPickedBytes = null;
      _lastPickedFileName = null;
      _error = null;
    });

    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
        if (result == null || result.files.isEmpty) return;
        final picked = result.files.single;
        if (picked.bytes == null) throw Exception('Failed to read picked file bytes.');
        setState(() {
          _lastPickedBytes = picked.bytes;
          _lastPickedFileName = picked.name;
        });
      } else {
        final XFile? xfile = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1600);
        if (xfile == null) return;
        setState(() {
          _lastPickedFile = File(xfile.path);
          _lastPickedFileName = xfile.name;
        });
      }

      if (!mounted) return;
      if (_lastPickedFile != null || _lastPickedBytes != null) _showUploadConfirmationDialog();
    } catch (e, st) {
      debugPrint('Image pick error: $e\n$st');
      if (!mounted) return;
      setState(() => _error = tr('failed_pick_image', args: [e.toString()]));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('failed_pick_image', args: [e.toString()])), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _showUploadConfirmationDialog() {
    final theme = Theme.of(context);
    final Widget previewWidget = _lastPickedFile != null
        ? Image.file(_lastPickedFile!, fit: BoxFit.cover, height: 220)
        : _lastPickedBytes != null
            ? Image.memory(_lastPickedBytes!, fit: BoxFit.cover, height: 220)
            : const SizedBox(height: 220);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(child: Text(tr('confirm_photo'), style: theme.textTheme.titleLarge)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: previewWidget), const SizedBox(height: 12), Text(tr('confirm_photo_question'), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)]),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(ctx);
            setState(() {
              _lastPickedFile = null;
              _lastPickedBytes = null;
              _lastPickedFileName = null;
            });
          }, child: Text(tr('retake'))),
          ElevatedButton(onPressed: () {
            Navigator.pop(ctx);
            _startUploadProcess();
          }, child: Text(tr('diagnose_button'))),
        ],
      ),
    );
  }

  Future<void> _startUploadProcess() async {
    if (_isUploading) return;
    if (_lastPickedFile == null && _lastPickedBytes == null) {
      setState(() => _error = tr('no_image_selected'));
      return;
    }

    setState(() {
      _isUploading = true;
      _predictionLabel = null;
      _predictionConfidence = null;
      _predictionImageUrl = null;
      _error = null;

      // reset solution UI while new prediction is pending
      _solutionShortDesc = null;
      _solutionRecommendedTreatment = null;
      _solutionSteps = [];
      _solutionPreventive = [];
      _solutionNotes = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('uploading_diagnosis')), duration: const Duration(seconds: 2)));

    String? cloudinaryUrl;
    Map<String, dynamic>? serverJson;

    try {
      // 1) send to prediction API
      final uri = Uri.parse(API_PREDICT);
      final request = http.MultipartRequest('POST', uri);

      if (kIsWeb) {
        final bytes = _lastPickedBytes!;
        final filename = _lastPickedFileName ?? 'upload.jpg';
        final mimeType = _getMimeTypeFromFilename(filename) ?? 'image/jpeg';
        final mimeParts = mimeType.split('/');
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: MediaType(mimeParts.first, mimeParts.last)));
      } else {
        final file = _lastPickedFile!;
        final filename = _lastPickedFileName ?? file.path.split(Platform.pathSeparator).last;
        request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: filename));
      }

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode != 200) {
        String details = resp.body;
        try {
          final j = json.decode(resp.body);
          details = j['error'] ?? j['details'] ?? resp.body;
        } catch (_) {}
        throw Exception('Server responded ${resp.statusCode}: $details');
      }

      serverJson = json.decode(resp.body) as Map<String, dynamic>;
      // DEBUG: print server JSON head to help diagnose label mismatches
      try {
        debugPrint('Server JSON: ${serverJson.toString().length > 800 ? serverJson.toString().substring(0, 800) + "..." : serverJson.toString()}');
      } catch (_) {}

      final result = serverJson['result'] as String? ?? serverJson['prediction'] as String?;
      final confidence = (serverJson['confidence'] is num)
          ? (serverJson['confidence'] as num).toDouble()
          : (serverJson['confidence'] is String ? double.tryParse(serverJson['confidence']) : null);
      final imageUrlFromServer = serverJson['image_url'] ?? serverJson['image'] ?? serverJson['file_url'] ?? serverJson['filename'];

      setState(() {
        _predictionLabel = result ?? tr('unknown');
        _predictionConfidence = confidence ?? 0.0;
        if (imageUrlFromServer == null)
          _predictionImageUrl = null;
        else if (imageUrlFromServer.toString().startsWith('http'))
          _predictionImageUrl = imageUrlFromServer.toString();
        else {
          final s = imageUrlFromServer.toString();
          _predictionImageUrl = s.startsWith('/') ? API_BASE + s : API_BASE + '/' + s;
        }
      });

      // speak diagnosis (after state updated)
      await _speakDiagnosis();

      // Immediately fetch solution details for the predicted label (best-effort)
      if (_predictionLabel != null) {
        // DEBUG: you can temporarily force fresh fetch by uncommenting next line:
        // _solutionsCache = null;
        await _fetchSolutionForLabel(_predictionLabel!);
      }

      // 2) upload to Cloudinary
      if (!kIsWeb && _lastPickedFile != null) {
        cloudinaryUrl = await CloudinaryService.uploadImage(file: _lastPickedFile!, folder: "diagnoses");
      } else if (kIsWeb && _lastPickedBytes != null) {
        final fname = _lastPickedFileName ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
        cloudinaryUrl = await CloudinaryService.uploadImage(fileBytes: _lastPickedBytes, fileName: fname, folder: "diagnoses");
      }

      if (cloudinaryUrl != null) setState(() => _predictionImageUrl = cloudinaryUrl);

      // 3) save record to Firestore
      await _saveDiagnosisToFirestore(
        prediction: _predictionLabel ?? tr('unknown'),
        confidence: _predictionConfidence ?? 0.0,
        imageUrl: cloudinaryUrl ?? _predictionImageUrl,
        rawServerResponse: serverJson,
      );

      // 4) reload history
      await _loadHistoryFromFirestore();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('diagnosis')}: ${_predictionLabel ?? tr('unknown')} (${(_predictionConfidence ?? 0.0).toStringAsFixed(2)}%)')));

    } catch (e, st) {
      debugPrint('Upload/Prediction error: $e\n$st');
      setState(() => _error = tr('upload_prediction_failed', args: [e.toString()]));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('upload_prediction_failed', args: [e.toString()])), backgroundColor: Theme.of(context).colorScheme.error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _lastPickedFile = null;
          _lastPickedBytes = null;
          _lastPickedFileName = null;
        });
      }
    }
  }

  Future<void> _saveDiagnosisToFirestore({
    required String prediction,
    required double confidence,
    String? imageUrl,
    Map<String, dynamic>? rawServerResponse,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (e) {
          debugPrint('Anonymous sign-in before save failed: $e');
        }
      }

      final finalUser = FirebaseAuth.instance.currentUser;
      if (finalUser == null) {
        debugPrint('No authenticated user available for Firestore write; skipping save.');
        return;
      }

      final doc = <String, dynamic>{
        'prediction': prediction,
        'confidence': confidence,
        'image_url': imageUrl,
        'created_at': FieldValue.serverTimestamp(),
        'server_response': rawServerResponse,
        'userId': finalUser.uid,
      };

      final ref = await FirebaseFirestore.instance.collection('diagnoses').add(doc);
      debugPrint('Saved diagnosis doc id=${ref.id} for user=${finalUser.uid}');
    } catch (e, st) {
      debugPrint('Firestore write failed: $e\n$st');
      // don't rethrow — app UI should continue and show uploaded image result
    }
  }

  /// Loads history from both `diagnoses` and `crop_images` collections (if present),
  /// normalizes fields and sorts by timestamp descending. This guarantees that
  /// all previously uploaded images for the user are shown.
  Future<void> _loadHistoryFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('Loading history: currentUser=${user?.uid}');
      if (user == null) {
        setState(() => _history = []);
        return;
      }

      final List<Map<String, dynamic>> merged = [];

      Map<String, dynamic> _normalizeDoc(QueryDocumentSnapshot d) {
        final data = d.data() as Map<String, dynamic>;
        final imageUrl = data['image_url'] ?? data['imageUrl'] ?? data['image'] ?? data['imageUrl'];
        final createdAtRaw = data['created_at'] ?? data['createdAt'] ?? data['timestamp'] ?? data['time'] ?? data['ts'];
        DateTime? when;

        if (createdAtRaw is Timestamp) {
          when = createdAtRaw.toDate();
        } else if (createdAtRaw is DateTime) {
          when = createdAtRaw;
        } else if (createdAtRaw != null) {
          when = DateTime.tryParse(createdAtRaw.toString());
        }

        double confidenceVal = 0.0;
        if (data['confidence'] is num) confidenceVal = (data['confidence'] as num).toDouble();
        else if (data['confidence'] is String) confidenceVal = double.tryParse(data['confidence']) ?? 0.0;

        return {
          'id': d.id,
          'image_url': imageUrl,
          'result': data['prediction'] ?? data['result'] ?? data['disease'],
          'confidence': confidenceVal,
          'created_at': when?.toIso8601String(),
          '_ts': when ?? DateTime.fromMillisecondsSinceEpoch(0),
          'raw': data,
        };
      }

      Future<void> _queryCollection(String collectionName) async {
        try {
          final qs = await FirebaseFirestore.instance
              .collection(collectionName)
              .where('userId', isEqualTo: user.uid)
              .orderBy('created_at', descending: true)
              .limit(100)
              .get();

          debugPrint('Collection $collectionName returned ${qs.docs.length} docs');
          for (var d in qs.docs) merged.add(_normalizeDoc(d));
        } on FirebaseException catch (e) {
          // If ordering fails (index requirement or different field name), attempt fallback without orderBy
          debugPrint('Query on $collectionName failed: ${e.code} - ${e.message}');
          final link = RegExp(r'https://console\.firebase\.google\.com[^\s]+').firstMatch(e.message ?? '')?.group(0);
          if (link != null) debugPrint('Firestore console index link: $link');

          try {
            final qsFallback = await FirebaseFirestore.instance
                .collection(collectionName)
                .where('userId', isEqualTo: user.uid)
                .limit(200)
                .get();

            debugPrint('Fallback query on $collectionName returned ${qsFallback.docs.length} docs');
            for (var d in qsFallback.docs) merged.add(_normalizeDoc(d));
          } catch (fallbackErr, fallbackSt) {
            debugPrint('Fallback query failed for $collectionName: $fallbackErr\n$fallbackSt');
          }
        } catch (e, st) {
          debugPrint('Unexpected error querying $collectionName: $e\n$st');
        }
      }

      // Query both collections (diagnoses and crop_images)
      await _queryCollection('diagnoses');
      await _queryCollection('crop_images');

      // sort merged by timestamp descending
      merged.sort((a, b) {
        final ta = a['_ts'] as DateTime;
        final tb = b['_ts'] as DateTime;
        return tb.compareTo(ta);
      });

      // limit to 100 items
      final trimmed = merged.take(100).toList();

      // remove internal _ts before setting state
      for (var e in trimmed) {
        e.remove('_ts');
      }

      setState(() => _history = trimmed.cast<Map<String, dynamic>>());
      debugPrint('Merged history length=${_history.length}');
    } on FirebaseException catch (e) {
      debugPrint('Firestore history load error: ${e.code} - ${e.message}');
      final link = RegExp(r'https://console\.firebase\.google\.com[^\s]+').firstMatch(e.message ?? '')?.group(0);
      if (link != null) debugPrint('Firestore console index link: $link');
      setState(() => _history = []);
    } catch (e, st) {
      debugPrint('Unexpected history load error: $e\n$st');
      setState(() => _history = []);
    }
  }

  String? _getMimeTypeFromFilename(String name) {
    final lower = name.toLowerCase();
    if (!lower.contains('.')) return null;
    final ext = lower.split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  Widget _tipRow({required IconData icon, required String text, required ThemeData theme}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 18, color: theme.colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text(text, style: theme.textTheme.bodyMedium))]));
  }

  Widget _adviceContainer(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(_cardRadius)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('quick_tips_title'), style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700)), const SizedBox(height: 10), _tipRow(icon: Icons.lightbulb_outline, text: tr('tip_daylight'), theme: theme), _tipRow(icon: Icons.zoom_in, text: tr('tip_focus_area'), theme: theme), _tipRow(icon: Icons.grass_outlined, text: tr('tip_include_leaf'), theme: theme)]));
  }

  Widget _buildMainInteractiveArea(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final cardBg = theme.cardColor;

    if (_isUploading) {
      return Card(color: cardBg, elevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)), child: Padding(padding: const EdgeInsets.all(28.0), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: colorScheme.secondary), const SizedBox(height: 16), Text(tr('analyzing_image'), style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.secondary)), const SizedBox(height: 8), Text(tr('please_wait_processing'), textAlign: TextAlign.center)])));
    }

    if (_lastPickedFile != null || _lastPickedBytes != null) {
      final Widget previewWidget = !kIsWeb && _lastPickedFile != null ? Image.file(_lastPickedFile!, fit: BoxFit.cover, width: double.infinity) : kIsWeb && _lastPickedBytes != null ? Image.memory(_lastPickedBytes!, fit: BoxFit.cover, width: double.infinity) : Container(color: colorScheme.surfaceVariant, child: Center(child: Icon(Icons.broken_image, size: 50, color: colorScheme.error)));

      return Card(color: cardBg, elevation: 6, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(_cardRadius)), child: AspectRatio(aspectRatio: 4 / 3, child: previewWidget)), Padding(padding: const EdgeInsets.all(16.0), child: Row(children: [Expanded(child: ElevatedButton.icon(onPressed: _showUploadConfirmationDialog, icon: const Icon(Icons.check_circle_outline), label: Text(tr('confirm_and_diagnose')))), const SizedBox(width: 12), OutlinedButton.icon(onPressed: () => setState(() { _lastPickedFile = null; _lastPickedBytes = null; _lastPickedFileName = null; }), icon: const Icon(Icons.close), label: Text(tr('discard'))), ]))]));
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.camera_alt_outlined, size: 80, color: colorScheme.primary), const SizedBox(height: 16), Text(tr('start_diagnosing'), style: theme.textTheme.headlineSmall), const SizedBox(height: 10), Text(tr('take_picture_prompt'), textAlign: TextAlign.center), const SizedBox(height: 24), Row(mainAxisAlignment: MainAxisAlignment.center, children: [ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: Text(tr('camera'))), const SizedBox(width: 12), OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: Text(tr('gallery'))), ])]);
  }

  Widget _historyItem(Map<String, dynamic> item) {
    final result = item['result']?.toString() ?? item['prediction']?.toString() ?? tr('unknown');
    final confidence = (item['confidence'] is double || item['confidence'] is int) ? (item['confidence'].toString()) : (item['confidence']?.toString() ?? '');
    final filename = item['filename']?.toString();
    final imageUrlRaw = item['image_url'] ?? item['image'] ?? filename;
    final imageUrl = (imageUrlRaw == null) ? null : imageUrlRaw.toString().startsWith('http') ? imageUrlRaw.toString() : API_BASE + (imageUrlRaw.toString().startsWith('/') ? '' : '/') + imageUrlRaw.toString();
    final ts = item['created_at'] ?? item['timestamp'];
    final when = ts != null ? DateTime.tryParse(ts.toString()) : null;
    final whenLabel = when != null ? when.toLocal().toString() : '';

    return InkWell(
      onTap: imageUrl != null
          ? () {
              showDialog(context: context, builder: (ctx) => AlertDialog(content: imageUrl != null ? Image.network(imageUrl) : const SizedBox()));
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(width: 72, height: 72, color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 36));
                },
              ),
            )
          else
            Container(width: 72, height: 72, color: Colors.grey[200], child: const Icon(Icons.image, size: 36)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(result, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text('${confidence}% • $whenLabel', style: const TextStyle(fontSize: 12, color: Colors.black54))]))
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(children: [
                Text(tr('ai_powered_plant_doctor'), style: theme.textTheme.headlineSmall?.copyWith(fontSize: 26, color: theme.colorScheme.primary)),
                const SizedBox(height: 8),
                Text(tr('get_instant_diagnosis'), style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                _buildMainInteractiveArea(theme),
                const SizedBox(height: 22),
                if (_predictionLabel != null) ...[
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(children: [
                        if (_predictionImageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _predictionImageUrl!,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox(width: 96, height: 96, child: Center(child: Icon(Icons.broken_image))),
                            ),
                          )
                        else
                          const SizedBox(width: 96, height: 96),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_predictionLabel!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 6), Text('${tr('confidence')}: ${_predictionConfidence?.toStringAsFixed(2) ?? '0.00'}%', style: const TextStyle(fontSize: 14))]),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ======= Solution / Treatment Card =======
                  if (_solutionShortDesc != null || _solutionRecommendedTreatment != null || _solutionSteps.isNotEmpty || _solutionPreventive.isNotEmpty || _solutionNotes != null) ...[
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tr('recommended_action'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (_solutionShortDesc != null) Text(_solutionShortDesc!, style: theme.textTheme.bodyMedium),
                          if (_solutionRecommendedTreatment != null) ...[
                            const SizedBox(height: 10),
                            Text(tr('treatment'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(_solutionRecommendedTreatment!, style: theme.textTheme.bodyMedium),
                          ],
                          if (_solutionSteps.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(tr('steps'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _solutionSteps.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('• ', style: theme.textTheme.bodyMedium), Expanded(child: Text(s, style: theme.textTheme.bodyMedium))]),
                                )).toList()
                            )
                          ],
                          if (_solutionPreventive.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(tr('preventive_measures'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _solutionPreventive.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(children: [Text('• ', style: theme.textTheme.bodyMedium), Expanded(child: Text(s, style: theme.textTheme.bodyMedium))]),
                                )).toList()
                            )
                          ],
                          if (_solutionNotes != null) ...[
                            const SizedBox(height: 10),
                            Text(tr('notes'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(_solutionNotes!, style: theme.textTheme.bodySmall),
                          ]
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]
                ],
                if (_error != null) ...[
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.error_outline, color: Colors.red), const SizedBox(width: 10), Expanded(child: Text(_error!))])),
                  const SizedBox(height: 12),
                ],
                _adviceContainer(theme),
                const SizedBox(height: 28),
                Align(alignment: Alignment.centerLeft, child: Text(tr('recent_diagnoses'), style: theme.textTheme.titleMedium)),
                const SizedBox(height: 8),
                if (_history.isEmpty)
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: Center(child: Text(tr('no_history_yet')))),
                if (_history.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, idx) => _historyItem(_history[idx]),
                  ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
