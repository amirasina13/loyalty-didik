import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../../domain/domain.dart';
import '../../../widgets/widgets.dart';
import '../../country/country.dart';
import '../../maintenance/maintenance_screen.dart';
import '../forgot_pass.dart';

class ForgetView extends StatefulWidget {
  final Function changeView;

  // ignore: use_key_in_widget_constructors
  const ForgetView({Key? key, required this.changeView}) : super();

  @override
  State<ForgetView> createState() => _ForgetViewState();
}

class _ForgetViewState extends State<ForgetView> {
  bool error = false;
  bool isProcessing = false, isRegisterEmail = false;
  String errorfield = '';
  String errorTextEmail = '';
  String selectedCode = '60';
  List<String> getCode = [];

  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final GlobalKey<OderInputFieldState> emailKey = GlobalKey();

  late FocusNode phoneFocus, emailFocus, contactFocus;
  final MyConnectivity _connectivity = MyConnectivity.instance;

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();

    Storage().token = '';
    emailFocus = FocusNode();
    contactFocus = FocusNode();

    isRegisterEmail = registerMethod == 'email';
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    emailFocus.dispose();
    contactFocus.dispose();

    _connectivity.disposeStream();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: errorfield == '' ? AppDesign.recovery.action : colorRed,
          selectionHandleColor: AppDesign.recovery.action,
        ),
      ),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppDesign.recovery.background,
          body: BlocConsumer<ForgotPassBloc, ForgotPassState>(
            listener: (context, state) {
              if (state is ForgotPassSent) {
                setProcessingStatus(false);
                Navigator.pushNamed(
                  context,
                  OderRoutes.resetPassword,
                  arguments: ResetPassParameters(
                    method:
                        isRegisterEmail
                            ? state.data['data']['email']
                            : state.data['data']['contact'],
                    vToken: state.data['data']['vToken'],
                  ),
                );
                // showSuccessToast(state.data['message'], context);
                // widget.changeView(
                //     changeType: ViewChangeType.Forward, data: state.data);
              }
              // on failure show a snackbar
              if (state is ForgotPassError) {
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
              return Container(
                height: ScreenSize.height,
                width: ScreenSize.width,
                padding: EdgeInsets.fromLTRB(
                  marginHorizontal,
                  ScreenSize.height * 0.05,
                  marginHorizontal,
                  0,
                ),
                decoration: BoxDecoration(color: AppDesign.recovery.background),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Image(
                          image: AssetImage(mainLogo),
                          height: ScreenSize.height * 0.13,
                        ),
                      ),
                      SizedBox(height: ScreenSize.height * 0.02),
                      Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: AppDesign.heroSize,
                          fontWeight: FontWeight.w700,
                          fontFamily: fontFamilyMain,
                          color: AppDesign.recovery.text,
                        ),
                      ),
                      const SizedBox(height: AppDesign.spaceXl),
                      isRegisterEmail
                          ? OderAppTextField(
                            palette: AppDesign.recovery,
                            labelText: 'Email Address',
                            key: emailKey,
                            controller: emailController,
                            validator: Validator.valueExists,
                            keyboardType: TextInputType.emailAddress,
                            focusNode: emailFocus,
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(
                              fontFamily: fontFamilyMain,
                              fontSize: AppDesign.smallSize,
                              fontWeight: FontWeight.w300,
                              color: AppDesign.recovery.muted,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppDesign.spaceLg,
                            ),
                            style: TextStyle(
                              fontFamily: fontFamilyMain,
                              fontSize: AppDesign.smallSize,
                              fontWeight: FontWeight.w300,
                              color: AppDesign.recovery.muted,
                            ),
                            onChanged: (value) {
                              if (value != '') {
                                setState(() {
                                  errorfield = '';
                                  error = false;
                                  emailKey.currentState?.validate();
                                });
                              }
                            },
                          )
                          : Container(
                            margin: const EdgeInsets.only(top: 20),
                            child: AccountPhoneRow(
                              countrySelector: BlocProvider<CountryBloc>(
                                create: (context) {
                                  // creditRecords.clear();
                                  return CountryBloc()..add(CountryLoad());
                                },
                                child: BlocConsumer<CountryBloc, CountryState>(
                                  listener: (context, state) {
                                    if (state is CountryError) {
                                      showErrorToast(state.error, context);
                                      // ErrorDialog.showErrorDialog(
                                      //     context, state.error);
                                    }
                                  },
                                  builder: (context, state) {
                                    if (state is CountryListLoaded) {
                                      getCode = _getCodes(state.countries);
                                    }

                                    if (state is CountryNetworkError) {
                                      _connectivity.initialise();
                                      _connectivity.myStream.listen((
                                        source,
                                      ) async {
                                        var connectionResult =
                                            await Connectivity()
                                                .checkConnectivity();

                                        if (connectionResult.contains(
                                              ConnectivityResult.mobile,
                                            ) &&
                                            connectionResult.contains(
                                              ConnectivityResult.wifi,
                                            )) {
                                          if (!context.mounted) return;
                                          BlocProvider.of<CountryBloc>(
                                            context,
                                          ).add(CountryLoad());
                                        }
                                      });
                                    }

                                    final codes =
                                        {selectedCode, ...getCode}
                                            .where((code) => code.isNotEmpty)
                                            .toList();
                                    return DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedCode,
                                        isDense: true,
                                        isExpanded: true,
                                        dropdownColor:
                                            AppDesign.recovery.background,
                                        icon: Icon(
                                          Icons.expand_more,
                                          size: 18,
                                          color: AppDesign.recovery.muted,
                                        ),
                                        style: TextStyle(
                                          fontFamily: fontFamilyMain,
                                          fontSize: AppDesign.bodySize,
                                          color: AppDesign.recovery.text,
                                        ),
                                        items:
                                            codes
                                                .map(
                                                  (code) => DropdownMenuItem(
                                                    value: code,
                                                    child: Text('+$code'),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (code) {
                                          if (code != null) {
                                            setState(() => selectedCode = code);
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              controller: contactController,
                              focusNode: contactFocus,
                              palette: AppDesign.recovery,
                              hintText: 'Example: 123456789',
                              onChanged: (value) {
                                if (value != '') {
                                  setState(() {
                                    errorfield = '';
                                    error = false;
                                  });
                                }
                              },
                            ),
                          ),
                      errorfield == 'error' ||
                              (isRegisterEmail
                                  ? errorfield == 'errorEmail'
                                  : errorfield == 'errorcontact')
                          ? Container(
                            margin: EdgeInsets.only(
                              top: 5,
                              left: AppDesign.spaceLg,
                            ),
                            child: Text(
                              errorTextEmail,
                              style: TextStyle(
                                fontSize: AppDesign.captionSize,
                                fontWeight: FontWeight.w400,
                                color:
                                    error
                                        ? colorRed
                                        : errorfield == 'error' ||
                                            (isRegisterEmail
                                                ? errorfield == 'errorEmail'
                                                : errorfield == 'errorcontact')
                                        ? colorRed
                                        : colorGreyBox,
                              ),
                            ),
                          )
                          : SizedBox(),
                      SizedBox(height: ScreenSize.height * 0.08),
                      OderCustomButton(
                        title: 'Request OTP',
                        textColor: isProcessing ? processingText : colorWhite,
                        backgroundColor:
                            isProcessing
                                ? processing
                                : AppDesign.recovery.action,
                        borderColor:
                            isProcessing
                                ? processing
                                : AppDesign.recovery.action,
                        borderRadius: 30,
                        height: AppDesign.buttonHeight,
                        onPressed: _validateAndSend,
                      ),
                      Center(
                        child: TextButton(
                          onPressed: isProcessing ? null : _showLogInScreen,
                          style: TextButton.styleFrom(
                            foregroundColor: AppDesign.recovery.action,
                            minimumSize: const Size(48, 48),
                          ),
                          child: const Text('Back to login'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<String> _getCodes(List<Country> countries) {
    List<String> codes = [];
    for (var value in countries) {
      codes.add(value.callCode ?? '');
    }

    return codes;
  }

  void _showLogInScreen() {
    // Storage().dynamicLink = null;
    Navigator.of(context).pushNamedAndRemoveUntil(
      OderRoutes.login,
      (Route<dynamic> route) => false,
    );
  }

  void _validateAndSend() {
    final bool isFieldEmpty =
        isRegisterEmail
            ? emailController.text.isEmpty
            : contactController.text.isEmpty;

    final String fieldErrorMessage =
        isRegisterEmail
            ? 'The email address is required!'
            : 'The contact number is required!';

    final String errorField = isRegisterEmail ? 'errorEmail' : 'errorcontact';

    final FocusNode fieldFocus = isRegisterEmail ? emailFocus : contactFocus;

    setState(() {
      fToast = FToast();
      fToast.init(context);
    });
    if (isFieldEmpty) {
      setProcessingStatus(false);
      errorfield = errorField;
      fieldFocus.requestFocus();
      errorTextEmail = fieldErrorMessage;
      // showErrorToast('Please enter valid email address!', context);
    } else {
      errorfield = '';
      setProcessingStatus(true);
      BlocProvider.of<ForgotPassBloc>(context).add(
        ForgotPassReset(
          email: isRegisterEmail ? emailController.text.trim() : '',
          contact:
              !isRegisterEmail
                  ? '$selectedCode-${contactController.text.trim()}'
                  : '',
        ),
      );
    }
  }
}
