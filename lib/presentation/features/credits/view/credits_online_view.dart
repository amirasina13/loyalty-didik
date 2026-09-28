import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pinput/pinput.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../util/utils.dart';
import '../../../widgets/widgets.dart';
import '../../authentication/authentication.dart';
import '../../maintenance/maintenance_screen.dart';
import '../../profile/profile.dart';
import '../../security_pin/security_pin.dart';
import '../credits.dart';

class CreditOnlineView extends StatefulWidget {
  final Function? changeView;

  const CreditOnlineView({super.key, this.changeView});

  @override
  State<CreditOnlineView> createState() => _CreditOnlineViewState();
}

class _CreditOnlineViewState extends State<CreditOnlineView> {
  List<RadioModel> amountOptions = [];
  String selectedAmount = '';
  String errorfield = '';

  TextEditingController amountController = TextEditingController();
  final GlobalKey<OderInputFieldState> amountKey = GlobalKey();
  final TextEditingController pinController = TextEditingController();
  late FocusNode amountFocus;
  bool isProcessing = false;
  bool load = false;
  bool rebutton = false;
  SliderButtonController slideController = SliderButtonController();

  final defaultPinTheme = PinTheme(
    width: 56,
    height: 56,
    textStyle: TextStyle(
      fontSize: AppDesign.titleSize,
      color: Color.fromRGBO(30, 60, 87, 1),
      fontWeight: FontWeight.w600,
    ),
    margin: EdgeInsets.zero,
  );

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();

    /* ------------------------------------------------------------------------- Add amount in amountOptions list from API */
    for (var amount in creditSelection) {
      amountOptions.add(
        RadioModel(false, amount),
      ); //adding each value to the list
    }

    amountFocus = FocusNode();

    fToast = FToast();
    fToast.init(context);
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.

