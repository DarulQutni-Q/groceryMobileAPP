import 'package:flutter/material.dart';

const authBackground = Color(0xFFEFF4EB);
const gardenInk = Color(0xFF142618);
const gardenBorder = Color(0xFFD9E6CF);
const resetGreen = Color(0xFF75BF26);

// Palet lime dari sampling screenshot referensi Figma.
const limeDeep = Color(0xFF7CC32E);
const limeBright = Color(0xFF8DD635);
const limeLight = Color(0xFFA4D472);
const limePale = Color(0xFFD5EEC0);
const limeMid = Color(0xFF79C549);
const scanYellow = Color(0xFFFFB800);
const textGrey = Color(0xFF657B67);
const textHint = Color(0xFF818781);
const goldText = Color(0xFFF7D96B);
const dangerRed = Color(0xFFB22E32);
const inputBg = Color(0xFFF7F9F5);

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
      // fontFamily eksplisit: tanpa ini, DefaultTextStyle tombol di widget
      // test jatuh ke Ahem (teks jadi kotak-kotak). Di device tidak berubah,
      // karena Roboto memang font default Material.
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: gardenInk,
      minimumSize: const Size(0, 44),
      side: const BorderSide(color: gardenBorder),
      textStyle: const TextStyle(fontFamily: 'Roboto'),
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
