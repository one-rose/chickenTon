import 'package:flutter/material.dart';
import 'package:template/common/layout/default_layout.dart';
import 'package:template/core/themes/app_colors.dart';
import 'package:template/features/calendar/calendar_page.dart';
import 'package:template/features/eisenhower/eisenhower_page.dart';
import 'package:template/features/settings/settings_page.dart';
import 'package:template/features/task/task_page.dart';

class RootTab extends StatefulWidget {
  const RootTab({super.key});
  static String get routeName => 'home';

  @override
  State<RootTab> createState() => _RootTabState();
}

class _RootTabState extends State<RootTab> with SingleTickerProviderStateMixin {
  late TabController controller;
  var index = 0;

  @override
  void initState() {
    super.initState();

    controller = TabController(length: 4, vsync: this);
    controller.addListener(tabListener);
  }

  @override
  void dispose() {
    controller.removeListener(tabListener);

    super.dispose();
  }

  void tabListener() {
    setState(() {
      index = controller.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      // title: '아이젠가든',
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: context.colors.primary,
        unselectedItemColor: context.colors.textPrimary,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        type: BottomNavigationBarType.fixed,
        onTap: (int index) {
          controller.animateTo(index);
        },
        currentIndex: index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: '과제',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: '달력',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: '매트릭스',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: '설정',
          ),
        ],
      ),
      child: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children: const [
          TaskPage(),
          CalendarPage(),
          EisenhowerPage(),
          SettingsPage(),
        ],
      ),
    );
  }
}
