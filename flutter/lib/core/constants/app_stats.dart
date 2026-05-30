import 'package:flutter/material.dart';

/// Display metadata for a supported crop.
class SupportedCrop {
  const SupportedCrop({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final IconData icon;
  final Color color;
}

/// App-wide marketing / capability stats shown in the UI.
abstract final class AppStats {
  static const String accuracy = '96%';
  static const String accuracyDisplay = '96%+';
  static const String diseaseCount = '19';
  static const String cropCount = '4';

  static const List<SupportedCrop> crops = [
    SupportedCrop(
      name: 'Strawberry',
      icon: Icons.blur_on,
      color: Color(0xFFF43F5E),
    ),
    SupportedCrop(
      name: 'Tomato',
      icon: Icons.circle,
      color: Color(0xFFEF4444),
    ),
    SupportedCrop(
      name: 'Potato',
      icon: Icons.egg_alt_outlined,
      color: Color(0xFFD97706),
    ),
    SupportedCrop(
      name: 'Apple',
      icon: Icons.eco_rounded,
      color: Color(0xFF22C55E),
    ),
  ];

  static List<String> get supportedCrops =>
      crops.map((crop) => crop.name).toList(growable: false);

  static SupportedCrop cropByName(String name) {
    return crops.firstWhere(
      (crop) => crop.name == name,
      orElse: () => crops.first,
    );
  }
}
