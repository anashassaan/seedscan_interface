// lib/utils/responsive_utils.dart
//
// Centralized responsive helpers — zero functionality change, layout-only.
// Usage example:
//   R.sp(context, 16)   → font size scaled to screen
//   R.w(context, 140)   → width scaled to screen
//   R.isTablet(context) → true when screen ≥ 600 dp

import 'package:flutter/material.dart';

class R {
  R._();

  // ── Break-points (dp) ──────────────────────────────────────────────────
  static const double _tabletBreak = 600;
  static const double _largeBreak  = 900;

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Screen width (logical pixels).
  static double sw(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Screen height (logical pixels).
  static double sh(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// True when running on a tablet / large phone (≥ 600 dp wide).
  static bool isTablet(BuildContext context) => sw(context) >= _tabletBreak;

  /// True when running on a large tablet / desktop (≥ 900 dp wide).
  static bool isLarge(BuildContext context) => sw(context) >= _largeBreak;

  /// Scaled font size. Clamps between [min] and [max] so text never gets
  /// absurdly large on tablets or tiny on small phones.
  ///
  /// On a 360-dp phone the result equals [base].
  static double sp(BuildContext context, double base,
      {double min = 10, double max = 36}) {
    final scale = sw(context) / 360;
    return (base * scale.clamp(0.85, 1.4)).clamp(min, max);
  }

  /// Scaled dimension (padding, icon size, etc.).
  static double dp(BuildContext context, double base) {
    final scale = sw(context) / 360;
    return base * scale.clamp(0.85, 1.4);
  }

  /// Percentage of screen width (0–1).
  static double pct(BuildContext context, double fraction) =>
      sw(context) * fraction;

  /// Adaptive horizontal padding: tighter on phones, wider on tablets.
  static EdgeInsets hPad(BuildContext context,
      {double phone = 16, double tablet = 32}) {
    return EdgeInsets.symmetric(
        horizontal: isTablet(context) ? tablet : phone);
  }

  /// Content max-width constraint — keeps wide-screen layouts from stretching
  /// edge to edge on tablets.
  static double contentMaxWidth(BuildContext context) =>
      isLarge(context) ? 840 : (isTablet(context) ? 640 : double.infinity);

  /// Adaptive grid cross-axis count based on screen width.
  static int gridCount(BuildContext context,
      {int phone = 2, int tablet = 3, int large = 4}) {
    if (isLarge(context)) return large;
    if (isTablet(context)) return tablet;
    return phone;
  }

  /// Constraint box that centres content and limits width on tablets.
  static Widget constrained(BuildContext context, Widget child) {
    final max = contentMaxWidth(context);
    if (max == double.infinity) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }
}

// ── Responsive spacing extension ─────────────────────────────────────────
extension RSpacing on num {
  /// Converts a fixed dp value into a responsive SizedBox (height).
  SizedBox get hGap => SizedBox(height: toDouble());

  /// Converts a fixed dp value into a responsive SizedBox (width).
  SizedBox get wGap => SizedBox(width: toDouble());
}

// ── Safe text widget ──────────────────────────────────────────────────────
/// A Text that always sets [overflow] to [TextOverflow.ellipsis] and
/// [softWrap] to true so it never overflows in a Row.
class SafeText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;

  const SafeText(
    this.data, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
      textAlign: textAlign,
    );
  }
}
