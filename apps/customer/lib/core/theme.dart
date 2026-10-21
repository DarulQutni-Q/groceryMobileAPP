import 'package:flutter/material.dart';

const authBackground = Color(0xFFEFF4EB);
const gardenInk = Color(0xFF142618);
const gardenBorder = Color(0xFFD9E6CF);
const resetGreen = Color(0xFF75BF26);

ThemeData customerTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: gardenInk,
  ).copyWith(primary: gardenInk, surface: Colors.white, onSurface: gardenInk),
  scaffoldBackgroundColor: authBackground,
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      backgroundColor: gardenInk,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: gardenInk,
      minimumSize: const Size(0, 44),
      side: const BorderSide(color: gardenBorder),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF7F9F5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF818781)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: gardenBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: gardenBorder),
    ),
  ),
);
