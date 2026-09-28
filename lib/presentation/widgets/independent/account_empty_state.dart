import 'package:flutter/material.dart';
import '../../../app_setting/app_setting.dart';
import '../widgets.dart';

class AccountEmptyState extends StatelessWidget {
  final PagePalette palette;
  final String title, message, asset;
  final String? actionLabel;
  final VoidCallback? onAction;
  const AccountEmptyState({
    super.key,
    required this.palette,
    required this.title,
    required this.message,
    required this.asset,
    this.actionLabel,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spaceXl,
        vertical: 70,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorBlueDidik.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              asset,
              height: ScreenSize.width * 0.15,
              width: ScreenSize.width * 0.15,
              // color: palette.muted,
            ),
          ),
          const SizedBox(height: AppDesign.spaceXl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDesign.sectionTitleSize,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
          const SizedBox(height: AppDesign.spaceMd),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDesign.bodySize,
              height: 1.9,
              color: palette.muted,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppDesign.spaceXxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.action,
                  foregroundColor: palette.onAction,
                  minimumSize: const Size.fromHeight(
                    AppDesign.setupButtonHeight,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// A real gap between link text and its underline, independent of font metrics.
class AccountUnderlinedLabel extends StatelessWidget {
  final String text;
  final TextStyle style;
  const AccountUnderlinedLabel(this.text, {super.key, required this.style});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: AppDesign.linkUnderlineGap),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: style.color ?? AppDesign.login.action),
      ),
    ),
    child: Text(text, style: style.copyWith(decoration: TextDecoration.none)),
  );
}
