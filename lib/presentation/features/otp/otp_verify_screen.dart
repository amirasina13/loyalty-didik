import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timer_count_down/timer_count_down.dart';

import '../../../app_setting/app_setting.dart';
import '../../widgets/widgets.dart';
import 'otp.dart';

class OtpVerifyParameters {
  final Map data;

  const OtpVerifyParameters({required this.data});
}

class OtpVerifyScreen extends StatefulWidget {
  final OtpVerifyParameters parameters;

  const OtpVerifyScreen({super.key, required this.parameters});

  @override
  State<StatefulWidget> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  String otpCode = '', resendvToken = '', tokenVerify = '';
  bool error = false;
  bool enableResend = true;
  bool isProcessing = false, isRegisterEmail = false;
  final pinController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    final data = widget.parameters.data['data'] as Map;
    resendvToken = data['vToken']?.toString() ?? '';
    tokenVerify = data['token']?.toString() ?? '';
    isRegisterEmail = registerMethod == 'email';
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppDesign.registration;
    final recipient =
        widget.parameters.data['data']['send_to']?.toString() ?? '';

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: error ? AppDesign.errorIcon : palette.action,
        ),
      ),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: palette.background,
          body: BlocConsumer<OtpBloc, OtpState>(
            listener: (context, state) {
              fToast = FToast()..init(context);

              if (state is OtpFinished) {
                setProcessingStatus(false);
                RegisterTimerDialog.showSuccessDialog(context);
              }
              if (state is OtpResent) {
                setProcessingStatus(false);
                final data = state.data['data'] as Map;
                resendvToken = data['vToken']?.toString() ?? resendvToken;
                tokenVerify = data['token']?.toString() ?? tokenVerify;
                showSuccessToast(state.data['message'], context);
              }
              if (state is OtpError) {
                error = true;
                setProcessingStatus(false);
                showErrorToast(state.error, context);
              }
            },
            builder: (context, state) {
              return VerificationCodeLayout(
                header:
                    isRegisterEmail
                        ? 'Verify your email'
                        : 'Verify your mobile number',
                heading: 'Enter the OTP code',
                message: 'We sent a six-digit code to $recipient.',
                secondaryLabel: 'Back to login',
                isEmail: isRegisterEmail,
                recipient: recipient,
                palette: palette,
                processing: isProcessing,
                complete: pinController.text.length == 6,
                codeInput: VerificationCodeInput(
                  palette: palette,
                  processing: isProcessing,
                  error: error,
                  controller: pinController,
                  focusNode: focusNode,
                  onChanged:
                      (value) => setState(() {
                        otpCode = value;
                        error = false;
                      }),
                ),
                resendControl: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(top: 20),
                  child:
                      enableResend
                          ? OderButtonText(
                            'Resend OTP',
                            color: palette.action,
                            onClick: isProcessing ? null : _resendOtp,
                          )
                          : Countdown(
                            seconds: 60,
                            build:
                                (_, time) => Text(
                                  '${time.toInt()} seconds left before enabling resend',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: AppDesign.bodySize,
                                    fontFamily: fontFamilyMain,
                                  ),
                                ),
                            onFinished: () {
                              if (mounted) {
                                setState(() => enableResend = true);
                              }
                            },
                          ),
                ),
                onConfirm: _verifyOtp,
                onEdit: _showLogInScreen,
              );
            },
          ),
        ),
      ),
    );
  }

  void setProcessingStatus(bool processing) {
    if (!mounted) return;
    setState(() => isProcessing = processing);
  }

  void _showLogInScreen() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      OderRoutes.login,
      (Route<dynamic> route) => false,
    );
  }

  void _resendOtp() {
    if (!mounted || isProcessing || !enableResend) return;

    setState(() => enableResend = false);
    BlocProvider.of<OtpBloc>(context).add(
      OtpResend(
        method: widget.parameters.data['data']['send_to'],
        sendvia: isRegisterEmail ? 'email' : 'contact',
        purpose: 'resend-register',
        vToken: resendvToken,
      ),
    );
  }

  void _verifyOtp() {
    if (!mounted || isProcessing || pinController.text.length != 6) return;

    setState(() {
      otpCode = pinController.text;
      isProcessing = true;
    });
    BlocProvider.of<OtpBloc>(
      context,
    ).add(OtpVerify(otpCode: otpCode, token: tokenVerify));
  }
}
