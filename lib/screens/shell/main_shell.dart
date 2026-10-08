import 'package:flutter/material.dart';

import '../doctors/doctors_page.dart';
import '../exercises/exercises_page.dart';
import '../food/restaurants_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';

// da el shell beta3 el patient: feh el bottom navigation bel 5 tabs
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // el home bt-call di 3shan t8yr el tab (masalan "Find Doctors")
  void _goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack by7fz state kol tab lama nnt2el benhom
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(onSwitchTab: _goToTab),
          const DoctorsPage(),
          const ExercisesPage(),
          const RestaurantsPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              selectedIcon: Icon(Icons.medical_services_rounded),
              label: 'Doctors'),
          NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center_rounded),
              label: 'Exercises'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant_rounded),
              label: 'Food'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}
