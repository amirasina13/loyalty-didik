import 'package:flutter/material.dart';

import '../../../app_setting/app_setting.dart';
import '../independent/success_timer_dialog.dart';

/// Compatibility entry point for the registration OTP success state.
///
/// The success screen uses the same themed layout as password reset and
/// passcode success states while preserving the existing three-second return
/// to the login route.
class RegisterTimerDialog {
  const RegisterTimerDialog._();

  static Future<void> showSuccessDialog(BuildContext context) {
    return SuccessTimerDialog.showSuccessTimerDialog(
      context,
      'Your account has been successfully registered.',
      () {
        Navigator.of(context).pushNamedAndRemoveUntil(
          OderRoutes.login,
          (Route<dynamic> route) => false,
        );
      },
      title: 'Account created',
      buttonLabel: 'Back to login',
      autoClose: true,
    );
  }
}
