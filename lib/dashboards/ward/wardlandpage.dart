import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtaasuite/services/translation_service.dart';

class WardDashboard extends StatefulWidget {
  const WardDashboard({super.key});

  @override
  State<WardDashboard> createState() => _WardDashboardState();
}

class _WardDashboardState extends State<WardDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text(tr('dashboard.ward.welcome'))),
    Center(child: Text(tr('dashboard.ward.tribunal_cases'))),
    Center(child: Text(tr('dashboard.ward.reports'))),
    Center(child: Text(tr('dashboard.ward.settings'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('dashboard.ward.title')),
        backgroundColor: Colors.blue.shade800,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(tr('dashboard.ward.welcome')),
              accountEmail: Text(tr('common.loading')),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  "WO",
                  style: TextStyle(fontSize: 24, color: Colors.blue.shade800),
                ),
              ),
              decoration: BoxDecoration(color: Colors.blue.shade800),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(tr('dashboard.ward.profile')),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: Text(tr('dashboard.ward.manage_cases')),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(tr('dashboard.ward.notifications')),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(tr('dashboard.ward.logout')),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop(); // close drawer; AuthWrapper rebuilds to LoginPage
              },
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: tr('dashboard.ward.home')),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: tr('dashboard.ward.tribunal_cases')),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: tr('dashboard.ward.reports')),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: tr('dashboard.ward.settings')),
        ],
      ),
    );
  }
}
