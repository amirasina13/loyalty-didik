import '../../../widgets/independent/passcode_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../widgets/widgets.dart';
import '../../maintenance/maintenance_screen.dart';
import '../security_pin.dart';

class SecurityPhoneView extends StatefulWidget {
  final Function changeView;
  const SecurityPhoneView({super.key, required this.changeView});

  @override
  State<SecurityPhoneView> createState() => _SecurityPhoneViewState();
}

class _SecurityPhoneViewState extends State<SecurityPhoneView> {
  bool isProcessing = false;

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SecurityBloc, SecurityState>(
      listener: (context, state) {
        fToast = FToast();
        fToast.init(context);

        // if (state is SecurityOtpSent) {
        //   showSuccessToast(state.data['message'], context);
        //   Navigator.of(context).pushNamed( OderRoutes.securityOtp);

        // }

        if (state is SecurityError) {
          setProcessingStatus(false);
          showErrorToast(state.error, context);
        }
        if (state is SecurityNetworkError) {
          setProcessingStatus(false);
          showErrorToast(state.error, context);
        }
        if (state is SecurityOtpSent) {
          setProcessingStatus(false);
          // setProcessingStatus(false);
          // setResetProcessingStatus(false);
          showSuccessToast(state.data['message'], context);

          Navigator.of(context).pushNamed(
            OderRoutes.securityOtp,
            arguments: SecurityOtpParameters(otpData: state.data),
          );
        }

        /* --------------------------------------------------------------------- Listen to maintenance error, navigate to maintenance page */
        if (state is SecurityMaintenanceError) {
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
      },
      builder: (context, state) {
        return PasscodeIntro(
          creating: false,
          busy: isProcessing || state is SecurityProcessing,
          onContinue: () {
            setProcessingStatus(true);
            BlocProvider.of<SecurityBloc>(context).add(SecurityOtpSend());
          },
          onCancel: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              Storage().page == 'wallet'
                  ? OderRoutes.wallet
                  : OderRoutes.setting,
              (route) => false,
            );
          },
        );
      },
    );
  }
}
