import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../widgets/widgets.dart';

class SecuritySetView extends StatefulWidget {
  final Function changeView;
  const SecuritySetView({super.key, required this.changeView});

  @override
  State<SecuritySetView> createState() => _SecuritySetViewState();
}

class _SecuritySetViewState extends State<SecuritySetView> {
  bool isProcessing = false;
  String enteredPin = '';
  final pinController = TextEditingController();

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VerificationCodeLayout(
      isEmail: false,
      recipient: '',
      header: 'Passcode',
      heading:
          Storage().set == 'reset' ? 'Set a new passcode' : 'Set your passcode',
      message: 'Choose a six-digit passcode for your transactions.',
      icon: Icons.lock_outline,
      palette: AppDesign.passcode,
      secondaryLabel: 'Cancel',
      primaryLabel: 'Continue',
      processing: isProcessing,
      complete: enteredPin.length == 6,
      codeInput: VerificationCodeInput(
        controller: pinController,
        obscure: true,
        processing: isProcessing,
        error: false,
        palette: AppDesign.passcode,
        onChanged:
            (value) => setState(() {
              enteredPin = value;
            }),
      ),
      resendControl: const SizedBox(height: AppDesign.spaceMd),
      onConfirm: _validateAndSend,
      onEdit: () => Navigator.of(context).maybePop(),
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
      // setProcessingStatus(true);
      Storage().securityPin = enteredPin;
      Navigator.of(context).pushNamed(OderRoutes.securityConfirm);
      // BlocProvider.of<SecurityBloc>(context).add(
      //   SecurityCreatePin(
      //     pin: confirmPinController.text,
      //   ),
      // );
      // print('ENTERED PIN: $enteredPin');
    }
  }
}
