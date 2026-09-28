import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timer_count_down/timer_count_down.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../widgets/widgets.dart';
import '../../maintenance/maintenance_screen.dart';
import '../security_pin.dart';

class SecurityOtpView extends StatefulWidget {
  final Function changeView;
  final Map otpData;

  const SecurityOtpView({
    super.key,
    required this.changeView,
    required this.otpData,
  });

  @override
  State<SecurityOtpView> createState() => _SecurityOtpViewState();
}

class _SecurityOtpViewState extends State<SecurityOtpView> {
  bool error = false;
  bool isProcessing = false;
  int secondsRemaining = 60;
  bool enableResend = true;
  String errorfield = '';
  String reqEmail = '', resendvToken = '', tokenVerify = '';

  /// Create Controller
  // final otpController = TextEditingController();
  // OtpFieldController otpController = OtpFieldController();
  final pinController = TextEditingController();
  final focusNode = FocusNode();

  String? otpCode = '';
  late double sizeBetween;

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();

    fToast = FToast();
    fToast.init(context);
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    sizeBetween = ScreenSize.height / 20;

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: error == false ? AppDesign.passcode.text : colorRed,
        ),
      ),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppDesign.passcode.background,
          body: BlocConsumer<SecurityBloc, SecurityState>(
            listener: (context, state) {
              // on success delete navigator stack and push to home
              if (state is SecurityOtpVerified) {
                setProcessingStatus(false);

                showSuccessToast(state.data['message'], context);
                Navigator.of(context).pushNamed(OderRoutes.securitySet);
              }
              if (state is SecurityOtpSent) {
                setProcessingStatus(false);
                showSuccessToast(state.data['message'], context);

                resendvToken = state.data['data']['vToken'];
                tokenVerify = state.data['data']['otp_token'];
              }
              // on failure show a snackbar
              if (state is SecurityNetworkError) {
                setProcessingStatus(false);
                showErrorToast(state.error, context);
              }
              if (state is SecurityError) {
                // ignore: unnecessary_null_comparison
                state.error != null ? error = true : error = false;
                setProcessingStatus(false);
                // pinController.clear();
                showErrorToast(state.error, context);
                // ErrorIconDialog.showErrorDialog(context, state.error);
              }
              /* --------------------------------------------------------------- Listen to maintenance error, navigate to maintenance page */
              if (state is SecurityMaintenanceError) {
                Navigator.pushAndRemoveUntil<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder:
                        (BuildContext context) => MaintenanceScreen(
                          parameters: MaintenanceParameters(
                            message: state.message,
                          ),
                        ),
                  ),
                  ModalRoute.withName('/'),
                );
              }
            },
            builder: (context, state) {
              // show loading screen while processing
              if (state is SecurityProcessing) {
                // return Center(
                //   child: CircularProgressIndicator(color: colorDisableGrey,),
                // );
              }

              if (state is SecurityInitial) {
                reqEmail = widget.otpData['data']['send_to'];
                resendvToken = widget.otpData['data']['vToken'];
                tokenVerify = widget.otpData['data']['otp_token'];
              }

              return VerificationCodeLayout(
                header: 'Verify account',
                secondaryLabel: 'Cancel',
                isEmail: reqEmail.contains('@'),
                recipient: reqEmail,
                palette: AppDesign.passcode,
                processing: isProcessing,
                complete: pinController.text.length == 6,
                codeInput: VerificationCodeInput(
                  palette: AppDesign.passcode,
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
                      !enableResend
                          ? Countdown(
                            seconds: 60,
                            build:
                                (_, time) => Text(
                                  '${time.toInt()} seconds left before enabling resend',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppDesign.passcode.action,
                                    fontSize: AppDesign.bodySize,
                                    fontFamily: fontFamilyMain,
                                  ),
                                ),
                          )
                          : OderButtonText(
                            'Send again',
                            color: AppDesign.passcode.action,
                            onClick: isProcessing ? null : _resendOtp,
                          ),
                ),
                onConfirm: _validateAndSend,
                onEdit: () => Navigator.of(context).maybePop(),
              );
            },
          ),
        ),
      ),
    );
  }

  void _resendOtp() {
    setState(() {
      enableResend = false;
    });
    BlocProvider.of<SecurityBloc>(context).add(SecurityOtpResend());

    Timer(Duration(seconds: 60), () {
      if (!mounted) return;
      setState(() {
        enableResend = true;
      });
    });
  }

  void _validateAndSend() {
    if (!mounted || isProcessing) return;
    setState(() {
      fToast = FToast();
      fToast.init(context);
    });

    // Navigator.of(context).pushNamed( OderRoutes.securitySet);

    if (pinController.text.length != 6) {
      setProcessingStatus(false);
      errorfield = 'errorOtp';
      showErrorToast('OTP number are required!', context);

      // ErrorIconDialog.showErrorDialog(context, 'OTP number are required!');
    } else {
      errorfield = '';
      setProcessingStatus(true);
      // Storage().otp = otpController.text;
      // Navigator.of(context).pushNamed( OderRoutes.securitySet);
      BlocProvider.of<SecurityBloc>(
        context,
      ).add(SecurityOtpVerify(otp: pinController.text, otpToken: tokenVerify));
    }
  }
}
