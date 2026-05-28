import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/notifications/notification_feed_service.dart';
import '../../../../shared/theme/app_page_style.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const List<_NotificationFilter> _filters = [
    _NotificationFilter('all', 'All'),
    _NotificationFilter('daily', 'Daily'),
    _NotificationFilter('weekly', 'Weekly'),
    _NotificationFilter('nudges', 'Nudges'),
  ];

  NotificationFeedResult? _feed;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    unawaited(_loadCachedThenRefresh());
  }

  @override
  Widget build(BuildContext context) {
    final feed = _feed;
    final notifications = _filteredItems(feed?.items ?? const []);
    final unreadCount = feed?.unreadCount ?? 0;

    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, unreadCount, feed?.items ?? const []),
              Divider(height: 1, color: pageBorderColor(context)),
              if (_isRefreshing && feed != null)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: _isLoading && feed == null
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () => _refreshFeed(force: true),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            20,
                            18,
                            20,
                            pageBottomContentPadding(context),
                          ),
                          children: [
                            _buildSummaryCard(context, feed),
                            const SizedBox(height: 16),
                            _buildFilters(context, feed?.items ?? const []),
                            const SizedBox(height: 18),
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
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadCachedThenRefresh() async {
    final service = NotificationFeedService.instance;
    final cached = await service.loadCachedFeed();
    if (!mounted) {
      return;
    }

    if (cached != null) {
      setState(() {
        _feed = cached;
        _isLoading = false;
      });
    }

    final shouldRefresh =
        cached == null || await service.shouldRefreshCachedFeed();
    if (!shouldRefresh) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await _refreshFeed(force: cached == null);
  }

  Future<void> _refreshFeed({bool force = false}) async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
      _isLoading = force && _feed == null;
    });

    final refreshed = await NotificationFeedService.instance.refreshFeed();
    if (!mounted) {
      return;
    }

    setState(() {
      if (!_sameFeed(_feed, refreshed)) {
        _feed = refreshed;
      }
      _isRefreshing = false;
      _isLoading = false;
    });
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
                    'Insights',
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
            child: TextButton(
              onPressed: unreadCount == 0
                  ? null
                  : () async {
                      await NotificationFeedService.instance.markAllRead(
                        notifications.map((item) => item.id),
                      );
                      final updated = await NotificationFeedService.instance
                          .loadFeed();
                      if (!mounted) return;
                      setState(() => _feed = updated);
                    },
              child: const Text('Mark all read'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, NotificationFeedResult? feed) {
    final items = feed?.items ?? const <AppNotificationItem>[];
    final dailyCount = _countFor(items, 'daily');
    final weeklyCount = _countFor(items, 'weekly');
    final nudgeCount = _countFor(items, 'nudges');
    final refreshedAt = feed?.refreshedAt;
    final refreshedText = refreshedAt == null
        ? 'Waiting for first sync'
        : 'Updated ${DateFormat('MMM d, h:mm a').format(refreshedAt)}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF246BFF), Color(0xFF10A7A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF246BFF).withValues(alpha: 0.22),
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
              Icon(Icons.insights_rounded, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'Insight history',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(label: 'Daily', value: dailyCount),
              _SummaryPill(label: 'Weekly', value: weeklyCount),
              _SummaryPill(label: 'Nudges', value: nudgeCount),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            refreshedText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, List<AppNotificationItem> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final selected = _selectedFilter == filter.key;
          final count = filter.key == 'all'
              ? items.length
              : items.where((item) => item.filterKey == filter.key).length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text('${filter.label} $count'),
              onSelected: (_) => setState(() => _selectedFilter = filter.key),
              selectedColor: const Color(0xFF246BFF),
              labelStyle: TextStyle(
                color: selected ? Colors.white : pagePrimaryTextColor(context),
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: pageSurfaceColor(context),
              side: BorderSide(color: pageBorderColor(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _markRead(String id) async {
    await NotificationFeedService.instance.markRead(id);
    final updated = await NotificationFeedService.instance.loadFeed();
    if (!mounted) return;
    setState(() => _feed = updated);
  }

  List<AppNotificationItem> _filteredItems(List<AppNotificationItem> items) {
    if (_selectedFilter == 'all') {
      return items;
    }

    return items.where((item) => item.filterKey == _selectedFilter).toList();
  }

  int _countFor(List<AppNotificationItem> items, String filterKey) {
    return items.where((item) => item.filterKey == filterKey).length;
  }

  bool _sameFeed(NotificationFeedResult? left, NotificationFeedResult right) {
    final leftItems = left?.items ?? const <AppNotificationItem>[];
    if (leftItems.length != right.items.length) {
      return false;
    }

    for (var index = 0; index < leftItems.length; index += 1) {
      final leftItem = leftItems[index];
      final rightItem = right.items[index];
      if (leftItem.id != rightItem.id ||
          leftItem.updatedAt != rightItem.updatedAt ||
          leftItem.isUnread != rightItem.isUnread ||
          leftItem.message != rightItem.message) {
        return false;
      }
    }

    return true;
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
            Icons.insights_outlined,
            color: pageSecondaryTextColor(context),
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            'No insights yet',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Daily and weekly reports appear after wellness, activity, nutrition, or nudge data is available.',
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
    if (item.filterKey == 'daily' || item.filterKey == 'weekly') {
      return _buildReportCard(context);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pageSurfaceColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: item.isUnread
                ? item.iconColor.withValues(alpha: 0.42)
                : pageBorderColor(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.16
                    : 0.07,
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: pagePrimaryTextColor(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PriorityBadge(priority: item.priority),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: pageSecondaryTextColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.metricChips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.metricChips
                          .map((chip) => _MetricChip(label: chip))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${item.sourceLabel} - ${item.time}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF98A2B3),
                            fontWeight: FontWeight.w600,
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
                              fontSize: 13,
                              color: Color(0xFF246BFF),
                              fontWeight: FontWeight.w700,
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
                width: 9,
                height: 9,
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

  Widget _buildReportCard(BuildContext context) {
    final isWeekly = item.filterKey == 'weekly';
    final accent = item.iconColor;
    final title = item.title.trim().isEmpty
        ? (isWeekly ? 'Weekly wellness report' : 'Daily wellness report')
        : item.title.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pageSurfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isUnread
                ? accent.withValues(alpha: 0.44)
                : pageBorderColor(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.16
                    : 0.07,
              ),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _ReportTypePill(
                            label: isWeekly
                                ? 'Weekly wellness report'
                                : 'Daily wellness report',
                            color: accent,
                          ),
                          _PriorityBadge(priority: item.priority),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: pagePrimaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.isUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: reportSummaryColor(context, accent),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.14)),
              ),
              child: Text(
                item.message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: pageSecondaryTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (item.metricChips.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Key signals',
                style: TextStyle(
                  color: pagePrimaryTextColor(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _ReportMetricGrid(metrics: item.metricChips, accent: accent),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: pageSecondaryTextColor(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${item.sourceLabel} - ${item.time}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: pageSecondaryTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item.showAction) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onActionTap,
                    child: const Text(
                      'Mark read',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF246BFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color reportSummaryColor(BuildContext context, Color accent) {
    return Theme.of(context).brightness == Brightness.dark
        ? accent.withValues(alpha: 0.08)
        : accent.withValues(alpha: 0.06);
  }
}

class _NotificationFilter {
  final String key;
  final String label;

  const _NotificationFilter(this.key, this.label);
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final int value;

  const _SummaryPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;

  const _MetricChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: itemChipColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: pageSecondaryTextColor(context),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color itemChipColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF4FBF8);
  }
}

class _ReportTypePill extends StatelessWidget {
  final String label;
  final Color color;

  const _ReportTypePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReportMetricGrid extends StatelessWidget {
  final List<String> metrics;
  final Color accent;

  const _ReportMetricGrid({required this.metrics, required this.accent});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final useTwoColumns = constraints.maxWidth >= 300;
        final itemWidth = useTwoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
                  child: _ReportMetricTile(metric: metric, accent: accent),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ReportMetricTile extends StatelessWidget {
  final String metric;
  final Color accent;

  const _ReportMetricTile({required this.metric, required this.accent});

  @override
  Widget build(BuildContext context) {
    final parts = _splitReportMetric(metric);

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  parts.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  parts.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMetricParts {
  final String label;
  final String value;

  const _ReportMetricParts({required this.label, required this.value});
}

_ReportMetricParts _splitReportMetric(String metric) {
  final normalized = metric.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) {
    return const _ReportMetricParts(label: 'Signal', value: 'Available');
  }

  if (normalized.startsWith('Risk ')) {
    return _ReportMetricParts(
      label: 'Burnout risk',
      value: normalized.substring('Risk '.length),
    );
  }

  final lastSpace = normalized.lastIndexOf(' ');
  if (lastSpace <= 0 || lastSpace == normalized.length - 1) {
    return _ReportMetricParts(label: 'Signal', value: normalized);
  }

  return _ReportMetricParts(
    label: normalized.substring(0, lastSpace),
    value: normalized.substring(lastSpace + 1),
  );
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final normalized = priority.toLowerCase();
    final color = switch (normalized) {
      'high' => const Color(0xFFE5484D),
      'medium' => const Color(0xFFE0A100),
      _ => const Color(0xFF22A55D),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        normalized.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
