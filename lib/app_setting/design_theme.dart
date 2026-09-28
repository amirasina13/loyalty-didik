import 'app_material.dart'
    show
        colorBlueDidik,
        colorDeepSkyBlue,
        colorGoldButton,
        // colorGreyBlue,
        // colorLightBlue,
        colorRed,
        colorRedLight,
        colorWhite,
        // colorWhiteLight,
        mainColor,
        secondaryColor;
import 'package:flutter/material.dart';

/// Shared defaults for the reviewed account screens. Page palettes below can be
/// changed independently without changing other pages or business configuration.
class PagePalette {
  final Color background,
      surface,
      text,
      muted,
      border,
      action,
      onAction,
      tabIndicator,
      favButton;
  const PagePalette({
    this.background = const Color(0xFFFFFFFF),
    this.surface = const Color(0xFFF7F1F4),
    this.text = const Color(0xFF29212A),
    this.muted = const Color(0xFF897B86),
    this.border = const Color(0xFFDCD6DC),
    this.action = mainColor,
    this.onAction = const Color(0xFFFFFFFF),
    this.tabIndicator = secondaryColor,
    this.favButton = colorRedLight,
  });
}

class AppDesign {
  // App-wide type scale. Keep compact metadata separate from readable body text.
  static const captionSize = 11.0;
  static const smallSize = 12.0;
  static const bodySize = 14.0;
  static const bodyLargeSize = 16.0;
  static const sectionTitleSize = 18.0;
  static const titleSize = 22.0;
  static const headingSize = 24.0;
  static const heroSize = 32.0;
  static const appBarTitleSize = 18.0;
  static const buttonTextSize = 14.0;
  static const buttonHeight = 54.0;
  static const buttonRadius = 28.0;
  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 12.0;
  static const spaceLg = 16.0;
  static const spaceXl = 24.0;
  static const spaceXxl = 32.0;
  static const contentPadding = 16.0;
  static const fieldPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 20,
  );
  static const profile = PagePalette();
  static const editProfile = PagePalette();
  static const deleteAccount = PagePalette();
  static const deleteDanger = Color(0xFFB83251);
  static const deleteWarningBackground = Color(0xFFFFF2F3);
  static const topUp = PagePalette();
  static const deals = PagePalette();
  static const voucherDetails = PagePalette();
  static const voucherPurchase = PagePalette();
  static const scanner = PagePalette(
    surface: Color(0xFFFFF8E3),
    text: mainColor,
    muted: Color(0xFF6D6D6D),
    border: Color(0xFFE1DCD3),
    action: colorGoldButton,
    onAction: mainColor,
  );
  static const history = PagePalette();
  static const historyIncoming = Color(0xFF148351);
  static const historyOutgoing = Color(0xFFB83251);
  static const favourites = PagePalette();
  static const favouritesRemove = Color(0xFFB83251);
  static const passcode = PagePalette();
  static const referral = PagePalette();
  static const login = PagePalette();
  static const registration = PagePalette();
  static const recovery = PagePalette();
  static const setup = PagePalette();
  static const calendar = PagePalette();
  static const photo = PagePalette();
  static const directory = PagePalette();
  static const merchantDetails = PagePalette();
  static const outletDetails = PagePalette();
  static const sheetRadius = 28.0;
  static const setupBadgeSize = 64.0;
  static const setupHeadingSize = headingSize;
  static const setupButtonHeight = buttonHeight;
  static const setupDisabled = Color(0xFFD7D3D7);
  static const profileHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mainColor, colorDeepSkyBlue],
  );
  static const profileHeaderText = Colors.white;
  static const profileHeaderSecondary = colorWhite; //Color(0xFFEFCFDE);
  static const directoryHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF351522), Color(0xFF68143B), Color(0xFF9B2058)],
  );
  static const directoryHeaderDidik = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mainColor, colorDeepSkyBlue],
  );
  static const formFieldGap = 24.0;
  static const fieldRadius = 11.0;
  static const cardRadius = 16.0;
  static const pagePadding = 24.0;
  static const errorBackground = Color(0xFFFFF2F3);
  static const errorText = Color(0xFF87233B);
  static const errorBorder = Color(0xFFEDC4CC);
  static const errorIcon = Color(0xFFB83251);
  static const toastDuration = Duration(seconds: 6);
  static const toastTopGap = 12.0;
  static const linkUnderlineGap = 4.0;
  static const toastSuccessBackground = Color(0xFFEAF7F0);
  static const toastSuccessText = Color(0xFF176B43);
  static const toastSuccessBorder = Color(0xFFB8DEC9);
  static const toastRadius = 14.0;
}

/// Applies the reviewed outline without changing field callbacks or validation.
InputDecoration outlinedAccountField(
  InputDecoration original,
  PagePalette? palette,
) {
  if (palette == null) return original;
  OutlineInputBorder outline(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppDesign.fieldRadius),
    borderSide: BorderSide(color: color),
  );
  return original.copyWith(
    isCollapsed: false,
    fillColor:
        original.filled == true
            ? colorBlueDidik.withValues(alpha: 0.1)
            : palette.background,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    contentPadding: AppDesign.fieldPadding,
    border: outline(palette.border),
    enabledBorder: outline(palette.border),
    focusedBorder: outline(
      original.focusedBorder?.borderSide.color == colorRed
          ? AppDesign.errorIcon
          : palette.action,
    ),
    errorBorder: outline(AppDesign.errorIcon),
    focusedErrorBorder: outline(AppDesign.errorIcon),
    labelStyle: TextStyle(
      color: palette.muted,
      fontSize: AppDesign.bodySize,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: TextStyle(color: palette.muted, fontSize: AppDesign.bodySize),
  );
}
