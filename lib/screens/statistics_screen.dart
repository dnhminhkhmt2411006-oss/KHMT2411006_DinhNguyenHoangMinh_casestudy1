import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../utils/helpers.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  double _income = 0, _expense = 0;
  Map<String, double> _cats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final from = DateTime(_month.year, _month.month, 1);
    final to = DateTime(_month.year, _month.month + 1, 0); // ngày cuối tháng
    final db = DatabaseHelper.instance;
    final summary = await db.getSummary(from: from, to: to);
    final cats = await db.getTotalByCategory(
        type: DatabaseHelper.typeExpense, from: from, to: to);
    if (!mounted) return;
    setState(() {
      _income = summary['income'] ?? 0;
      _expense = summary['expense'] ?? 0;
      _cats = cats;
      _loading = false;
    });
  }

  void _changeMonth(int delta) {
    _month = DateTime(_month.year, _month.month + delta);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final balance = _income - _expense;
    final total = _income + _expense;
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left)),
              Text('Tháng ${_month.month}/${_month.year}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _summary('Thu nhập', _income, Colors.green,
                      Colors.green.shade50)),
              const SizedBox(width: 12),
              Expanded(
                  child: _summary('Chi tiêu', _expense, Colors.red,
                      Colors.red.shade50)),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Chênh lệch'),
              trailing: Text(
                formatVnd(balance),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? Colors.green : Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Thu nhập so với chi tiêu',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (total == 0)
            const Text('Chưa có dữ liệu trong tháng này')
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 18,
                child: Row(children: [
                  if (_income > 0)
                    Expanded(
                        flex: (_income * 100).round(),
                        child: Container(color: Colors.green)),
                  if (_expense > 0)
                    Expanded(
                        flex: (_expense * 100).round(),
                        child: Container(color: Colors.red)),
                ]),
              ),
            ),
          const SizedBox(height: 24),
          const Text('Chi tiêu theo danh mục',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_cats.isEmpty) const Text('Không có khoản chi nào'),
          for (final e in _cats.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key),
                      Text(
                          '${formatVnd(e.value)} (${(e.value / _expense * 100).toStringAsFixed(0)}%)'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: e.value / _expense,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _summary(String label, double value, Color color, Color bg) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 4),
            Text(formatVnd(value),
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      );
}