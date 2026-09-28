import '../../../widgets/independent/content_preference_layout.dart';
import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../util/utils.dart';
import '../../../widgets/widgets.dart';
import '../../authentication/authentication.dart';
import '../../maintenance/maintenance_screen.dart';
import '../../webview/webviews.dart';
import '../setup.dart';

class VMuslimView extends StatefulWidget {
  final Function? changeView;
  final Map profile;

  const VMuslimView({super.key, this.changeView, required this.profile});

  @override
  State<VMuslimView> createState() => _VMuslimViewState();
}

class _VMuslimViewState extends State<VMuslimView> {
  bool isProcessing = false;
  String _result = '';
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;
  List<String> getMuslim = [
    "Muslim-Friendly Content Only",
    "Include Non-Halal Content",
  ];

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

    if (Platform.isIOS) {
      DeepLinkHandler.listenForDeepLinkIOS();
    } else {
      _initDeepLinkListener();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SetupBloc, SetupState>(
      listener: (context, state) {
        /* --------------------------------------------------------------------- Listen to maintenance error, navigate to maintenance page */
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
        /* --------------------------------------------------------------------- IF Setup got error, show error message */
        if (state is SetupError) {
          setProcessingStatus(false);
          showErrorToast(state.error, context);
        }
        // if (state is SetupLoaded) {
        if (state is SetupMuslimFriendlyDone) {
          setProcessingStatus(false);
          showSuccessToast('${state.data['message']}', context);

          if (TempData.deeplink.isNotEmpty) {
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
      },
      builder: (context, state) {
        return ContentPreferenceLayout(
          selected: _result == getMuslim[0],
          processing: isProcessing,
          onChanged:
              (value) => setState(() {
                _result = getMuslim[value ? 0 : 1];
              }),
          onConfirm: _validateAndSend,
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
    if (!mounted) return;
    setState(() {
      fToast = FToast();
      fToast.init(context);
    });

    if (_result.isEmpty) {
      setProcessingStatus(false);
      // validateFocus.requestFocus();
      // ErrorIconDialog.showErrorDialog(context, 'Please select your reason');
      showErrorToast('Please select a content preference.', context);
    } else {
      setProcessingStatus(true);
      BlocProvider.of<SetupBloc>(
        context,
      ).add(SetupMuslimFriendly(isMuslim: _result == getMuslim[0]));
    }
  }

  void _setProfileData() {
    var profile = widget.profile['profile'];

    _result = getMuslim[profile['isMuslim'] == true ? 0 : 1];
  }
}
