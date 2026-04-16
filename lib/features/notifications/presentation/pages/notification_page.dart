import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late final List<_NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      _NotificationItem(
        icon: Icons.nightlight_round,
        iconBg: const Color(0xFFE7E9FF),
        iconColor: const Color(0xFF5A4CFF),
        title: 'Sleep Reminder',
        message:
            'Your bedtime is in 30 minutes. Start winding down for better sleep quality.',
        time: '2 hours ago',
        showAction: true,
        isUnread: true,
      ),
      _NotificationItem(
        icon: Icons.warning_amber_rounded,
        iconBg: const Color(0xFFFFE5E5),
        iconColor: const Color(0xFFFF3B30),
        title: 'Burnout Risk Increasing',
        message:
            'Your burnout score increased by 7 points this week. Consider taking rest breaks.',
        time: '5 hours ago',
        isUnread: true,
      ),
      _NotificationItem(
        icon: Icons.water_drop_outlined,
        iconBg: const Color(0xFFDDF7FA),
        iconColor: const Color(0xFF00A7C4),
        title: 'Hydration Checkpoint',
        message: 'You have had 0.8L today. Remember to drink water regularly.',
        time: '6 hours ago',
        isUnread: true,
      ),
      _NotificationItem(
        icon: Icons.show_chart,
        iconBg: const Color(0xFFDDF5E6),
        iconColor: const Color(0xFF22A55D),
        title: 'Great Progress',
        message:
            'You have been staying consistent. Keep following your healthy routine.',
        time: '1 day ago',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((item) => item.isUnread).length;

    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, unreadCount),
              Divider(height: 1, color: pageBorderColor(context)),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    pageBottomContentPadding(context),
                  ),
                  children: [
                    _buildSmartNudgeCard(context),
                    const SizedBox(height: 22),
                    ..._notifications.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: NotificationCard(
                          item: item,
                          onTap: () {
                            setState(() {
                              item.isUnread = false;
                            });
                          },
                          onActionTap: () {
                            setState(() {
                              item.isUnread = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unreadCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: pagePrimaryTextColor(context),
              size: 22,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$unreadCount unread',
                    style: TextStyle(
                      fontSize: 14,
                      color: pageSecondaryTextColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  for (final item in _notifications) {
                    item.isUnread = false;
                  }
                });
              },
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF246BFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartNudgeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563FF),
            Color(0xFF0891B2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563FF).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Smart Reminders',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            'These reminders currently use local app preferences and preview content while deeper personalization is still being connected.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final _NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback? onActionTap;

  const NotificationCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: pageSurfaceColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pageBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.08,
              ),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: pageSecondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        item.time,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF98A2B3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (item.showAction)
                        GestureDetector(
                          onTap: onActionTap,
                          child: const Text(
                            'Take Action',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF246BFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (item.isUnread)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF246BFF),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String message;
  final String time;
  final bool showAction;
  bool isUnread;

  _NotificationItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
    this.showAction = false,
    this.isUnread = false,
  });
}
