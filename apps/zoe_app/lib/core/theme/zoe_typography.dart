/// Sistema tipográfico luxury do Zoe.
///
/// Referência direta: ARCHITECTURE.md §Typography System
import 'package:flutter/material.dart';
import 'zoe_colors.dart';

abstract class ZoeTypography {
  static const String displayFamily = 'PlayfairDisplay';
  static const String bodyFamily = 'Inter';
  static const String accentFamily = 'Montserrat';

  // DISPLAY
  static TextStyle displayLarge = const TextStyle(
    fontFamily: displayFamily, fontSize: 48, fontWeight: FontWeight.w700,
    letterSpacing: -0.5, height: 1.1, color: ZoeColors.secondary,
  );
  static TextStyle displayMedium = const TextStyle(
    fontFamily: displayFamily, fontSize: 36, fontWeight: FontWeight.w600,
    letterSpacing: -0.25, height: 1.2, color: ZoeColors.secondary,
  );
  static TextStyle displaySmall = const TextStyle(
    fontFamily: displayFamily, fontSize: 28, fontWeight: FontWeight.w600,
    height: 1.25, color: ZoeColors.secondary,
  );

  // HEADLINE
  static TextStyle headlineLarge = const TextStyle(
    fontFamily: bodyFamily, fontSize: 24, fontWeight: FontWeight.w600,
    height: 1.3, color: ZoeColors.secondary,
  );
  static TextStyle headlineMedium = const TextStyle(
    fontFamily: bodyFamily, fontSize: 20, fontWeight: FontWeight.w600,
    letterSpacing: 0.15, height: 1.35, color: ZoeColors.secondary,
  );
  static TextStyle headlineSmall = const TextStyle(
    fontFamily: bodyFamily, fontSize: 18, fontWeight: FontWeight.w600,
    letterSpacing: 0.15, height: 1.4, color: ZoeColors.secondary,
  );

  // BODY
  static TextStyle bodyLarge = const TextStyle(
    fontFamily: bodyFamily, fontSize: 16, fontWeight: FontWeight.w400,
    letterSpacing: 0.15, height: 1.5, color: ZoeColors.charcoal,
  );
  static TextStyle bodyMedium = const TextStyle(
    fontFamily: bodyFamily, fontSize: 14, fontWeight: FontWeight.w400,
    letterSpacing: 0.25, height: 1.5, color: ZoeColors.charcoal,
  );
  static TextStyle bodySmall = const TextStyle(
    fontFamily: bodyFamily, fontSize: 12, fontWeight: FontWeight.w400,
    letterSpacing: 0.4, height: 1.4, color: ZoeColors.darkGray,
  );

  // LABEL
  static TextStyle labelLarge = const TextStyle(
    fontFamily: accentFamily, fontSize: 14, fontWeight: FontWeight.w600,
    letterSpacing: 1.25, height: 1.4, color: ZoeColors.secondary,
  );
  static TextStyle labelMedium = const TextStyle(
    fontFamily: accentFamily, fontSize: 12, fontWeight: FontWeight.w500,
    letterSpacing: 1.5, height: 1.3, color: ZoeColors.secondary,
  );
  static TextStyle labelSmall = const TextStyle(
    fontFamily: accentFamily, fontSize: 10, fontWeight: FontWeight.w500,
    letterSpacing: 1.5, height: 1.2, color: ZoeColors.darkGray,
  );

  // PRICE
  static TextStyle priceLarge = const TextStyle(
    fontFamily: bodyFamily, fontSize: 24, fontWeight: FontWeight.w700,
    letterSpacing: -0.5, height: 1.2, color: ZoeColors.secondary,
  );
  static TextStyle priceMedium = const TextStyle(
    fontFamily: bodyFamily, fontSize: 18, fontWeight: FontWeight.w600,
    height: 1.3, color: ZoeColors.secondary,
  );
  static TextStyle priceStrikethrough = const TextStyle(
    fontFamily: bodyFamily, fontSize: 14, fontWeight: FontWeight.w400,
    height: 1.3, color: ZoeColors.mediumGray,
    decoration: TextDecoration.lineThrough,
  );
}
