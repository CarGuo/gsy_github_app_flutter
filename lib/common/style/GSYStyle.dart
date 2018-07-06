import 'package:flutter/material.dart';

class GSYColors {
  static const String welcomeMessage = "Welcome To Flutter";

  static const int _PrimaryValue = 0xFF24292E;
  static const int _PrimaryLightValue = 0xFF42464b;
  static const int _PrimaryDarkValue = 0xFF121917;

  static const MaterialColor primarySwatch = const MaterialColor(
    _PrimaryValue,
    const <int, Color>{
      50: const Color(_PrimaryLightValue),
      100: const Color(_PrimaryLightValue),
      200: const Color(_PrimaryLightValue),
      300: const Color(_PrimaryLightValue),
      400: const Color(_PrimaryLightValue),
      500: const Color(_PrimaryValue),
      600: const Color(_PrimaryDarkValue),
      700: const Color(_PrimaryDarkValue),
      800: const Color(_PrimaryDarkValue),
      900: const Color(_PrimaryDarkValue),
    },
  );
}

class GSYConstant {}