    amountFocus.dispose();
    amountController.dispose();
    pinController.dispose();
    slideController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreditBloc, CreditState>(
      // bloc: CreditBloc,
      listener: (context, creditState) {
        /* --------------------------------------------------------------------- If user click "Reload Now" button, will open topup webview */
        if (creditState is CreditOnlineLoaded) {
          setProcessingStatus(false);
          Navigator.push(
            context,
            NoAnimationPageRoute(
              builder: (context) {
                // Directly return WidgetWebView, as it contains its own Scaffold and AppBar
                return WidgetWebView(
                  widgetUrl: creditState.url,
                  title: 'Top Up Wallet',
                );
              },
            ),
          ).then(
            (value) => Timer(Duration(milliseconds: 5), () {
              if (!mounted) return;
              // slideController.removeListener(() {
              //   //   return slideController.reset();
              // });
              slideController.reset();
              BlocProvider.of<ProfileBloc>(context).add(ProfileLoad());
              // slideController.dispose();
            }),
          );
          // Navigator.push(
          //   context,
          //   NoAnimationPageRoute(
          //     builder: (context) {
          //       return Scaffold(
          //         appBar: AppBar(
          //           systemOverlayStyle: SystemUiOverlayStyle(
          //             statusBarColor: AppDesign.topUp.background,
          //             systemNavigationBarColor: colorWhite,
          //           ),
          //           title: Text(
          //             'Top Up Wallet',
          //             style: TextStyle(
          //               fontFamily: fontFamilyMain,
          //               color: AppDesign.topUp.text,
          //               fontWeight: FontWeight.w400,
          //               fontSize: 15,
          //             ),
          //             textScaler: TextScaler.linear(scaleFactor),
          //           ),
          //           leading: IconButton(
          //             icon: Icon(Icons.close),
          //             onPressed: () {
          //               Navigator.pop(context);
          //             },
          //           ),
          //           centerTitle: true,
          //           backgroundColor: AppDesign.topUp.background,
          //           iconTheme: IconThemeData(color: AppDesign.topUp.text),
          //           elevation: 0,
          //         ),
          //         // body: TopupWebView(paymentUrl: creditState.url),
          //         body: WidgetWebView(widgetUrl: creditState.url),
          //       );
          //     },
          //   ),
          // ).then(
          //   (value) => Timer(Duration(milliseconds: 5), () {
          //     // slideController.removeListener(() {
          //     //   //   return slideController.reset();
          //     // });
          //     slideController.reset();
          //     BlocProvider.of<ProfileBloc>(context).add(ProfileLoad());
          //     // slideController.dispose();
          //   }),
          // );
        }

        if (creditState is CreditError) {
          setProcessingStatus(false);
          // setState(() {
          // print('RESET!!');
          Timer(Duration(milliseconds: 5), () {
            // slideController.removeListener(() {
            //   //   return slideController.reset();
            // });
            slideController.reset();
            // slideController.dispose();
          });
          // rebutton = false;
          // slideController.dispose();

          // BlocProvider.of<ProfileBloc>(context)
          //   ..reloadBack = true
          //   ..add(ProfileLoad());
          // });

          // setState(() {
          //   BlocProvider.of<ProfileBloc>(context)
          //     ..reloadBack = true
          //     ..add(ProfileLoad());
          // });

          showErrorToast(creditState.error, context);
        }
        if (creditState is CreditNetworkError) {
          showErrorToast(creditState.error, context);
        }
        if (creditState is CreditSessionError) {
          sessionExpiredLogOut(creditState.error);
        }
      },

      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, profileState) {},
        builder: (context, profileState) {
          if (profileState is ProfileReloading) {
            return Container(
              // height: height * 0.7,
              color: AppDesign.topUp.background,
              child: LoadingWidget(),
            );
          }

          return Container(
            color: AppDesign.topUp.background,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDesign.spaceXl,
                      AppDesign.spaceXl,
                      AppDesign.spaceXl,
                      AppDesign.spaceSm,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Current balance',
                          style: TextStyle(
                            color: AppDesign.topUp.muted,
                            fontSize: AppDesign.bodySize,
                          ),
                        ),
                        const SizedBox(height: AppDesign.spaceSm),
                        Text(
                          profileState is ProfileLoaded
                              ? '${profileState.userProfile.profile?.credits ?? ''} $creditLabelText'
                              : '—',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppDesign.topUp.text,
                            fontSize: AppDesign.sectionTitleSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      /* ----------------------------------------------------------- Input reload part */
                      Container(
                        // margin: EdgeInsets.only(top: 40),
                        margin: EdgeInsets.fromLTRB(
                          marginHorizontal,
                          20,
                          marginHorizontal,
                          0,
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Set Amount',
                          style: TextStyle(
                            fontSize: AppDesign.bodyLargeSize,
                            fontFamily: fontFamilyMain,
                            fontWeight: FontWeight.w600,
                            color: AppDesign.topUp.text,
                          ),
                          textScaler: TextScaler.linear(scaleFactor),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(
                          marginHorizontal,
                          5,
                          marginHorizontal,
                          0,
                        ),
                        child: Text(
                          'How much would you like to top up?',
                          style: TextStyle(
                            color: AppDesign.topUp.text,
                            fontSize: AppDesign.captionSize,
                            fontWeight: FontWeight.w300,
                          ),
                          textScaler: TextScaler.linear(scaleFactor),
                        ),
                      ),
                      /* Input field part */
                      Theme(
                        data: ThemeData(
                          primaryColor: AppDesign.topUp.text,
                          textSelectionTheme: TextSelectionThemeData(
                            cursorColor:
                                errorfield == '' ? colorUsedGray : colorRed,
                            selectionHandleColor: AppDesign.topUp.action,
                          ),
                        ),
                        child: Container(
                          // margin: EdgeInsets.only(top: 0, bottom: 10),
                          margin: EdgeInsets.fromLTRB(
                            marginHorizontal,
                            AppDesign.spaceXxl,
                            marginHorizontal,
                            10,
                          ),
                          alignment: Alignment.center,
                          height: 96,
                          child: TextField(
                            key: amountKey,
                            controller: amountController,
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              CurrencyTextInputFormatter.currency(symbol: ''),
                              // DecimalTextInputFormatter(decimalRange: 2)
                              // CurrencyTextInputFormatter(symbol: ''),
                              // CurrencyTextInputFormatter(
                              //     // locale: 'ko',
                              //     // decimalDigits: 0,
                              //     // symbol: '',
                              //     ),
                            ],
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.fromLTRB(
                                0,
                                0,
                                0,
                                AppDesign.spaceLg,
                              ),
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                fontSize: AppDesign.heroSize,
                                fontWeight: FontWeight.w600,
                                fontFamily: fontFamilyMain,
                                color: colorTopupGrey,
                              ),
                              isDense: true,
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color:
                                      errorfield == '' ? colorGrey : colorRed,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(
                              fontSize: AppDesign.heroSize,
                              fontWeight: FontWeight.w600,
                              color:
                                  errorfield == ''
                                      ? AppDesign.topUp.action
                                      : colorRed,
                              fontFamily: fontFamilyMain,
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            focusNode: amountFocus,
                            onChanged: (value) {
                              if (value != '') {
                                setState(() {
                                  errorfield = '';
                                  amountKey.currentState?.validate();

                                  if (selectedAmount != amountController.text) {
                                    for (var element in amountOptions) {
                                      element.isSelected = false;
                                    }
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      /* ----------------------------------------------------------- List of amountOptions part */
                      Container(
                        // margin: EdgeInsets.symmetric(vertical: 10),
                        margin: EdgeInsets.fromLTRB(
                          marginHorizontal,
                          10,
                          marginHorizontal,
                          10,
                        ),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          crossAxisCount: 3,
                          childAspectRatio: (50 / 25),
                          children: List.generate(amountOptions.length, (
                            index,
                          ) {
                            return InkWell(
                              splashColor: colorGoldButton,
                              onTap: () {
                                setState(() {
                                  for (var element in amountOptions) {
                                    element.isSelected = false;
                                  }
                                  amountOptions[index].isSelected = true;
                                  selectedAmount =
                                      amountOptions[index].buttonText;
                                  amountController.text =
                                      amountOptions[index].buttonText;
                                });
                              },
                              child: OderRadioSelect(amountOptions[index]),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                /* ----------------------------------------------------------------- Reload Now button part */
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: BlocConsumer<SecurityBloc, SecurityState>(
                    listener: (context, securityState) {
                      fToast = FToast();
                      fToast.init(context);
                      if (securityState is SecurityCheckVerified) {
                        setProcessingStatus(false);

                        if (securityState.verified == false) {
                          Storage().page = 'credits';
                          Navigator.of(
                            context,
                          ).pushNamed(OderRoutes.securityCreate).then((value) {
                            setProcessingStatus(false);

                            Timer(Duration(milliseconds: 5), () {
                              slideController.reset();
                            });
                          });
                        } else {
                          Storage().page = 'wallet';
                          Navigator.of(
                            context,
                          ).pushNamed(OderRoutes.passcodeKey).then((value) {
                            if (value != null) {
                              // passcodePin = value.toString();

                              // print('VALUEPIN: $vaslue');

                              setState(() {
                                _validateAndSend();

                                //
                                // BlocProvider.of<RewardBloc>(context)
                                //     .add(RewardPurchaseLoad(
                                //   voucherId: detail.voucher!.id!,
                                //   pin: passcodePin,
                                // ));
                              });
                            } else {
                              setProcessingStatus(false);

                              Timer(Duration(milliseconds: 5), () {
                                slideController.reset();
                              });
                            }
                          });
                        }
                      }

                      if (securityState is SecurityPinVerified) {
                        _validateAndSend();
                      }

                      if (securityState is SecurityError) {
                        setProcessingStatus(false);
                        showErrorToast(securityState.error, context);
                      }

                      /* ------------------------------------------------------------------- Listen to maintenance error, navigate to maintenance page */
                      if (securityState is SecurityMaintenanceError) {
                        Navigator.pushAndRemoveUntil<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder:
                                (BuildContext context) => MaintenanceScreen(
                                  parameters: MaintenanceParameters(
                                    message: securityState.message,
                                  ),
                                ),
                          ),
                          ModalRoute.withName('/'),
                        );
                      }
                    },
                    builder: (context, state) {
                      return SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppDesign.pagePadding,
                            AppDesign.spaceXl,
                            AppDesign.pagePadding,
                            AppDesign.spaceLg,
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AccountPrimaryButton(
                              palette: AppDesign.topUp,
                              label: isProcessing ? 'Processing…' : 'Continue',
                              onPressed: isProcessing ? null : _checkVerified,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _checkVerified() {
    if (isProcessing) return;
    if (amountController.text.isEmpty) {
      setProcessingStatus(false);
      errorfield = 'errorAmount';
      showErrorToast('Amount field cannot be empty', context);

      Timer(Duration(seconds: 1), () {
        slideController.reset();
      });
    } else {
      setProcessingStatus(true);
      FocusScope.of(context).unfocus();

      // rebutton = true;

      BlocProvider.of<SecurityBloc>(context).add(SecurityStart());
    }
  }

  // void _validateSecurityPin() {
  //   if (pinController.text == '') {
  //     showErrorToast('Security pin are required!', context);
  //   } else {
  //     FutureOr.delayed(Duration(seconds: 1), () {
  //       load = false;
  //       BlocProvider.of<SecurityBloc>(context).add(SecurityPinVerify(
  //         pin: pinController.text,
  //       ));
  //       Navigator.pop(context);
  //     });
  //   }
  // }

  void _validateAndSend() {
    fToast = FToast();
    fToast.init(context);

    String topupAmount = amountController.text.replaceAll(RegExp("[,]"), "");

    setProcessingStatus(true);
    BlocProvider.of<CreditBloc>(
      context,
    ).add(CreditOnlineLoad(amount: topupAmount.trim()));
  }

  void sessionExpiredLogOut(String error) {
    setState(() {
      fToast = FToast();
      fToast.init(context);
    });

    showErrorToast('$error\nYou will be logged out.', context);
    BlocProvider.of<AuthenticationBloc>(context).add(AuthenticationLoggedOut());
    Navigator.of(context).pushNamedAndRemoveUntil(
      OderRoutes.login,
      (Route<dynamic> route) => false,
    );
  }
}
