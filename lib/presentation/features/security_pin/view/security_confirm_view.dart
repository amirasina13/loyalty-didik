import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../widgets/widgets.dart';
import '../../rewards/reward.dart';
import '../../voucher/voucher.dart';
import '../security_pin.dart';

class SecurityConfirmView extends StatefulWidget {
  final Function changeView;
  const SecurityConfirmView({super.key, required this.changeView});

  @override
  State<SecurityConfirmView> createState() => _SecurityConfirmViewState();
}

class _SecurityConfirmViewState extends State<SecurityConfirmView> {
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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: BlocConsumer<SecurityBloc, SecurityState>(
        listener: (context, state) {
          if (state is SecurityPinCreated) {
            setProcessingStatus(false);
            SuccessTimerDialog.showSuccessTimerDialog(
              context,
              state.data['message'],
              () {
                if (Storage().page == 'reward_details') {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    OderRoutes.rewardDetails,
                    (Route<dynamic> route) => false,
                    arguments: RewardDetailsParameters(
                      rewardId: Storage().rewardId,
                      title: Storage().titlePasscodeRoute!,
                      indexPage: 3,
                    ),
                  );
                } else if (Storage().page == 'voucher_details') {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    OderRoutes.voucherDesc,
                    (Route<dynamic> route) => false,
                    arguments: VoucherDescParameters(
                      voucherId: Storage().voucherId,
                      title: Storage().titlePasscodeRoute!,
                    ),
                  );
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    OderRoutes.wallet,
                    (Route<dynamic> route) => false,
                  );
                }
              },
            );
          }

          if (state is SecurityNetworkError) {
            setProcessingStatus(false);
            showErrorToast(state.error, context);
          }
          if (state is SecurityError) {
            setProcessingStatus(false);
            enteredPin = '';
            pinController.clear();
            showErrorToast(state.error, context);
          }
        },
        builder: (context, state) {
          return VerificationCodeLayout(
            isEmail: false,
            recipient: '',
            header: 'Passcode',
            heading: 'Confirm your passcode',
            message: 'Enter the same six-digit passcode again.',
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
    } else if (enteredPin != Storage().securityPin) {
      setProcessingStatus(false);
      showErrorToast('Passcode not match!', context);
      enteredPin = '';
      pinController.clear();
    } else {
      setProcessingStatus(true);
      // Storage().securityPin = enteredPin;
      // widget.changeView(changeType: ViewChangeType.Forward);
      BlocProvider.of<SecurityBloc>(
        context,
      ).add(SecurityCreatePin(pin: enteredPin));
      // print('ENTERED PIN: $enteredPin');
    }
  }
}
