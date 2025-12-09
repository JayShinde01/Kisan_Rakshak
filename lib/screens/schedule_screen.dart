// lib/screens/schedule_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Notification packages
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// For web notifications (we need NotificationOptions etc.)
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;


/// A lightweight schedule entry model.
class ScheduleEntry {
  final String id;
  String title;
  String action; // water, spray, fertilize, other
  DateTime dateTime;
  String repeat; // none/daily/weekly
  String notes;
  bool done;

  ScheduleEntry({
    required this.id,
    required this.title,
    required this.action,
    required this.dateTime,
    required this.repeat,
    required this.notes,
    this.done = false,
  });

  factory ScheduleEntry.fromMap(Map<String, dynamic> m) {
    return ScheduleEntry(
      id: m['id'] as String,
      title: m['title'] as String,
      action: m['action'] as String,
      dateTime: DateTime.parse(m['dateTime'] as String),
      repeat: m['repeat'] as String,
      notes: m['notes'] as String,
      done: m['done'] as bool? ?? false,
    );
  }

  /// Create from Firestore document map (handles Timestamp)
  factory ScheduleEntry.fromFirestore(Map<String, dynamic> m, String docId) {
    final dynamic dt = m['dateTime'];
    DateTime parsed;
    if (dt is Timestamp) {
      parsed = dt.toDate();
    } else if (dt is String) {
      parsed = DateTime.parse(dt);
    } else {
      parsed = DateTime.now();
    }

    return ScheduleEntry(
      id: docId,
      title: (m['title'] ?? '') as String,
      action: (m['action'] ?? 'water') as String,
      dateTime: parsed,
      repeat: (m['repeat'] ?? 'none') as String,
      notes: (m['notes'] ?? '') as String,
      done: (m['done'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'action': action,
      // Firestore prefers Timestamp but string is fine. We'll store Timestamp when writing.
      'dateTime': dateTime.toIso8601String(),
      'repeat': repeat,
      'notes': notes,
      'done': done,
    };
  }

  /// Map suitable for firestore: store Timestamp for dateTime
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'action': action,
      'dateTime': Timestamp.fromDate(dateTime),
      'repeat': repeat,
      'notes': notes,
      'done': done,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ScheduleEntry cloneWithNewId() {
    return ScheduleEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      action: action,
      dateTime: dateTime,
      repeat: repeat,
      notes: notes,
      done: done,
    );
  }
}

/// NotificationService - handles local scheduled notifications (native) and
/// a simple web fallback while the page is open.
class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance = NotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin _flnp = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Web-only: keep timers so scheduled notifications can be cancelled
  final Map<String, Timer> _webTimers = {};

