import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../utils/helpers.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionModel> _list = [];
  String? _type; // null = tất cả
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance
        .getTransactions(type: _type, keyword: _query);
    if (!mounted) return;
    setState(() {
      _list = data;
      _loading = false;
    });
  }

  Future<void> _openForm([TransactionModel? t]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransactionFormScreen(transaction: t)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giao dịch')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, danh mục, ghi chú...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) {
                _query = v;
                _load();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                for (final f in <List<String?>>[
                  [null, 'Tất cả'],
                  [DatabaseHelper.typeIncome, 'Thu nhập'],
                  [DatabaseHelper.typeExpense, 'Chi tiêu'],
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f[1]!),
                      selected: _type == f[0],
                      onSelected: (_) {
                        _type = f[0];
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                ? const Center(child: Text('Chưa có giao dịch nào'))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _list.length,
              itemBuilder: (_, i) {
                final t = _list[i];
                final inc = t.isIncome;
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete,
                        color: Colors.white),
                  ),
                  confirmDismiss: (_) async =>
                  await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Xóa giao dịch?'),
                      content: Text(
                          'Bạn có chắc muốn xóa "${t.title}"?'),
                      actions: [
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(c, false),
                            child: const Text('Hủy')),
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(c, true),
                            child: const Text('Xóa')),
                      ],
                    ),
                  ) ??
                      false,
                  onDismissed: (_) async {
                    await DatabaseHelper.instance
                        .deleteTransaction(t.id!);
                    _load();
                  },
                  child: ListTile(
                    onTap: () => _openForm(t),
                    leading: CircleAvatar(
                      backgroundColor: inc
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      child: Icon(
                          inc
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: inc ? Colors.green : Colors.red),
                    ),
                    title: Text(t.title),
                    subtitle: Text(
                        '${t.category} • ${formatDate(t.date)}'),
                    trailing: Text(
                      '${inc ? '+' : '-'}${formatVnd(t.amount)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: inc ? Colors.green : Colors.red),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}