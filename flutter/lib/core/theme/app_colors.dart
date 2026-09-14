import 'package:flutter/material.dart';

/// Light botanical palette, deliberately small.
///
/// The rule is **one accent**: [primary] means "you can act on this" and
/// nothing else. Status colours ([success], [error], [warning]) appear only
/// where the status *is* the message. Everything else is ivory, white and three
/// greys. Crop identity is carried by photographs, not colour — which is what
/// let four crop accents, a gradient and a glow be deleted outright.
///
/// Values are contrast-measured, not eyeballed: every foreground/background
/// pair in use clears WCAG AA. See `docs/UI_REWORK_PLAN.md`.
class AppColors {
  AppColors._();

  // --- Surfaces ---------------------------------------------------------
  static const Color background = Color(0xFFF5F7EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  /// Inset fills: progress tracks, skeletons, neutral icon wells.
  static const Color cardElevated = Color(0xFFEEF2E7);

  /// Soft botanical wash. Reserved for genuinely positive states — used as
  /// generic decoration it stops reading as meaningful.
  static const Color softGreen = Color(0xFFDCE8D5);

  /// Hairline border. (Named `glassBorder` from the frosted-surface era; the
  /// surfaces are flat now but ~20 call sites still use this name.)
  static const Color glassBorder = Color(0xFFC9D4C2);

  // --- Brand ------------------------------------------------------------
  /// The single accent. The reference sage (#8EAD82) is 2.2:1 against white and
  /// could not carry the white button label it was meant for; this reaches
  /// 4.9:1 and still reads unmistakably sage.
  static const Color primary = Color(0xFF5C7852);
  static const Color primaryDark = Color(0xFF4B6642);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // --- Text -------------------------------------------------------------
  static const Color foreground = Color(0xFF243126);
  static const Color foregroundSecondary = Color(0xFF4A554B);
  static const Color muted = Color(0xFF5F685F);
  static const Color mutedForeground = Color(0xFF737C73);

  // --- Lines ------------------------------------------------------------
  static const Color border = Color(0xFFC9D4C2);
  static const Color divider = Color(0xFFD8E0D3);

  // --- Status -----------------------------------------------------------
  // Only where the status is the point: health badges, risk, errors.
  static const Color success = Color(0xFF40734A);
  static const Color error = Color(0xFFB04A35);
  static const Color warning = Color(0xFF946627);

  /// Agronomic severity. Distinct from model confidence, which is never
  /// coloured by value — see `ConfidenceIndicator`.
  static const Color riskLow = success;
  static const Color riskMedium = warning;
  static const Color riskHigh = error;
}
