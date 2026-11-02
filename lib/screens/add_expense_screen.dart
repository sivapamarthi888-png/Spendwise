import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';

/// Screen 3 — Add / Edit Expense form with complete field validation.
///
/// Used for both creating a new transaction and editing an existing one
/// ([editTarget]). On success it notifies the user, refreshes the Provider
/// state and returns to the previous screen.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.editTarget});

  /// When non-null the form edits this transaction instead of creating one.
  final Expense? editTarget;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Field state.
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  String? _category;
  String? _paymentMethod;
  bool _saving = false;
  bool _triedToSubmit = false; // selection errors shown only after first try

  bool get _isEditing => widget.editTarget != null;
  bool get _showIncompleteErrors => _triedToSubmit;

  @override
  void initState() {
    super.initState();
    final Expense? target = widget.editTarget;
    if (target != null) {
      _type = target.type;
      _amountController.text =
          target.amount == target.amount.truncateToDouble()
              ? target.amount.toStringAsFixed(0)
              : target.amount.toStringAsFixed(2);
      _descriptionController.text = target.description ?? '';
      _date = target.date;
      _category = target.category;
      _paymentMethod = target.paymentMethod;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ---------- Validation ----------

  String? _validateAmount(String? raw) {
    final String text = (raw ?? '').trim();
    if (text.isEmpty) {
      return 'Amount is required';
    }
    // Input formatters block letters, but be robust to pasted junk anyway.
    final String cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
    final double? parsed = double.tryParse(cleaned);
    if (cleaned.isEmpty || parsed == null || parsed.isNaN || parsed.isInfinite) {
      return 'Amount must be numeric';
    }
    final double amount = CurrencyFormatter.parseAmount(text);
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }
    if (amount > AppConstants.maxAmount) {
      return 'Amount is too large';
    }
    return null;
  }

  String? _validateDescription(String? raw) {
    final String text = (raw ?? '').trim();
    // Description is optional but length-capped for display hygiene.
    if (text.length > AppConstants.maxDescriptionLength) {
      return 'Description must be at most ${AppConstants.maxDescriptionLength} characters';
    }
    return null;
  }

  // ---------- Submit ----------

  Future<void> _submit() async {
    if (_saving) return; // guard rapid double taps

    final bool selectionsOk =
        _category != null && _paymentMethod != null;
    setState(() => _triedToSubmit = true);

    final bool formOk = _formKey.currentState?.validate() ?? false;
    if (!selectionsOk || !formOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the highlighted fields'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final ExpenseProvider provider = context.read<ExpenseProvider>();

    final double amount = CurrencyFormatter.parseAmount(_amountController.text);

    // Keep time-of-entry semantics: new records timestamp now; edits keep
    // the original clock time and only change the calendar date.
    final DateTime original = widget.editTarget?.date ?? DateTime.now();
    final DateTime finalDate = DateTime(
      _date.year,
      _date.month,
      _date.day,
      original.hour,
      original.minute,
    );

    final Expense record = Expense(
      id: widget.editTarget?.id,
      type: _type,
      amount: amount,
      category: _category!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: finalDate,
      paymentMethod: _paymentMethod!,
      createdAt: widget.editTarget?.createdAt ?? DateTime.now(),
    );

    final bool ok =
        _isEditing
            ? await provider.updateExpense(record)
            : await provider.addExpense(record);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Transaction updated successfully'
                : _type == TransactionType.income
                    ? 'Income saved successfully'
                    : 'Expense saved successfully',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      if (_isEditing) {
        Navigator.of(context).pop(true); // lets the detail screen close too
        return;
      }
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Update failed. The record may have been deleted.'
              : 'Could not save. Please try again.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Transaction' : 'Add Expense'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: <Widget>[
              _TypeSelector(
                selected: _type,
                onChanged: (TransactionType t) {
                  setState(() => _type = t);
                  // Re-validate amount only on user edits to avoid noise.
                },
              ),
              const SizedBox(height: 18),
              _AmountField(
                controller: _amountController,
                validator: _validateAmount,
                isIncome: _type == TransactionType.income,
              ),
              const SizedBox(height: 18),
              _LabeledSection(
                title: 'Category',
                errorText:
                    _showIncompleteErrors && _category == null
                        ? 'Please select a category'
                        : null,
                child: _CategoryGrid(
                  selected: _category,
                  onChanged: (String c) => setState(() => _category = c),
                ),
              ),
              const SizedBox(height: 18),
              _LabeledSection(
                title: 'Payment Method',
                errorText:
                    _showIncompleteErrors && _paymentMethod == null
                        ? 'Please select a payment method'
                        : null,
                child: _PaymentDropdown(
                  selected: _paymentMethod,
                  onChanged: (String? p) => setState(() => _paymentMethod = p),
                ),
              ),
              const SizedBox(height: 18),
              _DateField(
                date: _date,
                onChanged: (DateTime d) => setState(() => _date = d),
              ),
              const SizedBox(height: 18),
              _DescriptionField(
                controller: _descriptionController,
                validator: _validateDescription,
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _saving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Transaction' : 'Save Transaction',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Let user pick Expense / Income
// ---------------------------------------------------------------------------
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TransactionType>(
      segments: const <ButtonSegment<TransactionType>>[
        ButtonSegment<TransactionType>(
          value: TransactionType.expense,
          icon: Icon(Icons.north_east_rounded, size: 18),
          label: Text('Expense'),
        ),
        ButtonSegment<TransactionType>(
          value: TransactionType.income,
          icon: Icon(Icons.south_west_rounded, size: 18),
          label: Text('Income'),
        ),
      ],
      selected: <TransactionType>{selected},
      onSelectionChanged: (Set<TransactionType> selection) =>
          onChanged(selection.first),
    );
  }
}

class _LabeledSection extends StatelessWidget {
  const _LabeledSection({
    required this.title,
    required this.child,
    this.errorText,
  });

  final String title;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: theme.textTheme.titleSmall),
        ),
        child,
        if (errorText != null) ...<Widget>[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.validator,
    required this.isIncome,
  });

  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}\.?\d{0,2}')),
      ],
      validator: validator,
      textInputAction: TextInputAction.next,
      maxLength: 12,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: 'Amount',
        hintText: '0.00',
        prefixText: '${CurrencyFormatter.symbol} ',
        counterText: '', // hide assistant counter
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (int i = 0; i < AppConstants.categories.length; i++)
          ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  AppConstants.categoryIcons[i],
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(AppConstants.categories[i]),
              ],
            ),
            selected: selected == AppConstants.categories[i],
            onSelected: (bool sel) {
              if (sel) onChanged(AppConstants.categories[i]);
            },
            labelStyle: theme.textTheme.labelMedium,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _PaymentDropdown extends StatelessWidget {
  const _PaymentDropdown({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      items: <String>[...AppConstants.paymentMethods].map((String method) {
        return DropdownMenuItem<String>(
          value: method,
          child: Text(method),
        );
      }).toList(),
      onChanged: onChanged,
      // No inline validator: the section-level error text (_LabeledSection)
      // is the single source for "Please select a payment method", keeping
      // one message per field instead of a duplicated error row.
      hint: const Text('Select payment method'),
      decoration: const InputDecoration(hintText: null),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: AppConstants.firstSelectableDate,
          lastDate: DateTime.now().add(const Duration(days: 365)),
          helpText: 'Select transaction date',
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          suffixIcon: Icon(Icons.calendar_month_rounded),
        ),
        child: SizedBox(
          height: 20,
          child: Text(
            _formatDate(date),
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }

  // Formatted locally to keep this widget self-contained for tests.
  static String _formatDate(DateTime d) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField({required this.controller, required this.validator});

  final TextEditingController controller;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: AppConstants.maxDescriptionLength,
      maxLines: 3,
      minLines: 2,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: TextInputAction.newline,
      decoration: const InputDecoration(
        labelText: 'Description (optional)',
        hintText: 'e.g. Lunch at the canteen',
        alignLabelWithHint: true,
      ),
    );
  }
}
