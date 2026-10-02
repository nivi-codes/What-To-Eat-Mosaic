import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'providers/preferences_provider.dart';
import 'widgets/doodles.dart';
import 'widgets/web_device_frame.dart';

class WhatToEatApp extends StatefulWidget {
  const WhatToEatApp({super.key});

  @override
  State<WhatToEatApp> createState() => _WhatToEatAppState();
}

class _WhatToEatAppState extends State<WhatToEatApp> {
  late final _router = buildRouter(context.read<PreferencesProvider>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'WhatToEat',
      theme: AppTheme.light(),
      routerConfig: _router,
      builder: (context, child) {
        final app = DoodlePrecacher(child: child ?? const SizedBox.shrink());
        return kIsWeb ? WebDeviceFrame(child: app) : app;
      },
    );
  }
}
