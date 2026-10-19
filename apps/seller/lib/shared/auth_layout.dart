import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/seller_theme.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.title, this.onBack});
  final Widget child;
  final String? title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        const Positioned(
          top: -220,
          right: -160,
          width: 700,
          height: 380,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFE3E6D1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Positioned(
          bottom: -310,
          left: -200,
          width: 850,
          height: 520,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFF3F6E3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null)
                      Row(
                        children: [
                          if (onBack != null)
                            IconButton(
                              onPressed: onBack,
                              tooltip: 'Kembali',
                              icon: const Icon(Icons.arrow_back),
                            ),
                          Expanded(
                            child: Text(
                              title!,
                              style: const TextStyle(
                                fontSize: 26,
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class ReferenceArtwork extends StatelessWidget {
  const ReferenceArtwork({
    super.key,
    required this.asset,
    required this.rect,
    this.width = 270,
    this.semanticLabel,
  });
  final String asset;
  final Rect rect;
  final double width;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final actualWidth = math.min(width, constraints.maxWidth);
        final scale = actualWidth / rect.width;
        return Semantics(
          label: semanticLabel,
          image: true,
          child: SizedBox(
            width: actualWidth,
            height: rect.height * scale,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: -rect.left * scale,
                    top: -rect.top * scale,
                    width: 478 * scale,
                    height: 940 * scale,
                    child: Image.asset(
                      'assets/references/$asset',
                      fit: BoxFit.fill,
                      excludeFromSemantics: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

void showAuthMessage(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? const Color(0xFFB3261E) : sellerInk,
    ),
  );
}
