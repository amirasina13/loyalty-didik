import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timer_count_down/timer_count_down.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../domain/domain.dart';
import '../../../widgets/widgets.dart';
import '../../maintenance/maintenance_screen.dart';
import '../../otp/otp.dart';
import '../forgot_pass.dart';

class ForcePassView extends StatefulWidget {
  final Function changeView;
  final String method; //Will receive email or password
  final String vToken;

  // ignore: use_key_in_widget_constructors
  const ForcePassView({
    Key? key,
    required this.changeView,
    required this.method,
    required this.vToken,
  }) : super();

  @override
  State<ForcePassView> createState() => _ForcePassViewState();
}

class _ForcePassViewState extends State<ForcePassView> {
  bool error = false;
  bool isProcessing = false;
  bool enableResend = true, isRegisterEmail = false;
  String passwordValid = '';
  String errorfield = '';
  String errorTextPwd = '', errorTextCfmPwd = '', errorTextMissMatch = '';
  String reqMethod = '', resendvToken = '', tokenVerify = '';

  // OtpFieldController otpController = OtpFieldController();
  /// Create Controller
  // OtpFieldController otpController = OtpFieldController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<OderInputFieldState> newPasswordKey = GlobalKey();
  final GlobalKey<OderInputFieldState> confirmPasswordKey = GlobalKey();
  final pinController = TextEditingController();
  final focusNode = FocusNode();

  String? otpCode = '';
  late double sizeBetween;
  late FocusNode pwFocus, confirmPwFocus;

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();

    pwFocus = FocusNode();
    confirmPwFocus = FocusNode();

    isRegisterEmail = registerMethod == 'email';

