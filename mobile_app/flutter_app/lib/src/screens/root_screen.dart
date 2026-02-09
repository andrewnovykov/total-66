import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'account_screen.dart';
import 'categories_screen.dart';
import 'goals_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  static const List<String> _titles = <String>['Home', 'Explore', 'Create', 'Challenges', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const GoalsScreen(),
      const CategoriesScreen(),
      const _ComingSoonScreen(title: 'Create'),
      const _ComingSoonScreen(title: 'Challenges'),
      const AccountScreen(),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0 || _selectedIndex == 4
          ? _homeAppBar()
          : AppBar(title: Text(_titles[_selectedIndex])),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        height: 84,
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_outlined, color: AppTheme.textPrimary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: AppTheme.textPrimary),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: _CreateNavIcon(selected: false),
            selectedIcon: _CreateNavIcon(selected: true),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department_outlined, color: AppTheme.textPrimary),
            label: 'Challenges',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textPrimary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _homeAppBar() {
    return AppBar(
      toolbarHeight: 86,
      titleSpacing: 10,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3C78F4), Color(0xFF5142E5)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'HeadsUp',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 36 / 2,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3C78F4), Color(0xFF5142E5)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        Container(
          margin: const EdgeInsets.only(right: 10),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.menu_rounded, color: Color(0xFF5D6B82), size: 26),
        ),
      ],
    );
  }
}

class _CreateNavIcon extends StatelessWidget {
  const _CreateNavIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFF3368EA),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.add,
        color: Colors.white,
        size: selected ? 20 : 18,
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title screen coming soon',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
