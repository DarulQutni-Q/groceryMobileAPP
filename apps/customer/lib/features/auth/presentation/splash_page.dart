import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/garden_widgets.dart';
import 'auth_artwork.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF96E23B),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: LayoutBuilder(
          builder: (context, size) {
            final top = size.maxWidth * 1.08;
            return SingleChildScrollView(
              child: Stack(
                children: [
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: artwork('splash_hero', width: size.maxWidth),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: top),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: math.max(400, size.maxHeight - top),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: _content(context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _content(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          artwork('garden_symbol_splash', width: 42, height: 39),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'GardenMart',
              style: TextStyle(
                fontFamily: 'GardenSerif',
                fontSize: 24,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      const Text(
        'Belanja Segar & Lengkap\nTanpa Ribet',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'GardenSerif',
          fontSize: 28,
          height: 1.18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Get fresh ingredients and household needs delivered fast with everyday best prices.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, height: 1.15, color: Colors.black),
      ),
      const SizedBox(height: 24),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: DarkPillButton(
          label: 'Get Started',
          onPressed: () => Navigator.pushNamed(context, '/login'),
        ),
      ),
    ],
  );
}
