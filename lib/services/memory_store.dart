import '../models/expense.dart';
import 'database_service.dart';

/// Non-persistent [TransactionStore] used wherever SQLite cannot run —
/// currently the Flutter web preview. Records live only in RAM for the
/// active session; on Android the app binds [DatabaseService] instead.
class MemoryStore implements TransactionStore {
  MemoryStore({List<Expense> seed = const <Expense>[]}) {
    for (final Expense e in seed) {
      // insert() assigns sequential ids and copies the record.
      insert(e);
    }
  }

  final Map<int, Expense> _records = <int, Expense>{};
  int _nextId = 1;

  @override
  Future<void> open() async {}

  @override
  Future<List<Expense>> loadAll() async {
    final List<Expense> list = _records.values.toList()
      ..sort((Expense a, Expense b) =>
          b.date.millisecondsSinceEpoch - a.date.millisecondsSinceEpoch);
    return list;
  }

  @override
  Future<int> insert(Expense expense) async {
    final int id = _nextId++;
    _records[id] = expense.copyWith(id: id);
    return id;
  }

  @override
  Future<int> update(Expense expense) async {
    final int? id = expense.id;
    if (id == null || !_records.containsKey(id)) return 0;
    _records[id] = expense.copyWith(id: id);
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    if (!_records.containsKey(id)) return 0;
    _records.remove(id);
    return 1;
  }

  @override
  Future<int> clearAll() async {
    final int count = _records.length;
    _records.clear();
    return count;
  }

  @override
  Future<void> close() async {}
}

/// Sample records shown only in the web preview so the dashboard, chart and
/// statistics screens render meaningfully. The device (Android) build never
/// uses this store.
List<Expense> previewSeed() {
  final DateTime now = DateTime.now();
  Expense mk(
    TransactionType type,
    double amount,
    String category,
    String? description,
    DateTime date,
    String payment,
  ) =>
      Expense(
        id: null,
        type: type,
        amount: amount,
        category: category,
        description: description,
        date: date,
        paymentMethod: payment,
        createdAt: date,
      );

  return <Expense>[
    mk(TransactionType.expense, 320, 'Food', 'Groceries for the week',
        now.subtract(const Duration(hours: 3)), 'UPI'),
    mk(TransactionType.expense, 45, 'Travel', 'Bus fare',
        now.subtract(const Duration(hours: 26)), 'Cash'),
    mk(TransactionType.expense, 120, 'Food', 'Cafeteria coffee',
        now.subtract(const Duration(hours: 30)), 'UPI'),
    mk(TransactionType.expense, 2500, 'Shopping', 'Winter jacket',
        now.subtract(const Duration(days: 3)), 'Card'),
    mk(
        TransactionType.income,
        20000,
        'Other',
        'Monthly stipend',
        now.subtract(const Duration(days: 5)),
        'Bank Transfer'),
    mk(TransactionType.expense, 899, 'Entertainment', 'Movie night',
        now.subtract(const Duration(days: 6)), 'UPI'),
  ];
}
