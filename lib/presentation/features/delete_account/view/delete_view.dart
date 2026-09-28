import '../../../widgets/independent/delete_account_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../domain/domain.dart';
import '../../../widgets/widgets.dart';
import '../../authentication/authentication.dart';
import '../../maintenance/maintenance_screen.dart';
import '../delete_acc.dart';

class DeleteMobileView extends StatefulWidget {
  final Function changeView;

  // ignore: use_key_in_widget_constructors
  const DeleteMobileView({Key? key, required this.changeView}) : super();

  @override
  State<DeleteMobileView> createState() => _DeleteMobileViewState();
}

class _DeleteMobileViewState extends State<DeleteMobileView> {
  // String selectedCode = '60';
  bool error = false;
  bool isProcessing = false;
  String errorfield = '', errorTextEmail = '';
  List<String> getCode = [];
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<OderInputFieldState> emailKey = GlobalKey();

  late FocusNode emailFocus;
  final MyConnectivity _connectivity = MyConnectivity.instance;

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();

    emailFocus = FocusNode();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    emailFocus.dispose();
    emailController.dispose();

    _connectivity.disposeStream();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const p = AppDesign.deleteAccount;
    return BlocConsumer<DeleteAccBloc, DeleteAccState>(
      listener: (context, state) async {
        if (state is DeleteAccSent) {
          setProcessingStatus(false);

          try {
            // Await secure storage wipe completely before proceeding
            await Storage().secureStorage.deleteAll();
          } catch (e) {
            if (!context.mounted) return;
            // Handle or log secure storage wipe exceptions safely
            showErrorToast(
              'Failed to clear secure storage during account deletion',
              context,
            );
          }

          if (!context.mounted) return;

          // Notify central AuthenticationBloc to reset in-memory state & storage
          BlocProvider.of<AuthenticationBloc>(
            context,
          ).add(AuthenticationLoggedOut());

          showSuccessToast(state.message, context);
          Navigator.of(context).pushNamedAndRemoveUntil(
            OderRoutes.login,
            (Route<dynamic> route) => false,
          );
        }
        // on failure show a error dialog
        if (state is DeleteAccError) {
          setProcessingStatus(false);
          // ignore: unnecessary_null_comparison
          state.error != null ? error = true : error = false;
          setProcessingStatus(false);

          // ErrorIconDialog.showErrorDialog(context, state.error);
          showErrorToast(state.error, context);
          Navigator.pop(context);
        }
        if (state is VerifyNetworkError) {
          setProcessingStatus(false);
          Navigator.pop(context);
          showErrorToast('No internet connection. Please try again.', context);
        }
        if (state is DeleteAccMaintenanceError) {
          setProcessingStatus(false);

          Navigator.pushAndRemoveUntil<void>(
            context,
            MaterialPageRoute<void>(
              builder:
                  (context) => MaintenanceScreen(
                    parameters: MaintenanceParameters(message: state.message),
                  ),
            ),
            ModalRoute.withName('/'),
          );
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
                  'Review account deletion',
                  style: TextStyle(
                    fontSize: AppDesign.headingSize,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: AppDesign.spaceMd),
                Text(
                  'Enter your account email address to continue.',
                  style: TextStyle(
                    fontSize: AppDesign.bodySize,
                    height: 1.7,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: AppDesign.formFieldGap),
                OderInputField(
                  palette: p,
                  label: 'Email Address',
                  key: emailKey,
                  controller: emailController,
                  validator: Validator.valueExists,
                  keyboard: TextInputType.emailAddress,
                  focusNode: emailFocus,
                  onValueChanged:
                      (value) => setState(() {
                        errorfield = '';
                        error = false;
                      }),
                ),
                const SizedBox(height: AppDesign.formFieldGap),
                const DeletionNotice(),
                const SizedBox(height: AppDesign.formFieldGap),
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

    if (emailKey.currentState?.validate() != null) {
      setProcessingStatus(false);
      errorfield = 'errorEmail';
      emailFocus.requestFocus();
      errorTextEmail = 'The email address is required!';
      showErrorToast(errorTextEmail, context);
      // showErrorToast('Please enter valid email address!', context);
    } else {
      errorfield = '';
      // setProcessingStatus(true);

      FocusScope.of(context).unfocus();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => DeleteConfirmationDialog(
              email: emailController.text,
              onConfirm: _confirmDeleteAccount,
            ),
      );
    }
  }

  void _confirmDeleteAccount() {
    if (isProcessing) return;
    setProcessingStatus(true);

    BlocProvider.of<DeleteAccBloc>(
      context,
    ).add(DeleteAccSend(email: emailController.text));
  }
}
