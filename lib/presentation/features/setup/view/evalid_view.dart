import '../../../widgets/independent/account_verification_layout.dart';
import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../domain/domain.dart';
import '../../../../util/utils.dart';
import '../../../widgets/widgets.dart';
import '../../authentication/authentication.dart';
import '../../maintenance/maintenance_screen.dart';
import '../../webview/webviews.dart';
import '../setup.dart';

class EvalidView extends StatefulWidget {
  final Function? changeView;
  final Map loginData;

  const EvalidView({super.key, this.changeView, required this.loginData});

  @override
  State<EvalidView> createState() => _EvalidViewState();
}

class _EvalidViewState extends State<EvalidView> {
  bool isProcessing = false;
  bool error = false, isRegisterEmail = false;
  String errorfield = '';
  String errorTextEmail = '';
  String resendVtoken = '';

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;
  late FocusNode emailFocus;
  final TextEditingController emailController = TextEditingController();

  void setProcessingStatus(bool processing) {
    if (!mounted) return;
    setState(() {
      isProcessing = processing;
    });
  }

  bool _isLoginFlagEnabled(String key) => widget.loginData[key] == true;

  void _initDeepLinkListener() {
    _appLinks = AppLinks();
    _sub = _appLinks!.uriLinkStream.listen((uri) async {
      TempData.deeplink = uri.toString();
    });
  }

  @override
  void initState() {
    super.initState();

    final profile = widget.loginData['profile'] as Map?;
    resendVtoken = widget.loginData['vToken']?.toString() ?? '';
    emailFocus = FocusNode();
    emailController.text = profile?['email']?.toString() ?? '';

    if (Platform.isIOS) {
      DeepLinkHandler.listenForDeepLinkIOS();
    } else {
      _initDeepLinkListener();
    }

    isRegisterEmail = registerMethod == 'email';
  }

