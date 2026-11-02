import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/category_icon.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/spending_chart.dart';

/// Analytics ranges offered on Screen 4.
enum StatsRange {
  thisMonth,
  last3Months,
  thisYear,
  allTime;

  String get label {
    switch (this) {
      case StatsRange.thisMonth:
        return 'This Month';
      case StatsRange.last3Months:
        return 'Last 3 Months';
      case StatsRange.thisYear:
        return 'This Year';
      case StatsRange.allTime:
        return 'All Time';
    }
  }
}

/// Screen 4 — Statistics / Analytics dashboard computed from saved data.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'Statistics',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: const _StatisticsBody(),
    );
  }
}

class _StatisticsBody extends StatefulWidget {
  const _StatisticsBody();

  @override
  State<_StatisticsBody> createState() => _StatisticsBodyState();
}

class _StatisticsBodyState extends State<_StatisticsBody> {
  StatsRange _range = StatsRange.thisMonth;

  DateTime get _rangeStart {
    final DateTime now = DateTime.now();
    switch (_range) {
      case StatsRange.thisMonth:
        return DateTime(now.year, now.month);
      case StatsRange.last3Months:
        return DateTime(now.year, now.month - 2);
      case StatsRange.thisYear:
        return DateTime(now.year, 1);
      case StatsRange.allTime:
        return AppConstants.firstSelectableDate;
    }
  }

  bool _inRange(Expense e) =>
      !e.date.isBefore(_rangeStart) && e.date.isBefore(DateTime.now().add(const Duration(days: 1)));

  @override
  Widget build(BuildContext context) {
    final ExpenseProvider provider = context.watch<ExpenseProvider>();
    final bool bootLoading = provider.loading && !provider.initialised;
    final bool bootError = provider.error != null && !provider.initialised;

    if (bootLoading) {
      return const LoadingWidget(label: 'Crunching your numbers…');
    }
    if (bootError) {
      return AppErrorWidget(
        message: provider.error!,
        onRetry: context.read<ExpenseProvider>().retry,
      );
    }
    if (provider.expenses.isEmpty) {
      return const EmptyState(
        icon: Icons.query_stats_rounded,
        title: 'No statistics yet',
        message: 'Add a few transactions and your spending story appears here.',
      );
    }

    final List<Expense> ranged = provider.expenses.where(_inRange).toList();
    final double income = _sum(ranged, (Expense e) => e.isIncome);
    final double expense = _sum(ranged, (Expense e) => e.isExpense);
    final double net = income - expense;

    // Category breakdown within range.
    final Map<String, double> byCategory = <String, double>{};
    for (final Expense e in ranged.where((Expense e) => e.isExpense)) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    final List<MapEntry<String, double>> sortedCategories =
        byCategory.entries.toList()
          ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
              b.value.compareTo(a.value));
    final double categoryTotal = expense;

    // Monthly overview: last 6 months of expenses.
    final Map<String, double> months6 = provider.monthlyTotals(6);

    // Daily spending for this month.
    final Map<int, double> dailies =
        provider.dailyTotalsForMonth(DateTime.now());

    // Average daily spending across the selected range (days elapsed).
    final int elapsedDays = DateTime.now().difference(_rangeStart).inDays + 1;
    final double avgDaily = elapsedDays > 0 ? expense / elapsedDays : 0;

    final MapEntry<String, double>? highest =
        sortedCategories.isEmpty ? null : sortedCategories.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ---- Range selector ----
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                for (final StatsRange r in StatsRange.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(r.label),
                      selected: _range == r,
                      onSelected: (bool _) => setState(() => _range = r),
                      labelStyle: const TextStyle(fontSize: 12.5),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // ---- Totals row ----
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  label: 'Total Income',
                  value: CurrencyFormatter.formatShort(income),
                  icon: Icons.south_west_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Total Expense',
                  value: CurrencyFormatter.formatShort(expense),
                  icon: Icons.north_east_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StatCard(
            label: 'Net Balance',
            value: CurrencyFormatter.formatShort(net),
            icon: Icons.account_balance_rounded,
            color: net >= 0
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.error,
            wide: true,
          ),
          const SizedBox(height: 12),
          // ---- Highlights ----
          Row(
            children: <Widget>[
              Expanded(
                child: _HighlightCard(
                  label: 'Top Category',
                  value: highest?.key ?? 'None',
                  icon: Icons.workspace_premium_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HighlightCard(
                  label: 'Avg / Day',
                  value: CurrencyFormatter.formatShort(avgDaily),
                  icon: Icons.av_timer_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // ---- Monthly overview ----
          _ChartPanel(
            title: 'Monthly Expense Overview',
            subtitle: 'Last 6 months',
            child: SpendingChart(
              height: 160,
              labels: months6.keys
                  .map((String key) => _monthShort(key))
                  .toList(),
              values: months6.values.toList(),
              showValueLabels: true,
            ),
          ),
          const SizedBox(height: 14),
          // ---- Daily spending (this month) ----
          _ChartPanel(
            title: 'Daily Spending',
            subtitle: DateFormatter.formatMonth(DateTime.now()),
            child: SpendingChart(
              height: 150,
              labels: dailies.keys
                  .map((int day) =>
                      day == 1 ||
                              day == 5 ||
                              day % 5 == 0 ||
                              day == dailies.length
                          ? '$day'
                          : '')
                  .toList(),
              values: dailies.values.toList(),
            ),
          ),
          const SizedBox(height: 18),
          // ---- Category breakdown ----
          _ChartPanel(
            title: 'Category Breakdown',
            subtitle:
                '${sortedCategories.length} ${sortedCategories.length == 1 ? 'category' : 'categories'} in range',
            child: sortedCategories.isEmpty
                ? Text(
                    'No expenses in this period — add some to see your breakdown.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                : Column(
                    children: <Widget>[
                      for (int i = 0; i < sortedCategories.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i == sortedCategories.length - 1 ? 0 : 12,
                          ),
                          child: _CategoryBreakdownRow(
                            category: sortedCategories[i].key,
                            amount: sortedCategories[i].value,
                            max: sortedCategories.first.value,
                            total: categoryTotal,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static double _sum(
    Iterable<Expense> items,
    bool Function(Expense) predicate,
  ) {
    double sum = 0;
    for (final Expense e in items) {
      if (predicate(e)) sum += e.amount;
    }
    return sum;
  }

  /// '2026-11' → 'Nov'
  static String _monthShort(String key) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final List<String> parts = key.split('-');
    final int month = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    return months[(month - 1).clamp(0, 11)];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CategoryBreakdownRow extends StatelessWidget {
  const _CategoryBreakdownRow({
    required this.category,
    required this.amount,
    required this.max,
    required this.total,
  });

  final String category;
  final double amount;
  final double max;
  final double total;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double fraction = max <= 0 ? 0 : (amount / max).clamp(0.0, 1.0);
    final int percent =
        total <= 0 ? 0 : ((amount / total) * 100).round();

    return Row(
      children: <Widget>[
        CategoryIcon(category: category, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      category,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatShort(amount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 6,
                        backgroundColor:
                            scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$percent%',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
