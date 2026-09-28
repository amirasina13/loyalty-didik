import '../../../widgets/independent/passcode_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../widgets/widgets.dart';
import '../security_pin.dart';

class SecurityCreateView extends StatefulWidget {
  final Function changeView;
  final int? voucherId;
  final String? title;

  const SecurityCreateView({
    super.key,
    required this.changeView,
    this.voucherId,
    this.title,
  });

  @override
  State<SecurityCreateView> createState() => _SecurityCreateViewState();
}

class _SecurityCreateViewState extends State<SecurityCreateView> {
  bool isProcessing = false;

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SecurityBloc, SecurityState>(
      listener: (context, securityState) {
        if (securityState is SecurityError) {
          setProcessingStatus(false);
          showErrorToast(securityState.error, context);
        }
        if (securityState is SecurityNetworkError) {
          setProcessingStatus(false);
          showErrorToast(securityState.error, context);
        }
        if (securityState is SecurityOtpSent) {
          setProcessingStatus(false);

          showSuccessToast(securityState.data['message'], context);
          Navigator.of(context).pushNamed(
            OderRoutes.securityOtp,
            arguments: SecurityOtpParameters(otpData: securityState.data),
          );
        }
      },
      builder: (context, state) {
        return PasscodeIntro(
          creating: true,
          busy: isProcessing || state is SecurityProcessing,
          onContinue: () {
            setProcessingStatus(true);
            BlocProvider.of<SecurityBloc>(context).add(SecurityOtpSend());
          },
          onCancel: () {
            Navigator.of(context).maybePop();
          },
        );
      },
    );
  }
}
