import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import 'transaction_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  /// Gọi khi bấm "Xem tất cả" (MainScreen dùng để chuyển sang tab Giao dịch)
  final VoidCallback? onSeeAll;
  const DashboardScreen({super.key, this.onSeeAll});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<TransactionModel> _list = [];
  final _money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance.getAllTransactions();
    if (!mounted) return;
    setState(() => _list = data);
  }

  // Chấp nhận cả 'income'/'Thu' để không phụ thuộc cách form đang lưu
  bool _isIncome(TransactionModel t) => t.type == 'income' || t.type == 'Thu';

  double get _income =>
      _list.where(_isIncome).fold(0.0, (s, e) => s + e.amount);

  double get _expense =>
      _list.where((e) => !_isIncome(e)).fold(0.0, (s, e) => s + e.amount);

  Future<void> _openForm([TransactionModel? t]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TransactionFormScreen(transaction: t)),
    );
    if (changed == true) _load();
  }

  Future<void> _confirmDelete(TransactionModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giao dịch'),
        content: Text('Bạn có chắc muốn xóa "${t.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.deleteTransaction(t.id!);
      _load();
    }
  }

  // Icon + màu theo danh mục
  (IconData, Color) _categoryStyle(String category) {
    final c = category.toLowerCase();
    if (c.contains('ăn')) return (Icons.restaurant, Colors.orange);
    if (c.contains('mua')) return (Icons.shopping_bag, Colors.pink);
    if (c.contains('lương')) return (Icons.payments, AppColors.income);
    if (c.contains('đi lại') || c.contains('xe')) {
      return (Icons.directions_car, Colors.blue);
    }
    if (c.contains('học')) return (Icons.menu_book, Colors.purple);
    return (Icons.category, Colors.blueGrey);
  }

  @override
  Widget build(BuildContext context) {
    final balance = _income - _expense;
    final recent = [..._list]
      ..sort((a, b) => b.date.compareTo(a.date)); // mới nhất trước
    final shown = recent.take(5).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(balance),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _summaryCard('Thu nhập', _income, Icons.arrow_upward,
                        AppColors.income, AppColors.incomeBg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard('Chi tiêu', _expense,
                        Icons.arrow_downward, AppColors.expense,
                        AppColors.expenseBg),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chi tiêu gần đây',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: widget.onSeeAll,
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
            ),
            if (shown.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: Text('Chưa có giao dịch nào')),
              )
            else
              ...shown.map(_transactionTile),
            const SizedBox(height: 90), // chừa chỗ cho nút +
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _header(double balance) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Xin chào!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Hôm nay bạn chi tiêu thế nào?',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Số dư hiện tại',
                          style: TextStyle(color: AppColors.textGrey)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _money.format(balance),
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String label, double value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_money.format(value),
                style: TextStyle(
                    color: color, fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(TransactionModel t) {
    final isIncome = _isIncome(t);
    final (icon, color) = _categoryStyle(t.category);
    final date = DateTime.tryParse(t.date);
    final dateText =
    date == null ? t.date : DateFormat('dd/MM/yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openForm(t),
          onLongPress: () => _confirmDelete(t),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(dateText,
                          style: const TextStyle(
                              color: AppColors.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'}${_money.format(t.amount)}',
                  style: TextStyle(
                    color: isIncome ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}