  @override
  void dispose() {
    _sub?.cancel();
    emailFocus.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SetupBloc, SetupState>(
      listener: (context, state) async {
        fToast = FToast();
        fToast.init(context);

        if (state is SetupMaintenanceError) {
          Navigator.pushAndRemoveUntil<void>(
            context,
            MaterialPageRoute<void>(
              builder:
                  (BuildContext context) => MaintenanceScreen(
                    parameters: MaintenanceParameters(message: state.message),
                  ),
            ),
            ModalRoute.withName('/'),
          );
        }

        if (state is SetupEmailDone) {
          setProcessingStatus(false);
          showSuccessToast(state.data['message'], context);

          // AuthFlowCoordinator.handleAuthentication(
          //   context,
          //   widget.loginData,
          //   isRegisterEmail: isRegisterEmail,
          //   isMuslimFriendly: isMuslimFriendly == true,
          //   deepLink: TempData.deeplink,
          // );

          // Check isContactRequired
          // if (isRegisterEmail && !widget.loginData['cValid']) {
          //   Storage().setupDone = false;
          //   // need to fill and get OTP
          //   if (mounted) {
          //     Navigator.of(context).pushNamedAndRemoveUntil(
          //       OderRoutes.setupCValid,
          //       (Route<dynamic> route) => false,
          //       arguments: CValidParameters(profile: widget.loginData),
          //     );
          //   }
          // }
          if (isContactRequired && !_isLoginFlagEnabled('cValid')) {
            Storage().setupDone = false;
            // need to fill and get OTP
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                OderRoutes.setupCValid,
                (Route<dynamic> route) => false,
                arguments: CValidParameters(profile: widget.loginData),
              );
            }
          } else if (!isContactRequired && !_isLoginFlagEnabled('cValid')) {
            Storage().setupDone = false;
            // need to fill only. No need OTP
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                OderRoutes.setupCValid,
                (Route<dynamic> route) => false,
                arguments: CValidParameters(profile: widget.loginData),
              );
            }
          } else if (!_isLoginFlagEnabled('vProfile')) {
            Storage().setupDone = false;
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                OderRoutes.setupVProfile,
                (Route<dynamic> route) => false,
                arguments: VProfileParameters(profile: widget.loginData),
              );
            }
          } else if (isMuslimFriendly == true &&
              !_isLoginFlagEnabled('vMuslim')) {
            Storage().setupDone = false;
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                OderRoutes.setupVMuslim,
                (Route<dynamic> route) => false,
                arguments: VMuslimParameters(profile: widget.loginData),
              );
            }
          } else if (TempData.deeplink.isNotEmpty) {
            Storage().setupDone = true;
            // Navigate to webview to intercept the url - convert from short url to long url
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => RedirectWebView(
                      parameters: DeeplinkParameters(
                        initialUrl: TempData.deeplink,
                      ),
                    ),
              ),
            );
          } else {
            if (mounted) {
              Storage().setupDone = true;
              Navigator.of(context).pushNamedAndRemoveUntil(
                OderRoutes.home,
                (Route<dynamic> route) => false,
              );
            }
          }
        }

        if (state is SetupEmailOtp) {
          Navigator.of(context)
              .pushNamed(
                OderRoutes.setupEValidOtp,
                arguments: EValidOtpParameters(
                  loginData: widget.loginData,
                  otpData: state.data,
                ),
              )
              .then((value) {
                resendVtoken = state.data['data']['vToken']?.toString() ?? '';
                setProcessingStatus(false);
              });
        }

        if (state is SetupError) {
          setProcessingStatus(false);
          showErrorToast(state.error, context);
        }
      },
      builder: (context, state) {
        return AccountVerificationLayout(
          isEmail: true,
          controller: emailController,
          focusNode: emailFocus,
          processing: isProcessing,
          onChanged: (value) {
            if (value.isNotEmpty) {
              setState(() {
                errorfield = '';
                error = false;
              });
            }
          },
          onNext: _validateAndSend,
          onLogout: () {
            BlocProvider.of<AuthenticationBloc>(
              context,
            ).add(AuthenticationLoggedOut());
            Storage().token = '';
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(OderRoutes.login, (route) => false);
          },
        );
      },
    );
  }

  void _validateAndSend() {
    if (!mounted || isProcessing) return;

    // Navigator.of(context).pushNamed(OderRoutes.otpCValidSend,
    //     arguments: CValidSendParameters(
    //       loginData: widget.loginData,
    //       otpData: {
    //         "isMaintenance": false,
    //         "status": true,
    //         "message":
    //             "An OTP code has been sent to sina@gmail.com. Please enter the code to proceed.",
    //         "data": {
    //           "token":
    //               "00b25a87e0856213b62296e3b2903771345a33c3777f421cb2c52b010d6808e5", // use this to verify otp
    //           "send_to": "sinamira@gmail.com",
    //           "vToken":
    //               "e796145663ab8ea6e82025b4a51c576914d30f0c45834510793f04c2a9867f29" // For resend otp
    //         }
    //       },
    //     ));
    setState(() {
      fToast = FToast();
      fToast.init(context);
    });

    if (Validator.valueExists(emailController.text) != null) {
      setProcessingStatus(false);
      errorfield = 'errorEmail';
      emailFocus.requestFocus();
      errorTextEmail = 'The email address is required!';
      showErrorToast(errorTextEmail, context);
    } else {
      errorfield = '';
      setProcessingStatus(true);
      BlocProvider.of<SetupBloc>(
        context,
      ).add(SetupEmail(email: emailController.text));
      // BlocProvider.of<OtpBloc>(context).add(OtpRequest(
      //   email: emailController.text,
      //   purpose: 'resend-register',
      //   vToken: resendVtoken,
      // ));
    }
  }

  // void _requestOtp() {
  //   setProcessingStatus(true);
  //   // Navigator.of(context).pushNamed( OderRoutes.otpCValidSend,
  //   //     arguments: CValidSendParameters(
  //   //       loginData: widget.loginData,
  //   //       otpData: {
  //   //         "isMaintenance": false,
  //   //         "status": true,
  //   //         "message":
  //   //             "An OTP code has been sent to sina@gmail.com. Please enter the code to proceed.",
  //   //         "data": {
  //   //           "token":
  //   //               "00b25a87e0856213b62296e3b2903771345a33c3777f421cb2c52b010d6808e5", // use this to verify otp
  //   //           "send_to": "sinamira@gmail.com",
  //   //           "vToken":
  //   //               "e796145663ab8ea6e82025b4a51c576914d30f0c45834510793f04c2a9867f29" // For resend otp
  //   //         }
  //   //       },
  //   //     ));
  //   BlocProvider.of<OtpBloc>(context).add(OtpRequest(
  //     email: widget.loginData['profile']['email'],
  //     purpose: 'resend-register',
  //     vToken: resendVtoken,
  //   ));
  // }
}
