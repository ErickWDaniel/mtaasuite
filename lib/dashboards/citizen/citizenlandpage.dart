import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtaasuite/services/translation_service.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text(tr('dashboard.citizen.welcome'))),
    Center(child: Text(tr('dashboard.citizen.my_reports'))),
    Center(child: Text(tr('dashboard.citizen.settings'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('dashboard.citizen.title')),
        backgroundColor: Colors.green.shade700,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(tr('common.loading')),
              accountEmail: Text(tr('common.loading')),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  "JD",
                  style: TextStyle(fontSize: 24, color: Colors.green.shade700),
                ),
              ),
              decoration: BoxDecoration(color: Colors.green.shade700),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(tr('dashboard.citizen.profile')),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(tr('dashboard.citizen.notifications')),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(tr('dashboard.citizen.logout')),
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
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: tr('dashboard.citizen.home')),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: tr('dashboard.citizen.my_reports')),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: tr('dashboard.citizen.settings')),
        ],
      ),
    );
  }
}
