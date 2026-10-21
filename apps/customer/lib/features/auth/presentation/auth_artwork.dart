import 'package:flutter/material.dart';

import '../../../core/theme.dart';

Widget artwork(String name, {double? width, double? height}) => Image.asset(
  'assets/references/$name.png',
  width: width,
  height: height,
  fit: BoxFit.contain,
  excludeFromSemantics: true,
);

class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child, this.reset = false});
  final Widget child;
  final bool reset;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: reset ? Colors.white : authBackground,
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (reset) ...[
              Positioned(
                left: 0,
                bottom: 0,
                child: artwork('forgot_decor_left_bottom', width: 150),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: artwork('forgot_decor_right_bottom', width: 141),
              ),
              Positioned(
                right: 0,
                top: 241,
                child: artwork('forgot_decor_right_middle', width: 93),
              ),
            ] else ...[
              Positioned(
                left: 4,
                top: 27,
                child: artwork('auth_decor_top', width: 110),
              ),
              Positioned(
                left: 0,
                top: 163,
                child: artwork('auth_decor_left_top', width: 119),
              ),
              Positioned(
                left: -20,
                bottom: 145,
                child: Transform.flip(
                  flipX: true,
                  child: artwork('auth_decor_right_bottom', width: 110),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: artwork('auth_decor_right_bottom', width: 164),
              ),
            ],
            SafeArea(child: child),
          ],
        ),
      ),
    ),
  );
}

class GardenLogo extends StatelessWidget {
  const GardenLogo({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      artwork('garden_symbol_auth', width: 42, height: 36),
      const SizedBox(height: 5),
      const Text(
        'GardenMart',
        style: TextStyle(
          fontSize: 24,
          height: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Text(
        'Belanja Segar & Lengkap Tanpa Ribet',
        style: TextStyle(fontSize: 12, color: Color(0xFF657B67)),
      ),
    ],
  );
}
