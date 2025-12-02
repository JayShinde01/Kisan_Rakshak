// lib/screens/notification.dart
import 'package:demo/main.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Sample notifications (replace with real source if needed)
  List<Map<String, dynamic>> notifications = [
    {"id": "n1", "title": "Payment received successfully!", "type": "success", "time": "2 min ago", "isRead": false},
    {"id": "n2", "title": "New system update available", "type": "update", "time": "10 min ago", "isRead": false},
    {"id": "n3", "title": "Your order is being processed", "type": "order", "time": "20 min ago", "isRead": false},
    {"id": "n4", "title": "🔥 50% off discount is live!", "type": "offer", "time": "1 hr ago", "isRead": true},
    {"id": "n5", "title": "New message from support team", "type": "message", "time": "2 hrs ago", "isRead": false},
    {"id": "n6", "title": "Field inspection report ready", "type": "report", "time": "1 day ago", "isRead": true},
    {"id": "n7", "title": "Low stock warning: Fertilizer X", "type": "warning", "time": "2 days ago", "isRead": true},
  ];

  // UI state
  bool showOnlyUnread = false;

  IconData _iconFor(String type) {
    switch (type) {
      case "success":
        return Icons.check_circle_rounded;
      case "update":
        return Icons.system_update_alt_rounded;
      case "order":
        return Icons.local_shipping_rounded;
      case "offer":
        return Icons.local_offer_rounded;
      case "message":
        return Icons.chat_bubble_rounded;
      case "report":
        return Icons.assignment_rounded;
      case "warning":
        return Icons.warning_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type, ThemeData theme) {
    // Use theme-aware colors where possible; fall back to tints
    switch (type) {
      case "success":
        return Colors.green.shade600;
      case "update":
        return Colors.blue.shade600;
      case "order":
        return Colors.orange.shade600;
      case "offer":
        return Colors.purple.shade600;
      case "message":
        return Colors.teal.shade600;
      case "report":
        return Colors.amber.shade700;
      case "warning":
        return Colors.red.shade600;
      default:
        return theme.iconTheme.color ?? Colors.grey.shade600;
    }
  }

  void _markAllRead() {
    final hasUnread = notifications.any((n) => n['isRead'] == false);
    if (!hasUnread) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All notifications already read')));
      return;
    }
    setState(() {
      for (var n in notifications) {
        n['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All notifications marked as read')));
  }

  void _removeAtIndex(int index, Map<String, dynamic> removed) {
    setState(() {
      notifications.removeAt(index);
    });
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification dismissed'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: theme.colorScheme.primary,
          onPressed: () {
            setState(() {
              // simple: add back at top
              notifications.insert(0, removed);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = theme.cardColor;
    final iconColor = theme.iconTheme.color ?? Colors.grey.shade700;
    final filtered = showOnlyUnread ? notifications.where((n) => n['isRead'] == false).toList() : notifications;
    final unreadCount = notifications.where((n) => n['isRead'] == false).length;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: AgrioDemoApp.primaryGreen,
        elevation: theme.appBarTheme.elevation ?? 2,
        title: Text('Notifications', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _markAllRead,
            tooltip: 'Mark all as read',
            icon: Icon(Icons.mark_email_read_rounded, color: iconColor),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'filter') setState(() => showOnlyUnread = !showOnlyUnread);
              if (v == 'clear') {
                setState(() => notifications.clear());
              }
            },
            icon: Icon(Icons.more_vert, color: iconColor),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Checkbox(value: showOnlyUnread, onChanged: (_) {}, activeColor: colorScheme.primary),
                    const SizedBox(width: 6),
                    const Expanded(child: Text('Show only unread')),
                  ],
                ),
              ),
              const PopupMenuItem(value: 'clear', child: Text('Clear all notifications')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              unreadCount > 0 ? '$unreadCount unread' : 'You are all caught up',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.9)),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? _buildEmptyState(context, theme, colorScheme)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final n = filtered[i];
                final title = n['title'] as String;
                final time = n['time'] as String;
                final type = n['type'] as String;
                final isRead = n['isRead'] as bool;
                final color = _colorFor(type, theme);
                final icon = _iconFor(type);

                // Need original index in master list to remove correctly
                final originalIndex = notifications.indexWhere((el) => el['id'] == n['id']);

                return Dismissible(
                  key: ValueKey(n['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeAtIndex(originalIndex, n),
                  child: Material(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        // mark read and optionally navigate
                        if (!isRead) {
                          setState(() {
                            n['isRead'] = true;
                          });
                        }
                        // TODO: navigate to relevant screen based on n['type']
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Icon circle
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                              child: Icon(icon, color: color, size: 26),
                            ),
                            const SizedBox(width: 14),

                            // Text content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 15,
                                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                      color: isRead ? theme.disabledColor : theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(time, style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor)),
                                ],
                              ),
                            ),

                            // Right-side indicator
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: isRead
                                  ? Icon(Icons.done, size: 18, color: theme.disabledColor)
                                  : Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      // quick action FAB to mark all read
      floatingActionButton: notifications.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _markAllRead,
              label: Text('Mark all read', style: TextStyle(color: Colors.black),),
              icon: Icon(Icons.mark_email_read_rounded, color: colorScheme.onSecondary),
              backgroundColor: colorScheme.secondary,
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off, size: 68, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('No notifications', style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'You are all caught up. We will show important alerts here — reminders, offers, reports and messages.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                // placeholder: go to tutorials or help
                Navigator.pop(context);
              },
              icon: Icon(Icons.home_outlined, color: colorScheme.onPrimary),
              label: Text('Go to Home', style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary)),
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
