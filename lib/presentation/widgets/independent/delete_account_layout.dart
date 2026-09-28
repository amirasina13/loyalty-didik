import 'package:flutter/material.dart';
import '../../../app_setting/app_setting.dart';

class DeletionNotice extends StatelessWidget {
  const DeletionNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppDesign.deleteWarningBackground,
      borderRadius: BorderRadius.circular(AppDesign.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, color: AppDesign.deleteDanger),
        const SizedBox(height: AppDesign.spaceMd),
        Text(
          'Before you delete your account',
          style: TextStyle(
            fontSize: AppDesign.bodyLargeSize,
            fontWeight: FontWeight.w700,
            color: AppDesign.deleteDanger,
          ),
        ),
        const SizedBox(height: AppDesign.spaceMd),
        Text(
          'This email will be unavailable for new registration for one year.\n\nAll unspent $appName vouchers will be forfeited.\n\nThis action cannot be undone.',
          style: TextStyle(
            fontSize: AppDesign.bodySize,
            height: 1.7,
            color: AppDesign.deleteAccount.text,
          ),
        ),
      ],
    ),
  );
}

class DeleteConfirmationDialog extends StatefulWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.email,
    required this.onConfirm,
  });
  final String email;
  final VoidCallback onConfirm;
  @override
  State<DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  bool submitting = false;
  @override
  Widget build(BuildContext context) {
    const p = AppDesign.deleteAccount;
    return PopScope(
      canPop: !submitting,
      child: AlertDialog(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.sheetRadius),
        ),
        title: Text(
          'Delete your account?',
          style: TextStyle(
            color: p.text,
            fontSize: AppDesign.appBarTitleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to permanently delete the account associated with:',
                style: TextStyle(color: p.muted, height: 1.6),
              ),
              const SizedBox(height: AppDesign.spaceMd),
              Text(
                widget.email,
                style: TextStyle(color: p.text, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppDesign.spaceLg),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: AppDesign.deleteDanger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDesign.spaceXl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesign.deleteDanger,
                    foregroundColor: p.onAction,
                    minimumSize: const Size.fromHeight(
                      AppDesign.setupButtonHeight,
                    ),
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  onPressed:
                      submitting
                          ? null
                          : () {
                            setState(() => submitting = true);
                            widget.onConfirm();
                          },
                  child: Text(submitting ? 'Deleting…' : 'Delete account'),
                ),
              ),
              const SizedBox(height: AppDesign.spaceSm),
              Center(
                child: TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: p.action),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
