import 'package:flutter/material.dart';
import 'package:kigali_connect/presentation/screens/listings/listings_screen.dart';
import 'package:kigali_connect/presentation/screens/map/map_view_screen.dart';
import 'package:kigali_connect/presentation/screens/settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _tabs = [
    ListingsScreen(),
    MapViewScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.list_alt_outlined),
      activeIcon: Icon(Icons.list_alt),
      label: 'Places',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.map_outlined),
      activeIcon: Icon(Icons.map),
      label: 'Map',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _navItems,
      ),
    );
  }
}
