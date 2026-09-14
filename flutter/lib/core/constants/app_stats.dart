/// Display metadata for a supported crop.
///
/// Crops used to carry a tinted [IconData]; they now carry a photograph. That
/// removed four accent colours from the palette — the photo identifies the crop
/// far better than a coloured circle did, and it keeps the chrome neutral.
class SupportedCrop {
  const SupportedCrop({required this.name, required this.image});

  final String name;

  /// Asset path to the crop photograph.
  final String image;
}

/// App-wide capability facts shown in the UI.
abstract final class AppStats {
  static const String diseaseCount = '19';
  static const String cropCount = '4';

  static const List<SupportedCrop> crops = [
    SupportedCrop(name: 'Strawberry', image: 'assets/images/strawberry.jpg'),
    SupportedCrop(name: 'Tomato', image: 'assets/images/tomato.jpg'),
    SupportedCrop(name: 'Potato', image: 'assets/images/potato.jpg'),
    SupportedCrop(name: 'Apple', image: 'assets/images/apple.jpg'),
  ];

  static List<String> get supportedCrops =>
      crops.map((crop) => crop.name).toList(growable: false);

  static SupportedCrop cropByName(String name) {
    return crops.firstWhere(
      (crop) => crop.name.toLowerCase() == name.toLowerCase(),
      orElse: () => crops.first,
    );
  }
}
