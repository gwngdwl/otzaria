import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:otzaria/settings/tabs/settings_tabs.dart';

class MySettingsScreen extends StatefulWidget {
  const MySettingsScreen({super.key});

  @override
  State<MySettingsScreen> createState() => _MySettingsScreenState();
}

class _MySettingsScreenState extends State<MySettingsScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;

  final List<_TabInfo> _tabs = const [
    _TabInfo(
      label: 'עיצוב',
      icon: FluentIcons.paint_brush_24_regular,
    ),
    _TabInfo(
      label: 'תצוגת ספרים',
      icon: FluentIcons.book_24_regular,
    ),
    _TabInfo(
      label: 'ספרייה',
      icon: FluentIcons.library_24_regular,
    ),
    _TabInfo(
      label: 'לוח שנה',
      icon: FluentIcons.calendar_24_regular,
    ),
    _TabInfo(
      label: 'גימטריה',
      icon: FluentIcons.calculator_24_regular,
    ),
    _TabInfo(
      label: 'גיבוי',
      icon: FluentIcons.arrow_sync_24_regular,
    ),
    _TabInfo(
      label: 'מתקדם',
      icon: FluentIcons.settings_24_regular,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            title: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: _tabs
                  .map((tab) => SizedBox(
                        width: 100,
                        child: Tab(
                          text: tab.label,
                          icon: Icon(tab.icon, size: 20),
                        ),
                      ))
                  .toList(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: Theme.of(context).dividerColor,
                height: 1.0,
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              AppearanceSettingsTab(),
              ReadingSettingsTab(),
              LibrarySettingsTab(),
              CalendarSettingsTab(),
              GematriaSettingsTab(),
              BackupSettingsTab(),
              AdvancedSettingsTab(),
            ],
          ),
        );
  }

}

class _TabInfo {
  final String label;
  final IconData icon;

  const _TabInfo({
    required this.label,
    required this.icon,
  });
}
