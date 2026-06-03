import 'package:auto_route/auto_route.dart';

import '../pages/root_shell_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: RootShellRoute.page,
          initial: true,
          children: [
            AutoRoute(page: ProjectsTabRoute.page, path: 'projects'),
            AutoRoute(page: TodayTabRoute.page, path: 'today'),
            AutoRoute(page: WeekTabRoute.page, path: 'week'),
            AutoRoute(page: SettingsTabRoute.page, path: 'settings'),
          ],
        ),
      ];
}
