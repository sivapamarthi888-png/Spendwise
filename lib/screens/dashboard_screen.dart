import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_widget.dart';
import '../widgets/expense_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/summary_card.dart';
import 'expense_detail_screen.dart';
import '../widgets/month_filter_sheet.dart';
import '../widgets/spending_chart.dart';

/// Screen 1 — Dashboard: financial summary, spending overview chart and the
/// searchable / filterable transaction list with all four list states
/// (loading, error, empty, data).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DashboardLifecycle(
      child: const _DashboardBody(),
    );
  }
}

/// Kicks off the (idempotent) initial database load exactly once.
class _DashboardLifecycle extends StatefulWidget {
  const _DashboardLifecycle({required this.child});

  final Widget child;

  @override
  State<_DashboardLifecycle> createState() => _DashboardLifecycleState();
}

class _DashboardLifecycleState extends State<_DashboardLifecycle> {
  @override
  void initState() {
    super.initState();
    // Schedule after first frame so Provider is fully available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExpenseProvider>().ensureLoaded();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              DateFormatter.greeting(DateTime.now()),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEEE, ').format(DateTime.now()) +
                  DateFormatter.format(DateTime.now()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        shape: const Border(),
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () => context.read<ExpenseProvider>().loadExpenses(),
        child: const _DashboardScroll(),
      ),
    );
  }
}

class _DashboardScroll extends StatelessWidget {
  const _DashboardScroll();

  void _openDetail(BuildContext context, Expense expense) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseDetailScreen(expense: expense),
      ),
    );
  }

  void _openAddExpense(BuildContext context) {
    Navigator.of(context).pushNamed('/add-expense');
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseProvider provider = context.watch<ExpenseProvider>();
    final bool bootLoading = provider.loading && !provider.initialised;
    final bool bootError = provider.error != null && !provider.initialised;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _MonthlyHeroCard(provider: provider),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SummaryCard(
                    title: 'Income',
                    amount: provider.totalIncome,
                    icon: Icons.south_west_rounded,
                    accent: Theme.of(context).colorScheme.secondary,
                    subtitle: 'All time',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SummaryCard(
                    title: 'Expenses',
                    amount: provider.totalExpense,
                    icon: Icons.north_east_rounded,
                    accent: Theme.of(context).colorScheme.primary,
                    subtitle: 'All time',
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _SpendingOverview(provider: provider),
          ),
        ),
        // ---- Transactions section ------------------------------------
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${provider.filteredCount} ${provider.filteredCount == 1 ? 'record' : 'records'}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          sliver: SliverToBoxAdapter(child: _SearchField(provider: provider)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _FilterControls(provider: provider),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _CategoryFilterChips(provider: provider),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 4)),
        if (bootLoading)
          const SliverToBoxAdapter(child: LoadingWidget())
        else if (bootError)
          SliverToBoxAdapter(
            child: AppErrorWidget(
              message: provider.error!,
              onRetry: context.read<ExpenseProvider>().retry,
            ),
          )
        else if (provider.expenses.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No expenses yet',
              message: 'Start tracking your spending by adding your first expense.',
              ctaLabel: 'Add your first expense',
              onCta: () => _openAddExpense(context),
            ),
          )
        else if (provider.filteredExpenses.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matching transactions',
              message: 'Nothing matches your current search or filters.',
              ctaLabel: null,
              onCta: null,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            sliver: SliverList.separated(
              itemCount: provider.filteredExpenses.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 2),
              itemBuilder: (BuildContext context, int index) {
                final Expense expense = provider.filteredExpenses[index];
                return ExpenseCard(
                  expense: expense,
                  onTap: () => _openDetail(context, expense),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// Summary hero card: monthly spending + today's spending.
class _MonthlyHeroCard extends StatelessWidget {
  const _MonthlyHeroCard({required this.provider});

  final ExpenseProvider provider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.account_balance_wallet_rounded,
                color: scheme.onPrimary.withValues(alpha: 0.85),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'This Month\'s Spending',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM').format(DateTime.now()).toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(provider.monthlyExpense),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: scheme.onPrimary,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _HeroChip(
                icon: Icons.today_rounded,
                label: 'Today',
                value: CurrencyFormatter.formatShort(provider.todaysExpense),
              ),
              const SizedBox(width: 10),
              _HeroChip(
                icon: Icons.flag_rounded,
                label: 'Net Balance',
                value: CurrencyFormatter.formatShort(provider.netBalance),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.onPrimary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 15, color: scheme.onPrimary.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.75),
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Last-seven-days bar overview.
class _SpendingOverview extends StatelessWidget {
  const _SpendingOverview({required this.provider});

  final ExpenseProvider provider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Map<DateTime, double> last7 = provider.last7DaysTotals();
    double total = 0;
    for (final double v in last7.values) {
      total += v;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Spending Overview',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                'Last 7 days · ${CurrencyFormatter.formatShort(total)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SpendingChart(
            height: 130,
            labels: last7.keys
                .map((DateTime d) => DateFormatter.dayLabel(d))
                .toList(),
            values: last7.values.toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.provider});

  final ExpenseProvider provider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextEditingController controller = TextEditingController(
      text: provider.searchQuery,
    );

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: provider.setSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search expenses…',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: provider.searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  controller.clear();
                  provider.setSearchQuery('');
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
      ),
      // Keep the caret placeable each rebuild without re-creating sessions.
      style: theme.textTheme.bodyMedium,
    );
  }
}

class _FilterControls extends StatelessWidget {
  const _FilterControls({required this.provider});

  final ExpenseProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // Month filter
        Expanded(
          child: FilterPill(
            icon: Icons.filter_alt_rounded,
            label: provider.monthFilter == null
                ? 'All Time'
                : monthLabelForKey(provider.monthFilter!),
            active: provider.monthFilter != null,
            onTap: () => MonthFilterSheet.show(
              context,
              months: provider.availableMonths,
              selected: provider.monthFilter,
              onSelected: provider.setMonthFilter,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Sort toggle
        FilterPill(
          icon: provider.newestFirst
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          label: provider.newestFirst ? 'Newest' : 'Oldest',
          active: true,
          onTap: provider.toggleSortOrder,
        ),
      ],
    );
  }
}

/// Local styled pill used only to keep the two compact controls aligned.
/// It wraps a real [Material] InkWell so ripple/semantics stay native.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color bg =
        active ? scheme.primaryContainer.withValues(alpha: 0.5) : scheme.surfaceContainerLow;
    final Color fg = active ? scheme.primary : scheme.onSurfaceVariant;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips({required this.provider});

  final ExpenseProvider provider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _choiceChip(
            context,
            label: 'All',
            icon: Icons.apps_rounded,
            selected: provider.categoryFilter == null,
            onSelected: (_) => provider.setCategoryFilter(null),
          ),
          const SizedBox(width: 6),
          for (int i = 0; i < AppConstants.categories.length; i++)
            Padding(
              padding: EdgeInsets.only(
                right: i == AppConstants.categories.length - 1 ? 0 : 4,
              ),
              child: _choiceChip(
                context,
                label: AppConstants.categories[i],
                icon: AppConstants.categoryIcons[i],
                selected: provider.categoryFilter == AppConstants.categories[i],
                onSelected: (bool sel) => provider.setCategoryFilter(
                  sel ? AppConstants.categories[i] : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _choiceChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 14,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: onSelected,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
