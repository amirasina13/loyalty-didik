import 'package:flutter/material.dart';
import '../../../app_setting/app_setting.dart';

/// Shared HTML verification layout. Requests and validation stay in the views.
class AccountVerificationLayout extends StatelessWidget {
  final Widget? countrySelector;
  final bool isEmail;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext, onLogout;
  final bool processing;

  const AccountVerificationLayout({
    super.key,
    this.countrySelector,
    this.isEmail = false,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onNext,
    required this.onLogout,
    required this.processing,
  }) : assert(isEmail || countrySelector != null);

  @override
  Widget build(BuildContext context) {
    final palette = AppDesign.setup;
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
                'Complete your account',
                textAlign: TextAlign.center,
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
                        color: colorBlueDidik.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEmail ? Icons.alternate_email : Icons.phone_outlined,
                        size: 26,
                        color: palette.action,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceXl),
                    Text(
                      'ACCOUNT VERIFICATION',
                      style: TextStyle(
                        fontSize: AppDesign.captionSize,
                        letterSpacing: 1,
                        color: palette.action,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceLg),
                    Text(
                      isEmail
                          ? 'Verify your email'
                          : 'Verify your mobile number',
                      style: TextStyle(
                        fontSize: AppDesign.setupHeadingSize,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceMd),
                    Text(
                      isEmail
                          ? 'Enter your email address to receive a verification code.'
                          : 'Enter your mobile number to receive a verification code.',
                      style: TextStyle(
                        fontSize: AppDesign.bodySize,
                        height: 1.8,
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceXxl),
                    ListenableBuilder(
                      listenable: focusNode,
                      builder:
                          (context, _) => InputDecorator(
                            key: ValueKey(
                              isEmail ? 'email-field' : 'mobile-number-field',
                            ),
                            isFocused: focusNode.hasFocus,
                            decoration: outlinedAccountField(
                              InputDecoration(
                                labelText: isEmail ? 'Email' : 'Mobile number',
                              ),
                              palette,
                            ),
                            child: Row(
                              children: [
                                if (!isEmail)
                                  SizedBox(
                                    width: 86,
                                    height: 24,
                                    child: countrySelector,
                                  ),
                                if (!isEmail)
                                  const SizedBox(width: AppDesign.spaceMd),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    keyboardType:
                                        isEmail
                                            ? TextInputType.emailAddress
                                            : TextInputType.phone,
                                    onChanged: onChanged,
                                    style: TextStyle(
                                      fontSize: AppDesign.bodySize,
                                      color: palette.text,
                                    ),
                                    decoration: const InputDecoration(
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
                    ),
                    const SizedBox(height: AppDesign.spaceXxl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.action,
                          foregroundColor: palette.onAction,
                          elevation: 0,
                          disabledBackgroundColor: AppDesign.setupDisabled,
                          disabledForegroundColor: palette.onAction,
                          minimumSize: const Size.fromHeight(
                            AppDesign.setupButtonHeight,
                          ),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.bodySize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: processing ? null : onNext,
                        child: Text(processing ? 'Processing…' : 'Next'),
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceLg),
                    Center(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: palette.action,
                          padding: const EdgeInsets.all(AppDesign.spaceLg),
                          textStyle: const TextStyle(
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.bodySize,
                          ),
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
