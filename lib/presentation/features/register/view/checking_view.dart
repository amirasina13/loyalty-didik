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
import '../../webview/webviews.dart';
import '../../wrapper.dart';
import '../register.dart';

class RegisterView extends StatefulWidget {
  final Function changeView;
  final String referralCode;

  // ignore: use_key_in_widget_constructors
  const RegisterView({
    Key? key,
    required this.changeView,
    required this.referralCode,
  }) : super();

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  bool error = false;
  String errorfield = '', barcodeScanRes = '', voucherAffilliateCode = '';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController referralController =
      TextEditingController(); //text: "IF21ZFGMYC"
  final TextEditingController contactController = TextEditingController();
  final GlobalKey<OderInputFieldState> emailKey = GlobalKey();
  final GlobalKey<OderInputFieldState> refferelKey = GlobalKey();
  final GlobalKey<RedirectWebViewState> _controller = GlobalKey();

  String otpCode = '';
  String errorTextEmail = '';
  String selectedCode = '60';
  late double sizeBetween;
  List<String> getCode = [];
  bool isProcessing = false, isRegisterEmail = false;
  late FocusNode emailFocus, contactFocus;
  final MyConnectivity _connectivity = MyConnectivity.instance;

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

    emailFocus = FocusNode();
    contactFocus = FocusNode();

    voucherAffilliateCode = TempData.affiliateCode;
    referralController.text =
        widget.referralCode.isNotEmpty
            ? widget.referralCode
            : voucherAffilliateCode;

    isRegisterEmail = registerMethod == 'email';
  }

  @override
  void dispose() {
    _connectivity.disposeStream();

    // Clean up the focus node when the Form is disposed.
    emailFocus.dispose();
    contactFocus.dispose();

    super.dispose();
  }

  Future<void> _stopWebviewDeeplink() async {
    if (TempData.deeplink.isNotEmpty) {
      TempData.deeplink = '';
      _controller.currentState?.clearWebview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: errorfield == '' ? colorDarkGray : colorRed,
          selectionHandleColor: AppDesign.registration.action,
        ),
      ),
      child: Scaffold(
        backgroundColor: colorWhite,
        body: BlocConsumer<RegisterBloc, RegisterState>(
          listener: (context, state) {
            if (state is RegisterMaintenanceError) {
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
            if (state is ReferDecryptSuccess) {
              referralController.text = state.referCode;
            }
            if (state is ReferDecryptFail) {
              // setProcessingStatus(false);
              referralController.text = '';
              showErrorToast('Refferal code not valid.', context);
            }
            if (state is RegisterVerifySuccess) {
              setProcessingStatus(false);
              showSuccessToast(state.data['message'], context);
              Storage().referralCode = referralController.text;
              _stopWebviewDeeplink();

              widget.changeView(changeType: ViewChangeType.Forward);
            }
            if (state is RegisterError) {
              // ignore: unnecessary_null_comparison
              state.error != null ? error = true : error = false;

              setProcessingStatus(false);
              showErrorToast(state.error, context);
            }
            if (state is RegisterNetworkError) {
              setProcessingStatus(false);
              showErrorToast(state.error, context);
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
              decoration: BoxDecoration(
                color: AppDesign.registration.background,
              ),
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
                      'Create Account',
                      style: TextStyle(
                        fontSize: AppDesign.heroSize,
                        fontWeight: FontWeight.w700,
                        fontFamily: fontFamilyMain,
                        color: AppDesign.registration.text,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceXl),
                    isRegisterEmail
                        ? OderAppTextField(
                          palette: AppDesign.registration,
                          labelText: 'Email Address',
                          key: emailKey,
                          controller: emailController,
                          hintText: 'Enter your email',
                          focusNode: emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          hintStyle: TextStyle(
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.smallSize,
                            fontWeight: FontWeight.w300,
                            color: AppDesign.registration.muted,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppDesign.spaceLg,
                          ),
                          bottomBorderColor:
                              errorfield == 'error' ||
                                      errorfield == 'errorEmail'
                                  ? colorRed
                                  : colorWhite,
                          style: TextStyle(
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.smallSize,
                            fontWeight: FontWeight.w300,
                            color: AppDesign.registration.muted,
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
                                          AppDesign.registration.background,
                                      icon: Icon(
                                        Icons.expand_more,
                                        size: 18,
                                        color: AppDesign.registration.muted,
                                      ),
                                      style: TextStyle(
                                        fontFamily: fontFamilyMain,
                                        fontSize: AppDesign.bodySize,
                                        color: AppDesign.registration.text,
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
                            palette: AppDesign.registration,
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
                    const SizedBox(height: AppDesign.formFieldGap),
                    OderAppTextField(
                      palette: AppDesign.registration,
                      labelText: 'Referral Code (optional)',
                      key: refferelKey,
                      controller: referralController,
                      validator: Validator.valueExists,
                      hintText:
                          voucherAffilliateCode.isNotEmpty
                              ? voucherAffilliateCode
                              : widget.referralCode.isNotEmpty
                              ? widget.referralCode
                              : 'Enter your referral code',
                      hintStyle: TextStyle(
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.smallSize,
                        fontWeight: FontWeight.w300,
                        color: AppDesign.registration.muted,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDesign.spaceLg,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      endIcon: InkWell(
                        child: Container(
                          margin: EdgeInsets.all(AppDesign.spaceMd),
                          child: Image(
                            fit: BoxFit.contain,
                            color: AppDesign.registration.muted,
                            width: ScreenSize.width * 0.05,
                            image: AssetImage(
                              'assets/icons/global/scanner.webp',
                            ),
                          ),
                        ),
                        onTap: () {
                          Storage().page = 'referral';
                          scanBarcodeNormal();
                        },
                      ),
                      style: TextStyle(
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.smallSize,
                        fontWeight: FontWeight.w300,
                        color: AppDesign.registration.muted,
                      ),
                    ),
                    const SizedBox(height: AppDesign.formFieldGap),
                    AccountPrimaryButton(
                      label: isProcessing ? 'Processing…' : 'Next',
                      palette: AppDesign.registration,
                      onPressed: isProcessing ? null : _validateAndSend,
                    ),
                    Center(
                      child: TextButton(
                        onPressed: isProcessing ? null : _showLogInScreen,
                        style: TextButton.styleFrom(
                          foregroundColor: AppDesign.registration.action,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.only(
                            top: AppDesign.spaceLg,
                            bottom: AppDesign.spaceXs,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Back to login',
                          style: TextStyle(
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.bodySize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesign.formFieldGap),
                  ],
                ),
              ),
            );
          },
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

  Future<void> scanBarcodeNormal() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (BuildContext context) =>
                AppBarcodeScannerWidget.defaultStyle(tabFor: 'checking_email'),
      ),
    ).then((value) {
      barcodeScanRes = value.toString();

      if (value != null) {
        referDecryptValue(barcodeScanRes);
      }
    });
  }

  void referDecryptValue(String barcodeScanRes) {
    BlocProvider.of<RegisterBloc>(
      context,
    ).add(RegisterReferDecrypt(referCode: barcodeScanRes));
  }

  void _showLogInScreen() {
    // Storage().dynamicLink = null;
    _stopWebviewDeeplink();

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

    if (isFieldEmpty) {
      setProcessingStatus(false);
      errorfield = errorField;
      fieldFocus.requestFocus();
      errorTextEmail = fieldErrorMessage;
      // showErrorToast('Please enter valid email address!', context);
    } else {
      errorfield = '';
      setProcessingStatus(true);

      BlocProvider.of<RegisterBloc>(context).add(
        RegisterVerify(
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