    reqMethod = widget.method;
    resendvToken = widget.vToken;
    _requestOtp();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    pwFocus.dispose();
    confirmPwFocus.dispose();
    pinController.dispose();
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: error == false ? colorDarkGray : colorRed,
          selectionHandleColor: colorMulberry,
        ),
      ),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppDesign.recovery.background,
          body: BlocConsumer<ForgotPassBloc, ForgotPassState>(
            listener: (context, state) {
              // on success delete navigator stack and push to home
              if (state is ForgotPassOtpVerified) {
                SuccessTimerDialog.showSuccessTimerDialog(
                  context,
                  state.message,
                  () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      OderRoutes.login,
                      (Route<dynamic> route) => false,
                    );
                  },
                  title: 'Password reset',
                  buttonLabel: 'Back to login',
                  autoClose: false,
                );
              }
              if (state is ForgotPassResent) {
                setProcessingStatus(false);
                showSuccessToast(state.data['message'], context);
              }
              // on failure show a snackbar
              if (state is ForgotPassError) {
                // otpController.clear();

                // ignore: unnecessary_null_comparison
                state.error != null ? error = true : error = false;
                setProcessingStatus(false);

                showErrorToast(state.error, context);
                // ErrorIconDialog.showErrorDialog(context, state.error);
              }
              // maintenance mode on
              if (state is ForgotPassMaintenanceError) {
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
              if (state is ForgotPassProcessing) {
                // return LoadingWidget();
              }

              if (state is ForgotPassSent) {
                reqMethod = state.data['data']['email'];
                resendvToken = state.data['data']['vToken'];
              }

              return SingleChildScrollView(
                child: Container(
                  height: ScreenSize.height,
                  width: ScreenSize.width,
                  padding: EdgeInsets.fromLTRB(
                    marginHorizontal,
                    ScreenSize.height * 0.05,
                    marginHorizontal,
                    0,
                  ),
                  decoration: BoxDecoration(
                    color: AppDesign.recovery.background,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppDesign.spaceSm,
                            AppDesign.spaceSm,
                            AppDesign.spaceSm,
                            AppDesign.spaceXl,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Enter the OTP code',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: fontFamilyMain,
                                  fontSize: AppDesign.setupHeadingSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppDesign.recovery.text,
                                ),
                              ),
                              const SizedBox(height: AppDesign.spaceSm),
                              Text(
                                'We sent a six-digit code to $reqMethod.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: fontFamilyMain,
                                  fontSize: AppDesign.bodySize,
                                  height: 1.6,
                                  color: AppDesign.recovery.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        VerificationCodeInput(
                          controller: pinController,
                          focusNode: focusNode,
                          processing: isProcessing,
                          error: error,
                          palette: AppDesign.recovery,
                          onChanged: (value) {
                            otpCode = value;
                            if (error) setState(() => error = false);
                          },
                          onCompleted: (pin) => otpCode = pin,
                        ),
                        // SizedBox(height: ScreenSize.height * 0.05),
                        BlocConsumer<OtpBloc, OtpState>(
                          listener: (context, state) {
                            if (state is OtpRequestSuccess) {
                              // isChanging = true;

                              setProcessingStatus(false);
                              resendvToken = state.data['data']['vToken'];
                              tokenVerify = state.data['data']['token'];
                              showSuccessToast(state.data['message'], context);
                            }
                            if (state is OtpResent) {
                              setProcessingStatus(false);
                              resendvToken = state.data['data']['vToken'];
                              tokenVerify = state.data['data']['token'];
                              showSuccessToast(state.data['message'], context);
                            }
                          },
                          builder: (context, state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                                    child: Text(
                                      'Change password',
                                      style: TextStyle(
                                        fontSize: AppDesign.setupHeadingSize,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: fontFamilyMain,
                                        color: AppDesign.recovery.text,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: ScreenSize.height * 0.03),
                                OderAppTextField(
                                  key: newPasswordKey,
                                  controller: newPasswordController,
                                  palette: AppDesign.recovery,
                                  labelText: 'New password',
                                  validator: Validator.valueExists,
                                  keyboardType: TextInputType.visiblePassword,
                                  isPassword: true,
                                  focusNode: pwFocus,
                                  hintText: 'Enter your new password',
                                  hintStyle: TextStyle(
                                    fontFamily: fontFamilyMain,
                                    fontSize: AppDesign.smallSize,
                                    fontWeight: FontWeight.w300,
                                    color: colorOutletAddressLabelGrey,
                                  ),
                                  textAlignVertical: TextAlignVertical.center,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppDesign.spaceLg,
                                  ),
                                  style: TextStyle(
                                    fontFamily: fontFamilyMain,
                                    fontSize: AppDesign.smallSize,
                                    fontWeight: FontWeight.w300,
                                    color: colorOutletAddressLabelGrey,
                                  ),
                                  onChanged: (value) {
                                    if (value != '') {
                                      setState(() {
                                        errorfield = '';
                                        newPasswordKey.currentState?.validate();
                                      });
                                    }
                                  },
                                ),
                                errorfield == 'error' ||
                                        errorfield == 'errorPwd' ||
                                        errorfield == 'errorMismatch'
                                    ? Container(
                                      margin: EdgeInsets.only(top: 5),
                                      child: Text(
                                        errorfield == 'error' ||
                                                errorfield == 'errorPwd'
                                            ? errorTextPwd
                                            : errorTextMissMatch,
                                        style: TextStyle(
                                          fontSize: AppDesign.captionSize,
                                          fontWeight: FontWeight.w400,
                                          color:
                                              error
                                                  ? colorRed
                                                  : errorfield == 'error' ||
                                                      errorfield ==
                                                          'errorPwd' ||
                                                      errorfield ==
                                                          'errorMismatch'
                                                  ? colorRed
                                                  : colorGreyBox,
                                        ),
                                      ),
                                    )
                                    : Container(
                                      margin: EdgeInsets.only(
                                        top: 5,
                                        left: AppDesign.spaceLg,
                                      ),
                                      child: Text(
                                        'Must contain: Min. 8 characters, uppercase, lowercase, number and symbol (!@#)',
                                        style: TextStyle(
                                          fontFamily: fontFamilyMain,
                                          fontSize: AppDesign.captionSize,
                                          color: colorOutletAddressLabelGrey,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                const SizedBox(height: AppDesign.formFieldGap),
                                OderAppTextField(
                                  key: confirmPasswordKey,
                                  controller: confirmPasswordController,
                                  palette: AppDesign.recovery,
                                  labelText: 'Confirm new password',
                                  validator: Validator.valueExists,
                                  keyboardType: TextInputType.visiblePassword,
                                  isPassword: true,
                                  focusNode: confirmPwFocus,
                                  hintText: 'Enter your confirm new password',
                                  hintStyle: TextStyle(
                                    fontFamily: fontFamilyMain,
                                    fontSize: AppDesign.smallSize,
                                    fontWeight: FontWeight.w300,
                                    color: colorOutletAddressLabelGrey,
                                  ),
                                  textAlignVertical: TextAlignVertical.center,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppDesign.spaceLg,
                                  ),
                                  style: TextStyle(
                                    fontFamily: fontFamilyMain,
                                    fontSize: AppDesign.smallSize,
                                    fontWeight: FontWeight.w300,
                                    color: colorOutletAddressLabelGrey,
                                  ),
                                  onChanged: (value) {
                                    if (value != '') {
                                      setState(() {
                                        errorfield = '';
                                        confirmPasswordKey.currentState
                                            ?.validate();
                                      });
                                    }
                                  },
                                ),
                                errorfield == 'error' ||
                                        errorfield == 'errorCfmPwd' ||
                                        errorfield == 'errorMismatch'
                                    ? Container(
                                      margin: EdgeInsets.only(top: 5),
                                      child: Text(
                                        errorfield == 'error' ||
                                                errorfield == 'errorCfmPwd'
                                            ? errorTextCfmPwd
                                            : errorTextMissMatch,
                                        style: TextStyle(
                                          fontSize: AppDesign.captionSize,
                                          fontWeight: FontWeight.w400,
                                          color:
                                              error
                                                  ? colorRed
                                                  : errorfield == 'error' ||
                                                      errorfield ==
                                                          'errorCfmPwd' ||
                                                      errorfield ==
                                                          'errorMismatch'
                                                  ? colorRed
                                                  : colorGreyBox,
                                        ),
                                      ),
                                    )
                                    : Container(
                                      margin: EdgeInsets.only(
                                        top: 5,
                                        left: AppDesign.spaceLg,
                                      ),
                                      child: Text(
                                        'Must contain: Min. 8 characters, uppercase, lowercase, number and symbol (!@#)',
                                        style: TextStyle(
                                          fontFamily: fontFamilyMain,
                                          fontSize: AppDesign.captionSize,
                                          color: colorOutletAddressLabelGrey,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                SizedBox(height: ScreenSize.height * 0.08),
                                Container(
                                  padding: EdgeInsets.only(
                                    top: AppDesign.spaceLg,
                                  ),
                                  alignment: Alignment.bottomCenter,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        // height: height * 0.05,
                                        // width: width,
                                        alignment: Alignment.center,
                                        margin: EdgeInsets.only(
                                          bottom: AppDesign.spaceLg,
                                        ),
                                        color: colorTransparent,
                                        child:
                                            enableResend == false
                                                ? Countdown(
                                                  seconds: 60,
                                                  build: (_, double time) {
                                                    var duration = Duration(
                                                      seconds: time.toInt(),
                                                    );
                                                    return Container(
                                                      alignment:
                                                          Alignment.center,
                                                      // padding:
                                                      //     EdgeInsets.only(left: AppDesign.spaceLg, top: 0.0),
                                                      child: Text(
                                                        // 'Remaining Time: ${duration.inMinutes}:${duration.inSeconds.remainder(60)}',
                                                        // '${duration.inSeconds} seconds  ',
                                                        '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                                                        style: TextStyle(
                                                          color: colorCountGrey,
                                                          fontSize:
                                                              AppDesign
                                                                  .sectionTitleSize,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontFamily:
                                                              fontFamilyMain,
                                                        ),
                                                        textScaler:
                                                            TextScaler.linear(
                                                              scaleFactor,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  onFinished: () {},
                                                )
                                                : SizedBox(),
                                        // Text('Time left before enabling resend', style: TextStyle(),),
                                      ),
                                      Container(
                                        padding: EdgeInsets.only(
                                          bottom: AppDesign.spaceLg,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Didn\'t receive it?',
                                              style: TextStyle(
                                                fontFamily: fontFamilyMain,
                                                fontSize: AppDesign.bodySize,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            OderButtonText(
                                              'Send again',
                                              color:
                                                  enableResend == true
                                                      ? mainColor
                                                      : colorDarkGray,
                                              fontSize: AppDesign.bodySize,
                                              underline: true,
                                              fontWeight: FontWeight.w600,
                                              // fontStyle: FontStyle.italic,
                                              onClick:
                                                  enableResend == true
                                                      ? _resendOtp
                                                      : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                      AccountPrimaryButton(
                                        label:
                                            isProcessing
                                                ? 'Processing…'
                                                : 'Continue',
                                        palette: AppDesign.recovery,
                                        onPressed:
                                            isProcessing
                                                ? null
                                                : _validateAndSend,
                                      ),
                                      Center(
                                        child: TextButton(
                                          onPressed:
                                              isProcessing
                                                  ? null
                                                  : () {
                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
                                                    Navigator.of(context).pop();
                                                  },
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                AppDesign.recovery.action,
                                            minimumSize: const Size(48, 48),
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _requestOtp() {
    setProcessingStatus(true);
    BlocProvider.of<OtpBloc>(context).add(
      OtpRequest(
        method: reqMethod,
        sendvia: isRegisterEmail ? 'email' : 'contact',
        purpose: 'forgot',
        vToken: resendvToken,
      ),
    );
  }

  void _resendOtp() {
    enableResend = false;
    BlocProvider.of<OtpBloc>(context).add(
      OtpResend(
        method: reqMethod,
        sendvia: isRegisterEmail ? 'email' : 'contact',
        purpose: 'resend-forgot',
        vToken: resendvToken,
      ),
    );
    Timer(Duration(seconds: 60), () {
      if (!mounted) return;
      setState(() {
        enableResend = true;
      });
    });
  }

  void _validateAndSend() {
    setState(() {
      fToast = FToast();
      fToast.init(context);
    });
    if (otpCode == '') {
      setProcessingStatus(false);
      errorfield = 'errorOtp';
      showErrorToast('Otp No are required!', context);
    } else if (newPasswordController.text == '') {
      setProcessingStatus(false);
      errorfield = 'errorPwd';
      errorTextPwd = 'The new password is required!';
      // showErrorToast('New password is required!', context);
    } else if (confirmPasswordController.text == '') {
      setProcessingStatus(false);
      errorfield = 'errorCfmPwd';
      errorTextCfmPwd = 'The confirmation password is required!';
      // showErrorToast('Password confirmation is required!', context);
    } else if (Validator.passwordCorrect(newPasswordController.text) != null) {
      setProcessingStatus(false);
      errorfield = 'errorMismatch';
      pwFocus.requestFocus();
      errorTextMissMatch =
          'Must contain: Min. 8 characters, uppercase, lowercase, number and symbol (!@#)';
    } else if (newPasswordController.text != confirmPasswordController.text) {
      setProcessingStatus(false);
      errorfield = 'errorMismatch';
      confirmPwFocus.requestFocus();
      errorTextMissMatch = 'Password mismatched';
      // showErrorToast('Password mismatched', context);
    } else {
      errorfield == '';
      setProcessingStatus(true);
      BlocProvider.of<ForgotPassBloc>(context).add(
        ForgotPassOtpSend(
          password: confirmPasswordController.text,
          otpCode: otpCode!,
          verifyToken: tokenVerify,
        ),
      );
    }
  }
}
