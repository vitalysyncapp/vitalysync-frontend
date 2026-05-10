import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../nutrition/data/nutrition_coach.dart';
import '../../../../shared/notifications/notification_feed_service.dart';
import '../../../../shared/theme/app_page_style.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Future<NotificationFeedResult> _feedFuture;

  @override
  void initState() {
    super.initState();
    _feedFuture = NotificationFeedService.instance.loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: FutureBuilder<NotificationFeedResult>(
            future: _feedFuture,
            builder: (context, snapshot) {
              final feed = snapshot.data;
              final notifications =
                  feed?.items ?? const <AppNotificationItem>[];
              final unreadCount = feed?.unreadCount ?? 0;

              return Column(
                children: [
                  _buildHeader(context, unreadCount, notifications),
                  Divider(height: 1, color: pageBorderColor(context)),
                  Expanded(child: _buildBody(context, snapshot)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int unreadCount,
    List<AppNotificationItem> notifications,
  ) {
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
              onTap: unreadCount == 0
                  ? null
                  : () async {
                      await NotificationFeedService.instance.markAllRead(
                        notifications.map((item) => item.id),
                      );
                      if (!mounted) return;
                      setState(() {
                        _feedFuture = NotificationFeedService.instance
                            .loadFeed();
                      });
                    },
              child: Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: unreadCount == 0
                      ? pageSecondaryTextColor(context).withValues(alpha: 0.55)
                      : const Color(0xFF246BFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<NotificationFeedResult> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to load notifications right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final feed = snapshot.data;
    final notifications = feed?.items ?? const <AppNotificationItem>[];
    final sources = feed?.functionalSources ?? const <String>[];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        pageBottomContentPadding(context),
      ),
      children: [
        _buildStatusCard(context, sources),
        const SizedBox(height: 22),
        _buildNutritionInsightSection(context, feed?.nutritionInsight),
        const SizedBox(height: 22),
        if (notifications.isEmpty)
          _buildEmptyState(context)
        else
          ...notifications.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: NotificationCard(
                item: item,
                onTap: () => _markRead(item.id),
                onActionTap: () => _markRead(item.id),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _markRead(String id) async {
    await NotificationFeedService.instance.markRead(id);
    if (!mounted) return;
    setState(() {
      _feedFuture = NotificationFeedService.instance.loadFeed();
    });
  }

  Widget _buildStatusCard(BuildContext context, List<String> sources) {
    final sourceText = sources.isEmpty
        ? 'No live notification sources are ready yet; reminders and reports appear here when their data exists.'
        : 'Showing functional sources now: ${sources.join(', ')}.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563FF), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563FF).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Smart Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            sourceText,
            style: const TextStyle(
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

  Widget _buildNutritionInsightSection(
    BuildContext context,
    NutritionInsight? insight,
  ) {
    final hasInsight = insight != null && insight.message.trim().isNotEmpty;
    final title = hasInsight ? insight.title : 'Nutrition Insights';
    final message = hasInsight
        ? insight.message
        : 'No nutrition insight yet. Add a meal log to generate one gentle suggestion.';
    final timeLabel = hasInsight
        ? 'Latest insight - ${DateFormat('MMM d, h:mm a').format(insight.generatedAt)}'
        : 'Last generated suggestion only';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition Insights',
          style: TextStyle(
            color: pagePrimaryTextColor(context),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pageSurfaceColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: pageBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.16
                      : 0.06,
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F7F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Color(0xFF1F9D63),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: TextStyle(
                        color: pageSecondaryTextColor(context),
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: pageSecondaryTextColor(context),
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            'No functional notifications yet',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enable reminders or add logs to generate sleep, hydration, activity, goal, burnout, and progress updates.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final AppNotificationItem item;
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
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.16
                    : 0.08,
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
                      Flexible(
                        child: Text(
                          item.time,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF98A2B3),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (item.showAction)
                        GestureDetector(
                          onTap: onActionTap,
                          child: const Text(
                            'Mark read',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF246BFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.sourceLabel,
                    style: TextStyle(
                      color: item.iconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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
