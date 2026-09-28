import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../../../app_setting/app_setting.dart';
import 'account_sheets.dart';

class PasscodeLayout extends StatelessWidget {
  final String title, message;
  final int? step;
  final Widget child;
  final VoidCallback? onBack;
  const PasscodeLayout({
    super.key,
    required this.title,
    required this.message,
    required this.child,
    this.step,
    this.onBack,
  });
  @override
  Widget build(BuildContext context) {
    const p = AppDesign.passcode;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Passcode',
          style: TextStyle(
            fontSize: AppDesign.appBarTitleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesign.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (step != null) ...[
                Center(
                  child: SizedBox(
                    width: 130,
                    child: Row(
                      children: List.generate(
                        3,
                        (i) => Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i <= step! ? p.action : p.border,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDesign.spaceXxl),
              ] else ...[
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: colorBlueDidik.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_outline, color: p.action, size: 34),
                  ),
                ),
                const SizedBox(height: AppDesign.spaceXl),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppDesign.headingSize,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const SizedBox(height: AppDesign.spaceLg),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppDesign.bodySize,
                  height: 1.9,
                  color: p.muted,
                ),
              ),
              const SizedBox(height: AppDesign.spaceXxl),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class PasscodeDigits extends StatefulWidget {
  final String value;
  final bool enabled, obscure;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final TextEditingController? controller;
  const PasscodeDigits({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.obscure = true,
    this.onCompleted,
    this.controller,
  });
  @override
  State<PasscodeDigits> createState() => _PasscodeDigitsState();
}

class _PasscodeDigitsState extends State<PasscodeDigits> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant PasscodeDigits oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const p = AppDesign.passcode;
    return Pinput(
      controller: _controller,
      length: 6,
      enabled: widget.enabled,
      obscureText: widget.obscure,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      separatorBuilder: (_) => const SizedBox(width: AppDesign.spaceSm),
      defaultPinTheme: PinTheme(
        width: 40,
        height: 48,
        textStyle: TextStyle(
          fontSize: AppDesign.titleSize,
          fontWeight: FontWeight.w600,
          color: p.text,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      focusedPinTheme: PinTheme(
        width: 40,
        height: 48,
        textStyle: TextStyle(
          fontSize: AppDesign.titleSize,
          fontWeight: FontWeight.w600,
          color: p.text,
        ),
        decoration: BoxDecoration(
          color: colorBlueDidik.withValues(alpha: 0.1),
          border: Border.all(color: p.action),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      hapticFeedbackType: HapticFeedbackType.lightImpact,
      onChanged: (value) {
        if (value != widget.value) widget.onChanged(value);
      },
      onCompleted: widget.onCompleted,
    );
  }
}

class PasscodeIntro extends StatelessWidget {
  final bool creating, busy;
  final VoidCallback onContinue, onCancel;
  const PasscodeIntro({
    super.key,
    required this.creating,
    required this.busy,
    required this.onContinue,
    required this.onCancel,
  });
  @override
  Widget build(BuildContext context) {
    const p = AppDesign.passcode;
    return PasscodeLayout(
      title: creating ? 'Set up your passcode' : 'Change your passcode',
      message: 'Your six-digit passcode helps protect your transactions.',
      onBack: onCancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesign.spaceLg),
            decoration: BoxDecoration(
              color: colorBlueDidik.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              creating
                  ? 'Verify your account, create a six-digit passcode, then enter it again to confirm.'
                  : 'Verify your account with a one-time code, then set and confirm your new passcode.',
              style: TextStyle(
                fontSize: AppDesign.smallSize,
                height: 1.8,
                color: p.muted,
              ),
            ),
          ),
          const SizedBox(height: AppDesign.spaceXxl),
          AccountPrimaryButton(
            palette: p,
            label:
                busy
                    ? 'Please wait…'
                    : creating
                    ? 'Set Passcode'
                    : 'Continue',
            onPressed: busy ? null : onContinue,
          ),
          const SizedBox(height: AppDesign.spaceMd),
          TextButton(
            onPressed: busy ? null : onCancel,
            style: TextButton.styleFrom(foregroundColor: p.action),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
