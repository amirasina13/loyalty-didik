import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app_setting/app_setting.dart';
import 'account_sheets.dart';

class SuccessTimerDialog extends StatefulWidget {
  final String message;
  final VoidCallback onClosedTap;
  final String title;
  final String buttonLabel;
  final bool autoClose;

  const SuccessTimerDialog({
    super.key,
    required this.message,
    required this.onClosedTap,
    this.title = 'Success',
    this.buttonLabel = 'Done',
    this.autoClose = true,
  });

  @override
  State<SuccessTimerDialog> createState() => _SuccessTimerDialogState();

  static Future<void> showSuccessTimerDialog(
    BuildContext context,
    String message,
    VoidCallback routes, {
    String title = 'Success',
    String buttonLabel = 'Done',
    bool autoClose = true,
  }) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => SuccessTimerDialog(
          message: message,
          onClosedTap: routes,
          title: title,
          buttonLabel: buttonLabel,
          autoClose: autoClose,
        ),
  );
}

class _SuccessTimerDialogState extends State<SuccessTimerDialog> {
  Timer? _timer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoClose) {
      _timer = Timer(const Duration(seconds: 3), _complete);
    }
  }

  void _complete() {
    if (_completed || !mounted) return;
    _completed = true;
    _timer?.cancel();
    widget.onClosedTap();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const palette = AppDesign.recovery;
    return PopScope(
      canPop: false,
      child: Dialog.fullscreen(
        backgroundColor: palette.background,
        child: SafeArea(
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDesign.pagePadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 48).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          mainLogo,
                          width: 180,
                          height: 88,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: AppDesign.spaceXxl),
                        Container(
                          padding: const EdgeInsets.all(AppDesign.pagePadding),
                          decoration: BoxDecoration(
                            color: colorBlueDidik.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: palette.action,
                            size: 56,
                          ),
                        ),
                        const SizedBox(height: AppDesign.spaceXl),
                        sheetTitle(widget.title, palette),
                        const SizedBox(height: AppDesign.spaceMd),
                        Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.muted,
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.bodySize,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppDesign.spaceXxl),
                        AccountPrimaryButton(
                          label: widget.buttonLabel,
                          palette: palette,
                          onPressed: _complete,
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
