import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../../../app_setting/app_setting.dart';

class VerificationCodeLayout extends StatelessWidget {
  final bool isEmail, processing, complete;
  final String recipient;
  final String? header, secondaryLabel, heading, message;
  final String primaryLabel;
  final IconData icon;
  final PagePalette palette;
  final Widget codeInput, resendControl;
  final VoidCallback onConfirm, onEdit;
  const VerificationCodeLayout({
    super.key,
    required this.isEmail,
    required this.processing,
    required this.complete,
    required this.recipient,
    required this.codeInput,
    required this.resendControl,
    required this.onConfirm,
    required this.onEdit,
    this.header,
    this.heading,
    this.message,
    this.primaryLabel = 'Confirm',
    this.icon = Icons.check,
    this.secondaryLabel,
    this.palette = AppDesign.setup,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.pagePadding,
                vertical: AppDesign.spaceXl,
              ),
              child: Text(
                header ?? (isEmail ? 'Verify email' : 'Verify mobile'),
                style: TextStyle(
                  fontSize: AppDesign.sectionTitleSize,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
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
                      child: Icon(icon, color: palette.action, size: 26),
                    ),
                    const SizedBox(height: AppDesign.spaceLg),
                    Text(
                      heading ?? 'Enter verification code',
                      style: TextStyle(
                        fontSize: AppDesign.setupHeadingSize,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceMd),
                    Text(
                      message ??
                          'Enter the six-digit code sent to ${recipient.isEmpty ? (isEmail ? 'your email address' : 'your mobile number') : recipient}.',
                      style: TextStyle(
                        fontSize: AppDesign.bodySize,
                        height: 1.8,
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceXxl),
                    codeInput,
                    const SizedBox(height: AppDesign.spaceXxl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.action,
                          foregroundColor: palette.onAction,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          disabledBackgroundColor: AppDesign.setupDisabled,
                          disabledForegroundColor: palette.onAction,
                          minimumSize: const Size.fromHeight(
                            AppDesign.setupButtonHeight,
                          ),
                          textStyle: const TextStyle(
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.bodySize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: processing || !complete ? null : onConfirm,
                        child: Text(processing ? 'Processing…' : primaryLabel),
                      ),
                    ),
                    resendControl,
                    Center(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: palette.action,
                          textStyle: const TextStyle(
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.bodySize,
                          ),
                        ),
                        onPressed: processing ? null : onEdit,
                        child: Text(
                          secondaryLabel ??
                              (isEmail ? 'Edit email' : 'Edit mobile number'),
                        ),
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

/// One six-digit field style for email, mobile and passcode verification.
class VerificationCodeInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool processing, error, obscure;
  final PagePalette palette;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  const VerificationCodeInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.obscure = false,
    required this.processing,
    required this.error,
    required this.onChanged,
    this.onCompleted,
    this.palette = AppDesign.setup,
  });
  @override
  Widget build(BuildContext context) => Pinput(
    enabled: !processing,
    obscureText: obscure,
    length: 6,
    controller: controller,
    autofocus: true,
    focusNode: focusNode,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    defaultPinTheme: PinTheme(
      width: 40,
      height: 48,
      textStyle: TextStyle(
        fontSize: AppDesign.titleSize,
        fontWeight: FontWeight.w600,
        color: palette.text,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: error ? AppDesign.errorIcon : palette.border),
      ),
    ),
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    hapticFeedbackType: HapticFeedbackType.lightImpact,
    onChanged: onChanged,
    onCompleted: onCompleted,
  );
}