  Future<void> init() async {
    if (_initialized) return;
    // Initialize timezone data
    tzdata.initializeTimeZones();

    // Attempt to set local timezone. For best results add `flutter_native_timezone` to pubspec
    // and use: final String tzName = await FlutterNativeTimezone.getLocalTimezone();
    // then tz.setLocalLocation(tz.getLocation(tzName));
    // Here we attempt a safe fallback: use the system local zone if possible.
    try {
      tz.setLocalLocation(tz.getLocation(tz.local.name));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    // Android initialization
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(
      android: androidInit,
      // iOS initialization left default; if you want iOS specifics, add them here
    );

    await _flnp.initialize(initSettings, onDidReceiveNotificationResponse: (payload) {
      // handle tap on notification if needed
    });

    // Web: request permission early if running on web
    if (kIsWeb) {
      await _requestWebPermission();
    }

    _initialized = true;
  }

  Future<void> _requestWebPermission() async {
    try {
      if (html.Notification != null && html.Notification.permission != 'granted') {
        await html.Notification.requestPermission();
      }
    } catch (_) {}
  }

  /// Schedule a notification at a specific DateTime.
  /// [id] - unique int id for the notification (use e.g. hashCode or parse id)
  /// [title], [body] - text for the notification
  Future<void> scheduleNotification({required String id, required DateTime dateTime, required String title, String? body}) async {
    await init();

    // If dateTime is in the past, don't schedule
    if (dateTime.isBefore(DateTime.now())) return;

    final int nid = _idFromString(id);

    if (kIsWeb) {
      // Web fallback: browsers don't support background scheduled notifications reliably.
      // We'll schedule a Timer that shows a Notification while the page is open.
      // NOTE: if user closes the tab, notification will not appear.
      // Cancel previous timer if present
      _webTimers[id]?.cancel();
      final delay = dateTime.difference(DateTime.now());
      final t = Timer(delay, () {
        _showWebNotification(id: id, title: title, body: body ?? '');
      });
      _webTimers[id] = t;
      return;
    }

    // Native platforms: use zonedSchedule for correct timezone handling
    final androidDetails = AndroidNotificationDetails(
      'schedule_channel',
      'Scheduled Notifications',
      channelDescription: 'Cropcare scheduled reminders',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final tz.TZDateTime tzDT = tz.TZDateTime.from(dateTime, tz.local);

    await _flnp.zonedSchedule(
      nid,
      title,
      body,
      tzDT,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      // We don't set matchDateTimeComponents — if you want daily/weekly repeats, handle separately
    );
  }

  Future<void> cancelNotification(String id) async {
    await init();
    final int nid = _idFromString(id);
    if (kIsWeb) {
      // cancel and remove stored timer if exists
      _webTimers[id]?.cancel();
      _webTimers.remove(id);
      return;
    }
    await _flnp.cancel(nid);
  }

  Future<void> cancelAll() async {
    await init();
    if (kIsWeb) {
      for (final t in _webTimers.values) {
        t.cancel();
      }
      _webTimers.clear();
      return;
    }
    await _flnp.cancelAll();
  }
Future<void> _showWebNotification(String title, String body) async {
  try {
    // Request permission if needed
    if (html.Notification.permission != 'granted') {
      final perm = await html.Notification.requestPermission();
      if (perm != 'granted') return;
    }

    // Build JS object for options
    final options = js_util.newObject();
    js_util.setProperty(options, 'body', body);
    js_util.setProperty(options, 'data', {'id': title});

    // Create notification
    final notif = html.Notification(title, options);

    // Click behavior
    notif.onClick.listen((_) {
      html.window.focus();
      notif.close();
    });

  } catch (e) {
    print("Web Notification Error: $e");
  }
}


  int _idFromString(String s) {
    // produce a stable int id from string (notification plugin expects int id)
    return s.hashCode & 0x7fffffff;
  }
}

/// Schedule screen
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _storageKey = 'cropcare_schedules_v1';

  List<ScheduleEntry> _entries = [];
  bool _loading = true;

  // Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _fsSub;

  @override
  void initState() {
    super.initState();
    // initialize notification service (safe to call repeatedly)
    NotificationService.instance.init();
    _loadEntries();
    // Also listen for auth changes so we can switch between local & remote
    _auth.userChanges().listen((user) {
      _attachFirestoreListenerIfNeeded();
      _loadEntries();
    });
    _attachFirestoreListenerIfNeeded();
  }

  @override
  void dispose() {
    _fsSub?.cancel();
    super.dispose();
  }

  Future<void> _attachFirestoreListenerIfNeeded() async {
    _fsSub?.cancel();
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final coll = _db.collection('users').doc(uid).collection('schedules');
    _fsSub = coll.snapshots().listen((snap) {
      final list = snap.docs.map((d) => ScheduleEntry.fromFirestore(d.data(), d.id)).toList();
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      setState(() {
        _entries = list;
        _loading = false;
      });
      _saveToLocal();
    }, onError: (err) {
      // ignore
    });
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    final uid = _auth.currentUser?.uid;

    if (uid != null) {
      try {
        final snap = await _db.collection('users').doc(uid).collection('schedules').get();
        final list = snap.docs.map((d) => ScheduleEntry.fromFirestore(d.data(), d.id)).toList();
        list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        setState(() {
          _entries = list;
          _loading = false;
        });
        await _saveToLocal();
        await _attachFirestoreListenerIfNeeded();
        return;
      } catch (e) {
        // Firestore failed — fall back to local cache
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> arr = json.decode(raw) as List<dynamic>;
        final list = arr.map((e) => ScheduleEntry.fromMap(e as Map<String, dynamic>)).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        setState(() {
          _entries = list;
        });
      } catch (_) {
        setState(() => _entries = []);
      }
    } else {
      setState(() => _entries = []);
    }

    setState(() => _loading = false);
  }

  Future<void> _saveEntries() async {
    await _saveToLocal();
    await _saveToFirestore();
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(_entries.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, raw);
  }

  Future<void> _saveToFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final coll = _db.collection('users').doc(uid).collection('schedules');

    try {
      final remoteSnap = await coll.get();
      final remoteIds = remoteSnap.docs.map((d) => d.id).toSet();
      final localIds = _entries.map((e) => e.id).toSet();

      for (final e in _entries) {
        await coll.doc(e.id).set(e.toFirestoreMap(), SetOptions(merge: true));
      }

      final toDelete = remoteIds.difference(localIds);
      for (final id in toDelete) {
        await coll.doc(id).delete();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _showAddEditDialog({ScheduleEntry? entry}) async {
    final isEdit = entry != null;
    final titleCtrl = TextEditingController(text: entry?.title ?? '');
    final notesCtrl = TextEditingController(text: entry?.notes ?? '');
    String action = entry?.action ?? 'water';
    String repeat = entry?.repeat ?? 'none';
    DateTime selectedDateTime = entry?.dateTime ?? DateTime.now().add(const Duration(hours: 1));
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setStateDialog) {
          Future<void> pickDateTime() async {
            final DateTime? pickedDate = await showDatePicker(
              context: ctx2,
              initialDate: selectedDateTime,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              builder: (c, child) => Theme(data: theme.copyWith(colorScheme: theme.colorScheme), child: child ?? const SizedBox.shrink()),
            );
            if (pickedDate == null) return;
            final TimeOfDay? pickedTime = await showTimePicker(
              context: ctx2,
              initialTime: TimeOfDay.fromDateTime(selectedDateTime),
            );
            if (pickedTime == null) return;
            selectedDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
            setStateDialog(() {});
          }

          return AlertDialog(
            title: Text(isEdit ? 'edit_schedule'.tr() : 'new_schedule'.tr(), style: theme.textTheme.titleLarge),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: InputDecoration(labelText: 'title_label'.tr(), hintText: 'title_hint'.tr()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('action_label'.tr(), style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: action,
                        items: [
                          DropdownMenuItem(value: 'water', child: Text('action_water'.tr())),
                          DropdownMenuItem(value: 'spray', child: Text('action_spray'.tr())),
                          DropdownMenuItem(value: 'fertilize', child: Text('action_fertilize'.tr())),
                          DropdownMenuItem(value: 'other', child: Text('action_other'.tr())),
                        ],
                        onChanged: (v) => setStateDialog(() => action = v ?? 'water'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: theme.iconTheme.color),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${_friendlyDateTime(selectedDateTime)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                      TextButton(onPressed: pickDateTime, child: Text('change'.tr())),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('repeat_label'.tr(), style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: repeat,
                        items: [
                          DropdownMenuItem(value: 'none', child: Text('repeat_none'.tr())),
                          DropdownMenuItem(value: 'daily', child: Text('repeat_daily'.tr())),
                          DropdownMenuItem(value: 'weekly', child: Text('repeat_weekly'.tr())),
                        ],
                        onChanged: (v) => setStateDialog(() => repeat = v ?? 'none'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: notesCtrl, decoration: InputDecoration(labelText: 'notes_label'.tr()), maxLines: 3),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx2), child: Text('cancel'.tr(), style: theme.textTheme.bodyMedium)),
              ElevatedButton(
                onPressed: () async {
                  final t = titleCtrl.text.trim();
                  if (t.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('please_give_title'.tr())));
                    return;
                  }

                  if (isEdit) {
                    entry!.title = t;
                    entry.action = action;
                    entry.repeat = repeat;
                    entry.dateTime = selectedDateTime;
                    entry.notes = notesCtrl.text.trim();
                    // update scheduled notification (cancel then schedule again)
                    await NotificationService.instance.cancelNotification(entry.id);
                    await NotificationService.instance.scheduleNotification(
                      id: entry.id,
                      dateTime: entry.dateTime,
                      title: entry.title,
                      body: entry.notes,
                    );
                  } else {
                    final newEntry = ScheduleEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: t,
                      action: action,
                      dateTime: selectedDateTime,
                      repeat: repeat,
                      notes: notesCtrl.text.trim(),
                    );
                    _entries.add(newEntry);
                    // schedule notification for the new entry
                    await NotificationService.instance.scheduleNotification(
                      id: newEntry.id,
                      dateTime: newEntry.dateTime,
                      title: newEntry.title,
                      body: newEntry.notes,
                    );
                  }

                  _entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                  await _saveEntries();
                  setState(() {});
                  Navigator.pop(ctx2);
                },
                child: Text(isEdit ? 'save'.tr() : 'add'.tr()),
              ),
            ],
          );
        });
      },
    );
  }

  Future<bool> _confirmDelete(ScheduleEntry entry) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('delete_schedule'.tr(), style: theme.textTheme.titleLarge),
        content: Text('remove_schedule_confirm'.tr(args: [entry.title])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr(), style: theme.textTheme.bodyMedium)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('delete'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red))),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _removeEntry(ScheduleEntry entry, {bool showSnack = true}) async {
    setState(() {
      _entries.removeWhere((it) => it.id == entry.id);
    });

    // cancel scheduled notification
    await NotificationService.instance.cancelNotification(entry.id);

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _db.collection('users').doc(uid).collection('schedules').doc(entry.id).delete();
      } catch (_) {}
    }

    await _saveToLocal();
    if (showSnack) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('schedule_deleted'.tr())));
    }
  }

  static String _friendlyDateTime(DateTime dt) {
    final datePart = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$datePart • $hour:$minute $ampm';
  }

  Future<void> _toggleDone(ScheduleEntry e) async {
    if (!e.done && e.repeat != 'none') {
      DateTime next = e.dateTime;
      if (e.repeat == 'daily') {
        next = e.dateTime.add(const Duration(days: 1));
      } else if (e.repeat == 'weekly') {
        next = e.dateTime.add(const Duration(days: 7));
      }
      e.dateTime = next;
      e.done = false;
      // reschedule notification for next occurrence
      await NotificationService.instance.cancelNotification(e.id);
      await NotificationService.instance.scheduleNotification(id: e.id, dateTime: e.dateTime, title: e.title, body: e.notes);
    } else {
      e.done = !e.done;
      if (e.done) {
        await NotificationService.instance.cancelNotification(e.id);
      } else {
        await NotificationService.instance.scheduleNotification(id: e.id, dateTime: e.dateTime, title: e.title, body: e.notes);
      }
    }

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _db.collection('users').doc(uid).collection('schedules').doc(e.id).set(e.toFirestoreMap(), SetOptions(merge: true));
      } catch (_) {}
    }

    await _saveToLocal();
    setState(() {});
  }

  Future<void> _clearCompleted() async {
    final completed = _entries.where((e) => e.done).toList();
    if (completed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('no_completed'.tr())));
      return;
    }

    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('clear_completed'.tr(), style: theme.textTheme.titleLarge),
        content: Text('remove_completed_confirm'.tr(args: [completed.length.toString()])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr(), style: theme.textTheme.bodyMedium)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('clear'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red))),
        ],
      ),
    );

    if (ok == true) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        for (final e in completed) {
          try {
            await _db.collection('users').doc(uid).collection('schedules').doc(e.id).delete();
            await NotificationService.instance.cancelNotification(e.id);
          } catch (_) {}
        }
      }

      setState(() => _entries.removeWhere((e) => e.done));
      await _saveToLocal();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('completed_cleared'.tr())));
    }
  }

  Future<void> _clearAll() async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('clear_all_schedules'.tr(), style: theme.textTheme.titleLarge),
        content: Text('remove_all_confirm'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr(), style: theme.textTheme.bodyMedium)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('clear_all'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red))),
        ],
      ),
    );

    if (ok == true) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        try {
          final coll = _db.collection('users').doc(uid).collection('schedules');
          final snap = await coll.get();
          for (final d in snap.docs) {
            await coll.doc(d.id).delete();
          }
        } catch (_) {}
      }

      // cancel all scheduled notifications (native + web)
      await NotificationService.instance.cancelAll();

      setState(() => _entries.clear());
      await _saveToLocal();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('all_schedules_cleared'.tr())));
    }
  }

  Future<void> _exportToClipboard() async {
    final raw = json.encode(_entries.map((e) => e.toMap()).toList());
    await Clipboard.setData(ClipboardData(text: raw));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('schedules_copied'.tr())));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;
    final cardColor = theme.cardColor;
    final iconColor = theme.iconTheme.color;

    return Scaffold(
      appBar: AppBar(
        title: Text('schedule_title'.tr()),
        backgroundColor: AgrioDemoApp.primaryGreen,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'clear_completed') {
                await _clearCompleted();
              } else if (v == 'clear_all') {
                await _clearAll();
              } else if (v == 'export') {
                await _exportToClipboard();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'clear_completed', child: Text('clear_completed'.tr())),
              PopupMenuItem(value: 'clear_all', child: Text('clear_all'.tr())),
              PopupMenuItem(value: 'export', child: Text('export_json'.tr())),
            ],
            icon: Icon(Icons.more_vert, color: iconColor),
          ),
          IconButton(
            icon: Icon(Icons.add_alert_outlined, color: iconColor),
            tooltip: 'add_quick_tooltip'.tr(),
            onPressed: () async {
              final quick = ScheduleEntry(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: 'quick_water'.tr(),
                action: 'water',
                dateTime: DateTime.now().add(const Duration(days: 1)).copyWith(hour: 7, minute: 0),
                repeat: 'none',
                notes: 'quick_added_note'.tr(),
              );
              setState(() {
                _entries.add(quick);
                _entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
              });
              // schedule notification for quick entry
              await NotificationService.instance.scheduleNotification(id: quick.id, dateTime: quick.dateTime, title: quick.title, body: quick.notes);
              await _saveEntries();
            },
          ),
          IconButton(icon: Icon(Icons.refresh, color: iconColor), tooltip: 'reload'.tr(), onPressed: () => _loadEntries()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        label: Text('add'.tr()),
        icon: const Icon(Icons.add),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primary))
          : _entries.isEmpty
              ? _emptyState(theme)
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: ListView.separated(
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final e = _entries[index];
                      return Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          final doDelete = await _confirmDelete(e);
                          if (doDelete) {
                            await _removeEntry(e);
                          }
                          return doDelete;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.delete_forever, color: Colors.white),
                        ),
                        child: Card(
                          color: cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            leading: _buildLeadingIcon(e, theme),
                            title: Text(e.title, style: TextStyle(decoration: e.done ? TextDecoration.lineThrough : null, color: theme.textTheme.bodyLarge?.color)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(_friendlyDateTime(e.dateTime), style: theme.textTheme.bodyMedium),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (e.repeat != 'none')
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                        child: Text(e.repeat.toUpperCase(), style: TextStyle(color: primary.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
                                      ),
                                    const SizedBox(width: 8),
                                    if (e.notes.isNotEmpty) Expanded(child: Text(e.notes, maxLines: 2, overflow: TextOverflow.ellipsis)),
                                  ],
                                )
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: Icon(Icons.edit_outlined, color: iconColor), tooltip: 'edit'.tr(), onPressed: () => _showAddEditDialog(entry: e)),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _toggleDone(e),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: e.done ? primary : theme.dividerColor, shape: BoxShape.circle),
                                    child: Icon(e.done ? Icons.check : Icons.check_box_outline_blank, color: e.done ? onPrimary : iconColor, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'delete') {
                                      final ok = await _confirmDelete(e);
                                      if (ok) await _removeEntry(e);
                                    } else if (v == 'duplicate') {
                                      final copy = e.cloneWithNewId();
                                      setState(() {
                                        _entries.add(copy);
                                        _entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                                      });
                                      // schedule notification for duplicate
                                      await NotificationService.instance.scheduleNotification(id: copy.id, dateTime: copy.dateTime, title: copy.title, body: copy.notes);
                                      await _saveEntries();
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('schedule_duplicated'.tr())));
                                    }
                                  },
                                  icon: Icon(Icons.more_vert, color: iconColor),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(value: 'duplicate', child: Text('duplicate'.tr())),
                                    PopupMenuItem(value: 'delete', child: Text('delete'.tr(), style: const TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ],
                            ),
                            onLongPress: () async {
                              final ok = await _confirmDelete(e);
                              if (ok) await _removeEntry(e);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note_outlined, size: 72, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('no_schedules'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('schedules_empty_desc'.tr(), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: () => _showAddEditDialog(), icon: const Icon(Icons.add), label: Text('add_schedule'.tr())),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(ScheduleEntry e, ThemeData theme) {
    late IconData icon;
    late Color bg;
    switch (e.action) {
      case 'water':
        icon = Icons.water_drop;
        bg = Colors.blue.shade100;
        break;
      case 'spray':
        icon = Icons.local_fire_department;
        bg = Colors.orange.shade100;
        break;
      case 'fertilize':
        icon = Icons.grass;
        bg = Colors.green.shade100;
        break;
      default:
        icon = Icons.task_alt;
        bg = Colors.grey.shade200;
    }

    return CircleAvatar(backgroundColor: bg, child: Icon(icon, color: Colors.black87));
  }
}

extension DateTimeCopy on DateTime {
  DateTime copyWith({int? year, int? month, int? day, int? hour, int? minute, int? second}) {
    return DateTime(year ?? this.year, month ?? this.month, day ?? this.day, hour ?? this.hour, minute ?? this.minute, second ?? this.second);
  }
}
