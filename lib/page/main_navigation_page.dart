import 'package:flutter/material.dart';
import 'home_page.dart';
import 'all_task_list_page.dart';
import '../services/app_language.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() =>
      _MainNavigationPageState();
}

class _MainNavigationPageState
    extends State<MainNavigationPage> {

  int currentIndex = 0;

  final pages = [
    const HomePage(),
    const AllTaskListPage(),
  ];

  String tr(String th, String en) => AppLanguage.instance.text(th, en);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) {
        return Scaffold(
          body: pages[currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            selectedItemColor: Colors.pink,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: tr('หน้าแรก', 'Home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.list),
                label: tr('งานทั้งหมด', 'All Tasks'),
              ),
            ],
          ),
        );
      },
    );
  }
}