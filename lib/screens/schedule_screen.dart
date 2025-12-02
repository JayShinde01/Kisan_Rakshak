// lib/screens/schedule_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _loadEntries();
    // Also listen for auth changes so we can switch between local & remote
    _auth.userChanges().listen((user) {
      // when signed in/out, reload and re-attach firestore listener
      _attachFirestoreListenerIfNeeded();
      _loadEntries(); // reload (will pick Firestore if logged in)
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
      // Build list from snapshot and update UI & local cache
      final list = snap.docs.map((d) => ScheduleEntry.fromFirestore(d.data(), d.id)).toList();
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      setState(() {
        _entries = list;
        _loading = false;
      });
      // also persist locally for offline use
      _saveToLocal();
    }, onError: (err) {
      // ignore, but keep local data
    });
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    final uid = _auth.currentUser?.uid;

    if (uid != null) {
      // user logged in — try Firestore first (one-shot load if listener not active yet)
      try {
        final snap = await _db.collection('users').doc(uid).collection('schedules').get();
        final list = snap.docs.map((d) => ScheduleEntry.fromFirestore(d.data(), d.id)).toList();
        list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        setState(() {
          _entries = list;
          _loading = false;
        });
        // persist local copy for offline fallback
        await _saveToLocal();
        // make sure listener is attached
        await _attachFirestoreListenerIfNeeded();
        return;
      } catch (e) {
        // Firestore failed — fall back to local cache
      }
    }

    // Fallback: local SharedPreferences
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
    // save locally and to Firestore (if user present)
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
    if (uid == null) return; // not signed in — nothing to push
    final coll = _db.collection('users').doc(uid).collection('schedules');

    // sync strategy:
    // - write/update each local entry as a doc with id = entry.id
    // - detect removed docs by comparing list of remote ids (simple approach)
    try {
      final remoteSnap = await coll.get();
      final remoteIds = remoteSnap.docs.map((d) => d.id).toSet();
      final localIds = _entries.map((e) => e.id).toSet();

      // Upsert local entries
      for (final e in _entries) {
        await coll.doc(e.id).set(e.toFirestoreMap(), SetOptions(merge: true));
      }

      // Delete remote entries that are no longer local
      final toDelete = remoteIds.difference(localIds);
      for (final id in toDelete) {
        await coll.doc(id).delete();
      }
    } catch (e) {
      // ignore firestore write errors for now — UI stays functional with local cache
    }
  }

  Future<void> _showAddEditDialog({ScheduleEntry? entry}) async {
    final isEdit = entry != null;
    final titleCtrl = TextEditingController(text: entry?.title ?? '');
    final notesCtrl = TextEditingController(text: entry?.notes ?? '');
    String action = entry?.action ?? 'water';
    String repeat = entry?.repeat ?? 'none';
    DateTime selectedDateTime = entry?.dateTime ?? DateTime.now().add(const Duration(hours: 1));

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setStateDialog) {
          // move pickDateTime inside builder so we can call setStateDialog
          Future<void> pickDateTime() async {
            final DateTime? pickedDate = await showDatePicker(
              context: ctx2,
              initialDate: selectedDateTime,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
            );
            if (pickedDate == null) return;
            final TimeOfDay? pickedTime = await showTimePicker(
              context: ctx2,
              initialTime: TimeOfDay.fromDateTime(selectedDateTime),
            );
            if (pickedTime == null) return;
            selectedDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            setStateDialog(() {}); // refresh dialog UI only
          }

          return AlertDialog(
            title: Text(isEdit ? 'Edit Schedule' : 'New Schedule'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Water North Field'),
                  ),
                  const SizedBox(height: 12),

                  // Action dropdown
                  Row(
                    children: [
                      const Text('Action:'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: action,
                        items: const [
                          DropdownMenuItem(value: 'water', child: Text('Water')),
                          DropdownMenuItem(value: 'spray', child: Text('Spray')),
                          DropdownMenuItem(value: 'fertilize', child: Text('Fertilize')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (v) => setStateDialog(() => action = v ?? 'water'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Date & Time
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_friendlyDateTime(selectedDateTime)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await pickDateTime();
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Repeat
                  Row(
                    children: [
                      const Text('Repeat:'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: repeat,
                        items: const [
                          DropdownMenuItem(value: 'none', child: Text('None')),
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        ],
                        onChanged: (v) => setStateDialog(() => repeat = v ?? 'none'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final t = titleCtrl.text.trim();
                  if (t.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please give a title')));
                    return;
                  }

                  if (isEdit) {
                    // modify entry (edit in-place)
                    entry!.title = t;
                    entry.action = action;
                    entry.repeat = repeat;
                    entry.dateTime = selectedDateTime;
                    entry.notes = notesCtrl.text.trim();
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
                  }

                  // sort by next occurrence
                  _entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                  await _saveEntries();
                  setState(() {}); // update list on screen
                  Navigator.pop(ctx2);
                },
                child: Text(isEdit ? 'Save' : 'Add'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<bool> _confirmDelete(ScheduleEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete schedule'),
        content: Text('Remove "${entry.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  // Remove one entry (used by overflow menu and Dismissible)
  Future<void> _removeEntry(ScheduleEntry entry, {bool showSnack = true}) async {
    setState(() {
      _entries.removeWhere((it) => it.id == entry.id);
    });

    // Remove from firestore if user signed in
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _db.collection('users').doc(uid).collection('schedules').doc(entry.id).delete();
      } catch (_) {
        // ignore errors (we still remove locally)
      }
    }

    await _saveToLocal();
    if (showSnack) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule deleted')));
    }
  }

  // helper: pretty format
  static String _friendlyDateTime(DateTime dt) {
    final datePart = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$datePart • $hour:$minute $ampm';
  }

  // When user marks done, optionally schedule next occurrence if repeat set
  Future<void> _toggleDone(ScheduleEntry e) async {
    // toggle done and handle repeat
    if (!e.done && e.repeat != 'none') {
      // marked done — compute next occurrence and update
      DateTime next = e.dateTime;
      if (e.repeat == 'daily') {
        next = e.dateTime.add(const Duration(days: 1));
      } else if (e.repeat == 'weekly') {
        next = e.dateTime.add(const Duration(days: 7));
      }
      e.dateTime = next;
      e.done = false;
    } else {
      // simple toggle (non-repeating or unmark)
      e.done = !e.done;
    }

    // save to firestore / local
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No completed schedules')));
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear completed'),
        content: Text('Remove ${completed.length} completed schedule(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      // delete from firestore where possible
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        for (final e in completed) {
          try {
            await _db.collection('users').doc(uid).collection('schedules').doc(e.id).delete();
          } catch (_) {}
        }
      }

      setState(() => _entries.removeWhere((e) => e.done));
      await _saveToLocal();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completed schedules cleared')));
    }
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all schedules'),
        content: const Text('Remove all schedules? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      // delete all from firestore if signed in
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

      setState(() => _entries.clear());
      await _saveToLocal();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All schedules cleared')));
    }
  }

  Future<void> _exportToClipboard() async {
    final raw = json.encode(_entries.map((e) => e.toMap()).toList());
    await Clipboard.setData(ClipboardData(text: raw));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedules JSON copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: Colors.green.shade700,
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
              const PopupMenuItem(value: 'clear_completed', child: Text('Clear completed')),
              const PopupMenuItem(value: 'clear_all', child: Text('Clear all')),
              const PopupMenuItem(value: 'export', child: Text('Export (JSON)')),
            ],
            icon: const Icon(Icons.more_vert),
          ),
          IconButton(
            icon: const Icon(Icons.add_alert_outlined),
            tooltip: 'Add quick watering schedule (tomorrow 7AM)',
            onPressed: () async {
              final quick = ScheduleEntry(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: 'Water: Quick',
                action: 'water',
                dateTime: DateTime.now().add(const Duration(days: 1)).copyWith(hour: 7, minute: 0),
                repeat: 'none',
                notes: 'Quick auto-added schedule',
              );
              setState(() {
                _entries.add(quick);
                _entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
              });
              await _saveEntries();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: () => _loadEntries(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        label: const Text('Add'),
        icon: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _emptyState()
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            leading: _buildLeadingIcon(e),
                            title: Text(e.title, style: TextStyle(decoration: e.done ? TextDecoration.lineThrough : null)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(_friendlyDateTime(e.dateTime)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (e.repeat != 'none')
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: Text(e.repeat.toUpperCase(), style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
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
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showAddEditDialog(entry: e),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _toggleDone(e),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: e.done ? Colors.green.shade700 : Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(e.done ? Icons.check : Icons.check_box_outline_blank, color: e.done ? Colors.white : Colors.black54, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Overflow menu for item-level actions (delete, duplicate)
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
                                      await _saveEntries();
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule duplicated')));
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note_outlined, size: 72, color: Colors.green.shade300),
          const SizedBox(height: 12),
          const Text('No schedules yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Add watering, spraying or fertilizing schedules that notify you when it\'s time.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: () => _showAddEditDialog(), icon: const Icon(Icons.add), label: const Text('Add schedule')),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(ScheduleEntry e) {
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

    return CircleAvatar(
      backgroundColor: bg,
      child: Icon(icon, color: Colors.black87),
    );
  }
}

extension DateTimeCopy on DateTime {
  DateTime copyWith({int? year, int? month, int? day, int? hour, int? minute, int? second}) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
    );
  }
}
