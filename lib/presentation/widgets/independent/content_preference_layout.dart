import 'package:flutter/material.dart';
import '../../../app_setting/app_setting.dart';
import 'account_sheets.dart';

class ContentPreferenceLayout extends StatelessWidget {
  const ContentPreferenceLayout({
    super.key,
    required this.selected,
    required this.processing,
    required this.onChanged,
    required this.onConfirm,
    required this.onLogout,
  });
  final bool selected, processing;
  final ValueChanged<bool> onChanged;
  final VoidCallback onConfirm, onLogout;

  @override
  Widget build(BuildContext context) {
    const p = AppDesign.setup;
    return ColoredBox(
      color: p.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDesign.spaceXl),
              child: Text(
                'Complete your account',
                style: TextStyle(
                  fontFamily: fontFamilyMain,
                  fontSize: AppDesign.sectionTitleSize,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppDesign.pagePadding,
                  AppDesign.spaceMd,
                  AppDesign.pagePadding,
                  AppDesign.spaceXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: AppDesign.setupBadgeSize,
                      height: AppDesign.setupBadgeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorBlueDidik.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: p.action,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceXl),
                    Text(
                      'CONTENT PREFERENCE',
                      style: TextStyle(
                        fontSize: AppDesign.captionSize,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: p.muted,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceMd),
                    Text(
                      'Choose what you see',
                      style: TextStyle(
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.setupHeadingSize,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceMd),
                    Text(
                      'Select the content you would like to see in the app.',
                      style: TextStyle(
                        fontSize: AppDesign.bodySize,
                        height: 1.8,
                        color: p.muted,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceXl),
                    for (final option in [
                      (true, 'Muslim-Friendly Content Only'),
                      (false, 'Include Non-Halal Content'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDesign.spaceMd,
                        ),
                        child: Semantics(
                          selected: selected == option.$1,
                          inMutuallyExclusiveGroup: true,
                          button: true,
                          child: Material(
                            color: p.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDesign.cardRadius,
                              ),
                              side: BorderSide(
                                color:
                                    selected == option.$1 ? p.action : p.border,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppDesign.cardRadius,
                              ),
                              onTap:
                                  processing
                                      ? null
                                      : () => onChanged(option.$1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDesign.spaceLg,
                                  vertical: 20,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option.$2,
                                        style: TextStyle(
                                          fontSize: AppDesign.bodySize,
                                          height: 1.5,
                                          color: p.text,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppDesign.spaceLg),
                                    Icon(
                                      selected == option.$1
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color:
                                          selected == option.$1
                                              ? p.action
                                              : p.border,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppDesign.spaceLg),
                    AccountPrimaryButton(
                      label: processing ? 'Processing…' : 'Confirm',
                      palette: p,
                      onPressed: processing ? null : onConfirm,
                    ),
                    const SizedBox(height: AppDesign.spaceLg),
                    Center(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: p.action,
                          padding: const EdgeInsets.all(AppDesign.spaceLg),
                        ),
                        onPressed: onLogout,
                        child: const Text('Log Out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
