import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../widgets/widgets.dart';
import '../delete_acc.dart';

class ReasonView extends StatefulWidget {
  final Function changeView;

  const ReasonView({super.key, required this.changeView});

  @override
  State<ReasonView> createState() => _ReasonViewState();
}

class _ReasonViewState extends State<ReasonView> {
  String errorfield = '';
  bool isProcessing = false;
  String _result = '';
  late FocusNode validateFocus;
  final TextEditingController otherTextController = TextEditingController();
  final GlobalKey<OderInputFieldState> otherTextKey = GlobalKey();
  final otherFocus = FocusNode();

  List reasonDelete = [
    'No longer using the service/ platform',
    'Privacy concerns',
    'Difficulty navigating the platform',
    'Account security concerns',
    'Personal reasons',
    'Others',
  ];

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();

    validateFocus = FocusNode();
  }

  @override
  void dispose() {
    otherTextController.dispose();

    // Clean up the focus node when the Form is disposed.
    validateFocus.dispose();
    otherFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const p = AppDesign.deleteAccount;
    return BlocConsumer<DeleteAccBloc, DeleteAccState>(
      listener: (context, state) {
        if (state is AccReasonDeleted) {
          setProcessingStatus(false);
          Navigator.of(context).pushNamed(OderRoutes.deleteMobbile);
        }
        if (state is DeleteAccError) {
          setProcessingStatus(false);
          showErrorToast(state.error, context);
        }
        if (state is VerifyNetworkError) {
          setProcessingStatus(false);
          showErrorToast('No internet connection. Please try again.', context);
        }
      },
      builder:
          (context, state) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDesign.spaceXl,
              AppDesign.spaceMd,
              AppDesign.spaceXl,
              AppDesign.spaceXl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why are you leaving?',
                  style: TextStyle(
                    fontSize: AppDesign.headingSize,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: AppDesign.spaceMd),
                Text(
                  'Select a reason to continue. You will review the details before confirming deletion.',
                  style: TextStyle(
                    fontSize: AppDesign.bodySize,
                    height: 1.7,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: AppDesign.formFieldGap),
                for (final String reason in reasonDelete)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDesign.spaceMd),
                    child: Material(
                      color: p.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDesign.cardRadius,
                        ),
                        side: BorderSide(
                          color: _result == reason ? p.action : p.border,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppDesign.cardRadius,
                        ),
                        onTap:
                            isProcessing
                                ? null
                                : () => setState(() => _result = reason),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDesign.spaceLg,
                            vertical: AppDesign.spaceLg,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  reason,
                                  style: TextStyle(
                                    fontSize: AppDesign.bodySize,
                                    color: p.text,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDesign.spaceMd),
                              Icon(
                                _result == reason
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: _result == reason ? p.action : p.border,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_result == 'Others')
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppDesign.spaceMd,
                      bottom: AppDesign.spaceMd,
                    ),
                    child: OderInputField(
                      palette: p,
                      label: 'Your reason',
                      controller: otherTextController,
                      focusNode: otherFocus,
                      maxLines: 3,
                      keyboard: TextInputType.multiline,
                    ),
                  ),
                const SizedBox(height: AppDesign.spaceMd),
                AccountPrimaryButton(
                  label: isProcessing ? 'Processing…' : 'Continue',
                  palette: p,
                  onPressed: isProcessing ? null : _validateAndSend,
                ),
                const SizedBox(height: AppDesign.spaceSm),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: p.action),
                    onPressed:
                        isProcessing ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _validateAndSend() {
    fToast = FToast();
    fToast.init(context);

    if (_result.isEmpty) {
      setProcessingStatus(false);
      // validateFocus.requestFocus();
      // ErrorIconDialog.showErrorDialog(context, 'Please select your reason');
      showErrorToast('Please select your reason', context);
    } else if (_result == 'Others' && otherTextController.text.isEmpty) {
      setProcessingStatus(false);
      otherFocus.requestFocus();
      // ErrorIconDialog.showErrorDialog(context, 'Please share us your reason');
      showErrorToast('Please share us your reason', context);
    } else {
      setProcessingStatus(true);
      BlocProvider.of<DeleteAccBloc>(context).add(
        DeleteAccReason(
          reason: _result == 'Others' ? otherTextController.text : _result,
        ),
      );
    }
  }
}
