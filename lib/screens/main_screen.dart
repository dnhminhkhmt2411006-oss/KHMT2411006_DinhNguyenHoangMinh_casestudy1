import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  // Tạo mới mỗi lần đổi tab để dữ liệu luôn được tải lại
  Widget _page() {
    switch (_index) {
      case 1:
        return const TransactionsScreen();
      case 2:
        return const StatisticsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return DashboardScreen(onSeeAll: () => setState(() => _index = 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _page(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Trang chủ'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Giao dịch'),
          NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Thống kê'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Cá nhân'),
        ],
      ),
    );
  }
}