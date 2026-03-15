import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/exiftool_reminder_dialog.dart';
import 'core/widgets/splash_screen.dart';
import 'features/geotagging/data/repositories/photo_repository_impl.dart';
import 'features/geotagging/presentation/controllers/geotagging_controller.dart';
import 'features/geotagging/presentation/pages/geotagging_page.dart';

class GeoPicApp extends StatefulWidget {
  const GeoPicApp({super.key});

  @override
  State<GeoPicApp> createState() => _GeoPicAppState();
}

class _GeoPicAppState extends State<GeoPicApp> {
  late final GeotaggingController _controller;
  bool _splashMinTimeElapsed = false;

  static const _splashMinDuration = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _controller = GeotaggingController(PhotoRepositoryImpl());
    Future.delayed(_splashMinDuration, () {
      if (mounted) setState(() => _splashMinTimeElapsed = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final ready = _controller.hasCompletedInitialLoad && _splashMinTimeElapsed;
          if (!ready) {
            return const SplashScreen();
          }
          return ExiftoolReminderOverlay(
            child: GeotaggingPage(controller: _controller),
          );
        },
      ),
    );
  }
}
