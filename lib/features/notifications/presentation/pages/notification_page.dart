import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        "icon": Icons.nightlight_round,
        "iconBg": const Color(0xFFE7E9FF),
        "iconColor": const Color(0xFF5A4CFF),
        "title": "Sleep Reminder",
        "message":
            "Your bedtime is in 30 minutes. Start winding down for better sleep quality.",
        "time": "2 hours ago",
        "showAction": true,
      },
      {
        "icon": Icons.warning_amber_rounded,
        "iconBg": const Color(0xFFFFE5E5),
        "iconColor": const Color(0xFFFF3B30),
        "title": "Burnout Risk Increasing",
        "message":
            "Your burnout score increased by 7 points this week. Consider taking rest breaks.",
        "time": "5 hours ago",
        "showAction": false,
      },
      {
        "icon": Icons.water_drop_outlined,
        "iconBg": const Color(0xFFDDF7FA),
        "iconColor": const Color(0xFF00A7C4),
        "title": "Hydration Checkpoint",
        "message":
            "You've had 0.8L today. Remember to drink water regularly.",
        "time": "6 hours ago",
        "showAction": false,
      },
      {
        "icon": Icons.show_chart,
        "iconBg": const Color(0xFFDDF5E6),
        "iconColor": const Color(0xFF22A55D),
        "title": "Great Progress!",
        "message":
            "You’ve been staying consistent. Keep following your healthy routine.",
        "time": "1 day ago",
        "showAction": false,
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7FB),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Divider(height: 1, color: Color(0xFFE2E6EF)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  children: [
                    _buildSmartNudgeCard(),
                    const SizedBox(height: 22),
                    ...notifications.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: NotificationCard(
                          icon: item["icon"] as IconData,
                          iconBackgroundColor: item["iconBg"] as Color,
                          iconColor: item["iconColor"] as Color,
                          title: item["title"] as String,
                          message: item["message"] as String,
                          time: item["time"] as String,
                          isUnread: true,
                          showAction: item["showAction"] as bool,
                          onActionTap: () {},
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF5B6475),
              size: 22,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0E1A2B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "3 unread",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7B8595),
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
              onTap: () {},
              child: const Text(
                "Mark all read",
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

  Widget _buildSmartNudgeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFA64DFF),
            Color(0xFF2563FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D5FEF).withOpacity(0.25),
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
                "Smart Nudge Engine",
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
            "Notifications are personalized based on your behavior\npatterns and compliance history.",
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
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final String title;
  final String message;
  final String time;
  final bool isUnread;
  final bool showAction;
  final VoidCallback? onActionTap;

  const NotificationCard({
    Key? key,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
    this.isUnread = false,
    this.showAction = false,
    this.onActionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD6E7FF),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8AAAE5).withOpacity(0.12),
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
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF475467),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF98A2B3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (showAction)
                      GestureDetector(
                        onTap: onActionTap,
                        child: const Text(
                          "Take Action",
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
          if (isUnread)
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
    );
  }
}