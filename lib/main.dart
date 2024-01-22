import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'expense.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(title: "Daily Expense Tracker"),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<DateTime, List<Expense>> _groupedExpenses = {};
  final List<Expense> _userExpenses = [];
  Expense? _editingExpense;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _groupExpensesByDate() {
    _groupedExpenses = {};
    final currentDate = DateTime.now();

    for (final expense in _userExpenses) {
      final date = expense.date ?? DateTime(2000);

      if (date.year == currentDate.year &&
          date.month == currentDate.month &&
          date.day == currentDate.day) {
        if (_groupedExpenses.containsKey(currentDate)) {
          _groupedExpenses[currentDate]!.add(expense);
        } else {
          _groupedExpenses[currentDate] = [expense];
        }
      } else {
        if (_groupedExpenses.containsKey(date)) {
          _groupedExpenses[date]!.add(expense);
        } else {
          _groupedExpenses[date] = [expense];
        }
      }
    }
  }

  void _addNewExpense(String title, double amount, DateTime? chosenDate) {
    if (_editingExpense != null) {
      setState(() {
        _editingExpense!.title = title;
        _editingExpense!.amount = amount;
        _editingExpense!.date = chosenDate;
        _editingExpense = null;
      });

      Fluttertoast.showToast(
        msg: "Expense updated successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } else {
      final newExpense = Expense(
        id: DateTime.now().toString(),
        title: title,
        amount: amount,
        date: chosenDate,
      );

      setState(() {
        _userExpenses.add(newExpense);
      });

      Fluttertoast.showToast(
        msg: "Expense added successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }

    _storeExpenses();
  }

  Future<void> _deleteExpense(String id) async {
    final shouldDelete = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Do you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
            child: const Text('No'),
          ),
        ],
      ),
    );

    if (shouldDelete != null && shouldDelete) {
      setState(() {
        _userExpenses.removeWhere((expense) => expense.id == id);
      });

      Fluttertoast.showToast(
        msg: "Expense deleted successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      _storeExpenses();
    }
  }

  void _startAddNewExpense(BuildContext context, [Expense? expense]) {
    setState(() {
      _editingExpense = expense;
    });

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (_) {
        return SingleChildScrollView(
          reverse: true, // Ensure the content is scrollable
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _editingExpense != null ? 'Update Expense' : 'Add New Expense',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                NewExpenseForm(
                  addExpense: _addNewExpense,
                  editingExpense: _editingExpense,
                  isEditing: _editingExpense != null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _storeExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = _userExpenses.map((expense) => expense.toJson()).toList();
    await prefs.setStringList('expenses', expensesJson);
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList('expenses');

    if (expensesJson != null) {
      setState(() {
        _userExpenses.clear();
        _userExpenses.addAll(expensesJson.map((json) => Expense.fromJson(json)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _groupExpensesByDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Expense Tracker'),
      ),
      body: ListView(
        children: _groupedExpenses.keys.map((date) {
          final expenses = _groupedExpenses[date]!;
          final totalExpense = expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  DateFormat.yMMMd().format(date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                itemBuilder: (ctx, index) {
                  final expense = expenses[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      trailing: Wrap(
                        spacing: 4,
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle, // Square shape
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8), // Fine edges
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () => _startAddNewExpense(context, expense),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle, // Square shape
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8), // Fine edges
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              onPressed: () => _deleteExpense(expense.id),
                            ),
                          ),
                        ],
                      ),
                      leading: Container(
                        width: 60, // Define a fixed width
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle, // Square shape
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8), // Fine edges
                        ),
                        child: Center(
                          child: Text(
                            '₱${expense.amount.toStringAsFixed(2)}', // Use ₱ instead of $
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        expense.title,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      subtitle: Text(
                        expense.date != null
                            ? DateFormat.yMMMd().format(expense.date!)
                            : 'No date provided',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                // leading: const Icon(Icons.monetization_on), // Use Peso sign icon
                title: Text(
                  'Total Expense: ₱${totalExpense.toStringAsFixed(2)}', // Use ₱ instead of $
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _startAddNewExpense(context),
      ),
      persistentFooterButtons: const [
        Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            '© 2024 splucena',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class NewExpenseForm extends StatefulWidget {
  final Function(String, double, DateTime?) addExpense;
  final Expense? editingExpense;
  final bool isEditing;

  const NewExpenseForm({
    Key? key,
    required this.addExpense,
    this.editingExpense,
    required this.isEditing,
  }) : super(key: key);

  @override
  NewExpenseFormState createState() => NewExpenseFormState();
}

class NewExpenseFormState extends State<NewExpenseForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    if (widget.editingExpense != null) {
      _titleController.text = widget.editingExpense!.title;
      _amountController.text = widget.editingExpense!.amount.toString();
      _selectedDate = widget.editingExpense!.date;
    }
  }

  void _submitData() {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text) ?? 0;

    if (enteredTitle.isEmpty || enteredAmount <= 0 || _selectedDate == null) {
      return;
    }

    widget.addExpense(
      enteredTitle,
      enteredAmount,
      _selectedDate,
    );

    Navigator.of(context).pop();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2019),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDate == null
                    ? 'No Date Chosen!'
                    : 'Picked Date: ${DateFormat.yMd().format(_selectedDate!)}',
              ),
              TextButton(
                onPressed: _presentDatePicker,
                child: Text(
                  'Choose Date',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            onPressed: _submitData,
            child: Text(widget.isEditing ? 'Update Expense' : 'Add Expense'),
          ),
        ],
      ),
    );
  }
}
