import 'package:flutter/material.dart';

/// Shadow discipline: almost none.
///
/// Depth comes from the 1px hairline border and the white-on-ivory surface
/// contrast, not from elevation. Both levels sit at or below 4% opacity — at
/// the previous 6-8% the cards read as floating rather than as paper.
abstract final class AppShadows {
  /// Cards. Barely perceptible; the border does the separating.
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x08243126), blurRadius: 6, offset: Offset(0, 1)),
  ];

  /// Only for surfaces that genuinely float over content: the bottom nav bar
  /// and the capture button.
  static const List<BoxShadow> lifted = [
    BoxShadow(color: Color(0x0D243126), blurRadius: 16, offset: Offset(0, 4)),
  ];
}
