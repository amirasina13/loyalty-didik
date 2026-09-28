import 'package:flutter/material.dart';

import '../../../app_setting/app_setting.dart';

/// Shared phone field used by account entry and verification screens. The
/// country code and mobile number live inside one floating-label outline.
class AccountPhoneRow extends StatelessWidget {
  final Widget countrySelector;
  final TextEditingController controller;
  final FocusNode focusNode;
  final PagePalette palette;
  final ValueChanged<String> onChanged;
  final String labelText;
  final String hintText;

  const AccountPhoneRow({
    super.key,
    required this.countrySelector,
    required this.controller,
    required this.focusNode,
    required this.palette,
    required this.onChanged,
    this.labelText = 'Mobile number',
    this.hintText = '',
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: focusNode,
    builder:
        (context, _) => InputDecorator(
          key: const ValueKey('mobile-number-field'),
          isFocused: focusNode.hasFocus,
          decoration: outlinedAccountField(
            InputDecoration(labelText: labelText),
            palette,
          ),
          child: Row(
            children: [
              SizedBox(width: 86, height: 24, child: countrySelector),
              const SizedBox(width: AppDesign.spaceMd),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.phone,
                  onChanged: onChanged,
                  style: TextStyle(
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.bodySize,
                    color: palette.text,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText.isEmpty ? null : hintText,
                    hintStyle: TextStyle(
                      fontFamily: fontFamilyMain,
                      fontSize: AppDesign.bodySize,
                      color: palette.muted,
                    ),
                    isDense: true,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
  );
}
