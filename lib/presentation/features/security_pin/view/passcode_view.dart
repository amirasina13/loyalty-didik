import '../../../widgets/independent/passcode_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../widgets/widgets.dart';
import '../security_pin.dart';

class PasscodeView extends StatefulWidget {
  final Function changeView;
  const PasscodeView({super.key, required this.changeView});

  @override
  State<PasscodeView> createState() => _PasscodeViewState();
}

class _PasscodeViewState extends State<PasscodeView> {
  bool isProcessing = false, isResetProcessing = false;
  String enteredPin = '';
  String verifyPin = '';

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  void setResetProcessingStatus(bool processing) {
    setState(() {
      isResetProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: BlocConsumer<SecurityBloc, SecurityState>(
        listener: (context, state) {
          if (state is SecurityPinVerified) {
            setProcessingStatus(false);
            Storage().secureStorage.delete(key: 'voucherRefCode');
            Navigator.pop(context, verifyPin);

            // Future.delayed(Duration.zero, () {
            //   Navigator.pop(context, verifyPin);
            // });
          }

          if (state is SecurityOtpSent) {
            setResetProcessingStatus(false);
            showSuccessToast(state.data['message'], context);
            Navigator.of(context).pushNamed(
              OderRoutes.securityOtp,
              arguments: SecurityOtpParameters(otpData: state.data),
            );
          }

          if (state is SecurityNetworkError) {
            setProcessingStatus(false);
            setResetProcessingStatus(false);
            showErrorToast(state.error, context);
          }
          if (state is SecurityError) {
            setProcessingStatus(false);
            setResetProcessingStatus(false);
            enteredPin = '';
            showErrorToast(state.error, context);
          }
        },
        builder: (context, state) {
          // if (state is SecurityProcessing) {
          //   return LoadingWidget();
          // }
          return PasscodeLayout(
            title: 'Enter your passcode',
            message: 'Enter your six-digit passcode to continue.',
            step: null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PasscodeDigits(
                  value: enteredPin,
                  enabled: !isProcessing,
                  onChanged:
                      (value) => setState(() {
                        enteredPin = value;
                        verifyPin = value;
                      }),
                ),
                const SizedBox(height: AppDesign.spaceXxl),
                AccountPrimaryButton(
                  palette: AppDesign.passcode,
                  label: isProcessing ? 'Please wait…' : 'Continue',
                  onPressed:
                      isProcessing || enteredPin.length != 6
                          ? null
                          : _validateAndSend,
                ),
                const SizedBox(height: AppDesign.spaceMd),
                TextButton(
                  onPressed:
                      isProcessing
                          ? null
                          : () => Navigator.of(context).maybePop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppDesign.passcode.action,
                  ),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed:
                      isProcessing || isResetProcessing
                          ? null
                          : () {
                            setResetProcessingStatus(true);
                            BlocProvider.of<SecurityBloc>(
                              context,
                            ).add(SecurityOtpSend());
                          },
                  style: TextButton.styleFrom(
                    foregroundColor: AppDesign.passcode.action,
                  ),
                  child: const Text('Forgot passcode? Reset'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _validateAndSend() {
    if (!mounted || isProcessing) return;
    setState(() {
      fToast = FToast();
      fToast.init(context);
    });

    if (enteredPin.isEmpty) {
      setProcessingStatus(false);
      showErrorToast('Passcode are required!', context);
    } else if (enteredPin.length < 6) {
      setProcessingStatus(false);
      showErrorToast('Passcode must be 6 digit', context);
    } else {
      setProcessingStatus(true);
      // Storage().securityPin = enteredPin;
      BlocProvider.of<SecurityBloc>(
        context,
      ).add(SecurityPinVerify(pin: enteredPin));
    }
  }
}
