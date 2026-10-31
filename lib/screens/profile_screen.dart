import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../utils/helpers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Người dùng';
  int _count = 0;
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final db = DatabaseHelper.instance;
    final summary = await db.getSummary();
    final all = await db.getAllTransactions();
    if (!mounted) return;
    setState(() {
      _name = prefs.getString('user_name') ?? 'Người dùng';
      _balance = summary['balance'] ?? 0;
      _count = all.length;
    });
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _name);
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Đổi tên hiển thị'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(c, ctrl.text.trim()),
              child: const Text('Lưu')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', result);
      setState(() => _name = result);
    }
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa toàn bộ dữ liệu?'),
        content:
        const Text('Tất cả giao dịch sẽ bị xóa và không thể khôi phục.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Xóa hết')),
        ],
      ),
    );
    if (ok != true) return;
    await DatabaseHelper.instance.deleteAllTransactions();
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa toàn bộ giao dịch')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                    radius: 40, child: Icon(Icons.person, size: 40)),
                const SizedBox(height: 12),
                Text(_name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _stat('Số dư', formatVnd(_balance))),
              const SizedBox(width: 12),
              Expanded(child: _stat('Giao dịch', '$_count')),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Đổi tên hiển thị'),
            onTap: _editName,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Xóa toàn bộ giao dịch'),
            onTap: _deleteAll,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Giới thiệu'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Quản lý chi tiêu',
              applicationVersion: '1.0.0',
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16)),
    child: Column(
      children: [
        Text(label),
        const SizedBox(height: 4),
        Text(value,
            style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}