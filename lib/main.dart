import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/preferences_provider.dart';
import 'providers/eat_flow_provider.dart';
import 'providers/meal_log_provider.dart';
import 'providers/saved_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'widgets/web_device_frame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WhatToEatRoot());
}

class WhatToEatRoot extends StatelessWidget {
  const WhatToEatRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
        ChangeNotifierProvider(create: (_) => EatFlowProvider()),
        ChangeNotifierProvider(create: (_) {
          final log = MealLogProvider();
          if (Uri.base.queryParameters['demo'] == 'heavy-day') log.seedHeavyDay();
          return log;
        }),
        ChangeNotifierProvider(create: (_) => SavedProvider()),
      ],
      child: const _App(),
    );
  }
}

class _App extends StatefulWidget {
  const _App();

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  late final _router = buildRouter(context.read<PreferencesProvider>());

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp.router(
      title: 'WhatToEat',
      theme: AppTheme.light(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: kIsWeb
          ? (ctx, child) => WebDeviceFrame(child: child ?? const SizedBox())
          : null,
    );
    return app;
  }
}
