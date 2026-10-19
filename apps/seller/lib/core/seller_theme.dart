import 'package:flutter/material.dart';

const sellerBackground = Color(0xFFFDFFF4);
const sellerPrimary = Color(0xFF83AC9E);
const sellerInk = Color(0xFF192D1E);
const sellerInput = Color(0xFFECE5D0);

ThemeData sellerTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: sellerBackground,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20))
      .copyWith(
        primary: sellerPrimary,
        onPrimary: Colors.white,
        surface: sellerBackground,
        onSurface: sellerInk,
      ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: sellerInput,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDCCCAC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDCCCAC)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
  ),
);
