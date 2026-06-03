import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import 'dashboard_page.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

@RoutePage()
class RootShellPage extends ConsumerWidget {
  const RootShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AutoTabsRouter(
      routes: const [
        ProjectsTabRoute(),
        TodayTabRoute(),
        WeekTabRoute(),
        SettingsTabRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return _WindowTitleUpdater(
          activeIndex: tabsRouter.activeIndex,
          child: Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: tabsRouter.activeIndex,
                  onDestinationSelected: tabsRouter.setActiveIndex,
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.folder_outlined),
                      selectedIcon: Icon(Icons.folder),
                      label: Text('Projets'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.today_outlined),
                      selectedIcon: Icon(Icons.today),
                      label: Text('Aujourd’hui'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.date_range_outlined),
                      selectedIcon: Icon(Icons.date_range),
                      label: Text('Cette semaine'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Paramètres'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WindowTitleUpdater extends StatefulWidget {
  final int activeIndex;
  final Widget child;

  const _WindowTitleUpdater({
    required this.activeIndex,
    required this.child,
  });

  @override
  State<_WindowTitleUpdater> createState() => _WindowTitleUpdaterState();
}

class _WindowTitleUpdaterState extends State<_WindowTitleUpdater> {
  static const _titles = [
    'Projets',
    'Aujourd’hui',
    'Cette semaine',
    'Paramètres'
  ];

  @override
  void initState() {
    super.initState();
    _updateTitle();
  }

  @override
  void didUpdateWidget(covariant _WindowTitleUpdater oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      _updateTitle();
    }
  }

  void _updateTitle() {
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      final title = _titles[widget.activeIndex];
      windowManager.setTitle('$title — Gestion des taches');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

@RoutePage()
class ProjectsTabPage extends ConsumerWidget {
  const ProjectsTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardPage(
      section: NavSection.projects,
    );
  }
}

@RoutePage()
class TodayTabPage extends ConsumerWidget {
  const TodayTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardPage(
      section: NavSection.today,
    );
  }
}

@RoutePage()
class WeekTabPage extends ConsumerWidget {
  const WeekTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardPage(
      section: NavSection.week,
    );
  }
}

@RoutePage()
class SettingsTabPage extends ConsumerWidget {
  const SettingsTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardPage(
      section: NavSection.settings,
    );
  }
}
