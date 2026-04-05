import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final VoidCallback onSaveComplete;

  const AddTransactionScreen({super.key, required this.onSaveComplete});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Еда';
  
  final List<String> _expenseCategories = ['Еда', 'Транспорт', 'Развлечения', 'Коммунальные услуги', 'Покупки', 'Другое'];
  final List<String> _incomeCategories = ['Зарплата', 'Фриланс', 'Бизнес', 'Подарки', 'Инвестиции', 'Другое'];

  @override
  Widget build(BuildContext context) {
    final categories = _selectedType == TransactionType.expense ? _expenseCategories : _incomeCategories;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить транзакцию'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Transaction Type Selector
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.expense, label: Text('Расход')),
                ButtonSegment(value: TransactionType.income, label: Text('Доход')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() => _selectedType = newSelection.first);
              },
            ),
            const SizedBox(height: 20),
            
            // Amount
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Сумма (KGS)',
                prefixIcon: const Icon(Icons.money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            
            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Категория',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedCategory = val!);
              },
            ),
            const SizedBox(height: 20),
            
            // Date Picker
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Дата',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(DateFormat('dd MMMM yyyy', 'ru_RU').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 20),
            
            // Note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Заметка (необязательно)',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
            
            // Save button
            ElevatedButton(
              onPressed: _saveEntry,
              child: const Text('Добавить', style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }

  void _saveEntry() async {
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите корректную сумму')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Вы уверены, что хотите сохранить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final transaction = Transaction(
      id: const Uuid().v4(),
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      type: _selectedType,
      note: _noteController.text,
    );

    ref.read(transactionsProvider.notifier).addTransaction(transaction);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Успешно добавлено!'), backgroundColor: Colors.green),
    );
    
    // Clear inputs
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });

    // Notify parent to switch tab
    widget.onSaveComplete();
  }
}
