import 'dart:math';
import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';

class WebDeviceFrame extends StatelessWidget {
  const WebDeviceFrame({super.key, required this.child});

  final Widget child;

  static const double _screenW = 393;
  static const double _screenH = 852;
  static const double _bezelThickness = 12;
  static const double _outerW = _screenW + _bezelThickness * 2; // 417
  static const double _outerH = _screenH + _bezelThickness * 2; // 876
  static const double _minContentW = _outerW;
  static const double _minContentH = _outerH + 40; // 916

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFF1A1A1E),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final contentW = max(constraints.maxWidth, _minContentW);
            final contentH = max(constraints.maxHeight, _minContentH);

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  width: contentW,
                  height: contentH,
                  child: Center(child: _buildFrame(ctx)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrame(BuildContext context) {
    return Container(
      width: _outerW,
      height: _outerH,
      decoration: ShapeDecoration(
        color: const Color(0xFF2C2C2E),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 66,
            cornerSmoothing: 1,
          ),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(_bezelThickness),
        child: ClipSmoothRect(
          radius: SmoothBorderRadius(
            cornerRadius: 54,
            cornerSmoothing: 1,
          ),
          child: SizedBox(
            width: _screenW,
            height: _screenH,
            child: Stack(
              children: [
                // App content with synthetic MediaQuery
                Positioned.fill(
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: const Size(_screenW, _screenH),
                      padding: const EdgeInsets.only(top: 59, bottom: 34),
                      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
                      viewInsets: EdgeInsets.zero,
                      systemGestureInsets: const EdgeInsets.only(bottom: 34),
                    ),
                    child: child,
                  ),
                ),
                // Dynamic Island
                Positioned(
                  top: 11,
                  left: (_screenW - 125) / 2,
                  child: IgnorePointer(
                    child: Container(
                      width: 125,
                      height: 37,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(18.5),
                      ),
                    ),
                  ),
                ),
                // Home indicator
                Positioned(
                  bottom: 8,
                  left: (_screenW - 140) / 2,
                  child: IgnorePointer(
                    child: Container(
                      width: 140,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
