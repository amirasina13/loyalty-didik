import '../../../widgets/independent/account_verification_layout.dart';
import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../../util/utils.dart';
import '../../../widgets/widgets.dart';
import '../../authentication/authentication.dart';
import '../../country/country.dart';
import '../../maintenance/maintenance_screen.dart';
import '../../profile/profile.dart';
import '../../webview/webview_deeplink.dart';
import '../setup.dart';

class CValidView extends StatefulWidget {
  final Function? changeView;
  final Map profile;

  const CValidView({super.key, this.changeView, required this.profile});

  @override
  State<CValidView> createState() => _CValidViewState();
}

class _CValidViewState extends State<CValidView> {
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  // final GlobalKey<OderInputField> _genderKey = GlobalKey();

  String errorfield = '';

  bool isProcessing = false;
  bool error = false, isRegisterEmail = false;
  String newDate = '';
  String errorGender = '', errorContact = '';
  String resendVtoken = '';
  late FocusNode _contactFocus, _genderFocus;
  String selectedCode = '60';

  List<String> getGender = ["Male", "Female"];
  List<String> getCode = [];

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  void _initDeepLinkListener() {
    _appLinks = AppLinks();
    _sub = _appLinks!.uriLinkStream.listen((uri) async {
      TempData.deeplink = uri.toString();
    });
  }

  @override
  void initState() {
    super.initState();

    initializeDateFormatting();

    _setProfileData();

    _contactFocus = FocusNode();
    _genderFocus = FocusNode();

    if (Platform.isIOS) {
      DeepLinkHandler.listenForDeepLinkIOS();
    } else {
      _initDeepLinkListener();
    }

    isRegisterEmail = registerMethod == 'email';
  }

  @override
  void dispose() {
    _contactController.dispose();
    _genderController.dispose();

    // Clean up the focus node when the Form is disposed.
    _contactFocus.dispose();
    _genderFocus.dispose();

    _sub?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SetupBloc, SetupState>(
      listener: (context, state) {
        if (state is SetupContactDone) {
          setProcessingStatus(false);
          showSuccessToast(state.data['message'], context);

          // AuthFlowCoordinator.handleAuthentication(
          //   context,
          //   widget.profile,
          //   isRegisterEmail: isRegisterEmail,
          //   isMuslimFriendly: isMuslimFriendly == true,
          //   deepLink: TempData.deeplink,
          // );

          // if (!isRegisterEmail && !widget.profile['eValid']) {
          //   Storage().setupDone == false;
          //   // need to fill and get OTP
          //   if (mounted) {
          //     Navigator.of(context).pushNamedAndRemoveUntil(
          //       OderRoutes.setupEValid,
          //       (Route<dynamic> route) => false,
          //       arguments: EValidParameters(loginData: widget.profile),
          //     );
          //   }
          // } else
          if (widget.profile['vProfile'] == false) {
            Storage().setupDone == false;
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                OderRoutes.setupVProfile,
                (Route<dynamic> route) => false,
                arguments: VProfileParameters(profile: widget.profile),
              );
            }
          } else if (isMuslimFriendly == true &&
              widget.profile['vMuslim'] == false) {
            Storage().setupDone == false;
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                OderRoutes.setupVMuslim,
                (Route<dynamic> route) => false,
                arguments: VMuslimParameters(profile: widget.profile),
              );
            }
          } else if (TempData.deeplink.isNotEmpty) {
            Storage().setupDone = null;
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
              // Storage().setupDone = null;
              Navigator.of(context).pushNamedAndRemoveUntil(
                OderRoutes.home,
                (Route<dynamic> route) => false,
              );
            }
          }
        }

        if (state is SetupContactOtp) {
          Navigator.of(context)
              .pushNamed(
                OderRoutes.setupCValidOtp,
                arguments: CValidOtpParameters(
                  loginData: widget.profile,
                  otpData: state.data,
                ),
              )
              .then((value) {
                resendVtoken = state.data['data']['vToken'];
                setProcessingStatus(false);
              });

          showSuccessToast(state.data['message'], context);
        }

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
        if (state is SetupError) {
          setProcessingStatus(false);
          // ignore: unnecessary_null_comparison
          state.error != null ? error = true : error = false;
          showErrorToast(state.error, context);
          // ErrorDialog.showErrorDialog(context, state.error);
        }
      },
      builder: (context, state) {
        return AccountVerificationLayout(
          controller: _contactController,
          focusNode: _contactFocus,
          processing: isProcessing,
          onChanged: (value) {
            if (value.isNotEmpty) {
              setState(() {
                errorfield = '';
                error = false;
              });
            }
          },
          onNext: _validateAndUpdatePersonal,
          onLogout: () {
            BlocProvider.of<AuthenticationBloc>(
              context,
            ).add(AuthenticationLoggedOut());
            Storage().token = '';
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(OderRoutes.login, (route) => false);
          },
          countrySelector: BlocProvider<CountryBloc>(
            create: (_) => CountryBloc()..add(CountryLoad()),
            child: BlocConsumer<CountryBloc, CountryState>(
              listener: (context, state) {
                if (state is CountryError) showErrorToast(state.error, context);
                if (state is CountryNetworkError) {
                  showErrorToast(state.error, context);
                }
              },
              builder: (context, state) {
                if (state is CountryListLoaded) {
                  getCode = _getCodes(state.countries);
                }
                final codes =
                    {
                      selectedCode,
                      ...getCode,
                    }.where((code) => code.isNotEmpty).toList();
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCode,
                    isDense: true,
                    isExpanded: true,
                    dropdownColor: AppDesign.setup.background,
                    icon: Icon(
                      Icons.expand_more,
                      size: 18,
                      color: AppDesign.setup.muted,
                    ),
                    style: TextStyle(
                      fontFamily: fontFamilyMain,
                      fontSize: AppDesign.bodySize,
                      color: AppDesign.setup.text,
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
                      if (code != null) setState(() => selectedCode = code);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _validateAndUpdatePersonal() {
    if (!mounted) return;
    setState(() {
      fToast = FToast();
      fToast.init(context);
    });

    if (_contactController.text.isEmpty) {
      errorfield = 'errorContact';
      _contactFocus.requestFocus();
      showErrorToast('Please enter a valid mobile number!', context);
      // ErrorIconDialog.showErrorDialog(context, 'Please enter valid email!');

      BlocProvider.of<ProfileBloc>(
        context,
      ).add(ProfileEditLoad(errorField: errorfield));
    } else {
      setProcessingStatus(true);
      Storage().contact = '$selectedCode-${_contactController.text.trim()}';

      BlocProvider.of<SetupBloc>(context).add(
        SetupContact(
          contact: '$selectedCode-${_contactController.text.trim()}',
        ),
      );
    }
  }

  // void _setProfileData(ProfileState state) {
  void _setProfileData() {
    var profile = widget.profile['profile'];

    _contactController.text =
        profile['contact'].substring(profile['contact'].indexOf("-") + 1) ?? '';

    // _genderController.text = profile['gender'] ?? '';

    selectedCode =
        profile['contact'] != ''
            ? profile['contact'].substring(0, profile['contact'].indexOf("-"))
            : '60';
  }

  List<String> _getCodes(List<Country> countries) {
    List<String> codes = [];
    for (var value in countries) {
      codes.add(value.callCode ?? '');
    }

    return codes;
  }
}
