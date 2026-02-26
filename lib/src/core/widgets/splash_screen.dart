import 'package:flutter/material.dart';

/// Light gray – distinct from pure white so the loading screen is visible.
const _splashBackgroundColor = Color(0xFFF0F0F0);
const _splashAccentOrange = Color(0xFFF26725);

/// Splash/loading screen shown when the application is initializing.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  static const _titleColor = Color(0xFF333333);
  static const _taglineColor = Color(0xFF888888);
  static const _loadingColor = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _splashBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              _MapPinLogo(),
              const SizedBox(height: 24),
              Text(
                'GeoTag',
                style: TextStyle(
                  color: _titleColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 3,
                decoration: BoxDecoration(
                  color: _splashAccentOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'CAPTURE THE MOMENT',
                style: TextStyle(
                  color: _taglineColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_splashAccentOrange),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'LOADING...',
                style: TextStyle(
                  color: _loadingColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPinLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: 72,
        height: 96,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Icon(
              Icons.place,
              size: 96,
              color: _splashAccentOrange,
            ),
            Positioned(
              top: 14,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFF333333),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
