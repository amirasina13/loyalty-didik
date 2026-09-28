import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../voucher.dart';

class VoucherFeedbackView extends StatefulWidget {
  final Function? changeView;
  final String voucherId;

  const VoucherFeedbackView({
    super.key,
    this.changeView,
    required this.voucherId,
  });

  @override
  State<VoucherFeedbackView> createState() => _VoucherFeedbackViewState();
}

class _VoucherFeedbackViewState extends State<VoucherFeedbackView> {
  bool isProcessing = false;
  bool _hydrated = false;
  int initialRating = 0, finalRating = 0;
  String initialValue = '';
  VoucherPastDetails? pastDetail;
  final TextEditingController ratingTextController = TextEditingController();

  void setProcessingStatus(bool processing) {
    if (!mounted) return;
    setState(() => isProcessing = processing);
  }

  @override
  void dispose() {
    ratingTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _returnToHistory();
      },
      child: OderScaffold(
        title: Text(
          'Feedback',
          style: TextStyle(
            fontFamily: fontFamilyMain,
            color: AppDesign.history.text,
            fontWeight: FontWeight.w700,
            fontSize: AppDesign.appBarTitleSize,
          ),
        ),
        appBarColor: AppDesign.history.background,
        background: AppDesign.history.background,
        bottomMenuIndex: 3,
        body: BlocConsumer<VoucherBloc, VoucherState>(
          listener: (context, state) {
            if (state is VoucherRatingSuccess) {
              showSuccessToast(state.ratingResponse['message'], context);
              Navigator.of(context).pushNamedAndRemoveUntil(
                OderRoutes.voucher,
                (route) => false,
                arguments: const VoucherParameters(
                  selectedTab: 2,
                  filterBy: 'all',
                  filterValue: '1',
                ),
              );
            }
            if (state is VoucherRatingFailed) {
              setProcessingStatus(false);
              showErrorToast(state.ratingResponse['message'], context);
            }
            if (state is VoucherError) {
              setProcessingStatus(false);
              showErrorToast(state.error, context);
            }
          },
          builder: (context, state) {
            if (state is VoucherPastDetailsLoaded) {
              final loaded = state.pastDetails;
              if (!_hydrated || pastDetail?.id != loaded.id) {
                pastDetail = loaded;
                initialValue = loaded.comment ?? '';
                initialRating = loaded.rating ?? 0;
                finalRating = initialRating;
                ratingTextController.text = initialValue;
                _hydrated = true;
              }
            }

            final detail = pastDetail;
            if (detail == null) return LoadingWidget();
            return _buildFeedback(context, detail);
          },
        ),
      ),
    );
  }

  Widget _buildFeedback(BuildContext context, VoucherPastDetails detail) {
    final palette = AppDesign.history;
    final hasFeedback = initialRating > 0 && initialValue.trim().isNotEmpty;
    final image = detail.image?.trim() ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDesign.spaceXl,
          20,
          AppDesign.spaceXl,
          36,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 156,
                height: 156,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colorBlueDidik.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDesign.cardRadius),
                ),
                child:
                    image.isEmpty
                        ? Icon(
                          Icons.confirmation_num_outlined,
                          size: 52,
                          color: palette.muted,
                        )
                        : CachedImage(imageUrl: image),
              ),
            ),
            const SizedBox(height: AppDesign.spaceXl),
            Text(
              detail.name ?? 'Voucher feedback',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.text,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.sectionTitleSize,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDesign.spaceXl),
            Text(
              hasFeedback
                  ? 'Thank you for your feedback!'
                  : 'Rate your experience',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.text,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.titleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!hasFeedback) ...[
              const SizedBox(height: AppDesign.spaceSm),
              Text(
                'Are you satisfied with the service?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.muted,
                  fontFamily: fontFamilyMain,
                  fontSize: AppDesign.bodySize,
                ),
              ),
            ],
            const SizedBox(height: AppDesign.spaceLg),
            Center(
              child: RatingBar.builder(
                itemSize: 40,
                initialRating: initialRating.toDouble(),
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                ignoreGestures: hasFeedback || isProcessing,
                unratedColor: palette.border,
                glow: false,
                itemCount: 5,
                itemBuilder:
                    (context, _) =>
                        Icon(Icons.star_rounded, color: colorYellowIndicator),
                onRatingUpdate:
                    (rating) => setState(() => finalRating = rating.toInt()),
              ),
            ),
            const SizedBox(height: AppDesign.spaceXl),
            TextFormField(
              controller: ratingTextController,
              readOnly: hasFeedback || isProcessing,
              minLines: 5,
              maxLines: 7,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                color: palette.text,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.bodySize,
                height: 1.45,
              ),
              decoration: outlinedAccountField(
                const InputDecoration(
                  labelText: 'Your feedback',
                  hintText: 'Tell us about your experience',
                  alignLabelWithHint: true,
                ),
                palette,
              ),
            ),
            const SizedBox(height: AppDesign.spaceXl),
            AccountPrimaryButton(
              palette: palette,
              label:
                  hasFeedback
                      ? 'Submitted'
                      : isProcessing
                      ? 'Submitting…'
                      : 'Submit feedback',
              onPressed: hasFeedback || isProcessing ? null : _validateAndSend,
            ),
            const SizedBox(height: AppDesign.spaceSm),
            TextButton(
              onPressed: isProcessing ? null : _returnToHistory,
              style: TextButton.styleFrom(foregroundColor: palette.action),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _returnToHistory() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pushNamedAndRemoveUntil(
      OderRoutes.voucher,
      (route) => true,
      arguments: const VoucherParameters(
        selectedTab: 2,
        filterBy: 'all',
        filterValue: '1',
      ),
    );
  }

  void _validateAndSend() {
    if (isProcessing) return;
    if (finalRating == 0) {
      showErrorToast(
        'Kindly rate your experience with at least 1 star.',
        context,
      );
      return;
    }
    if (ratingTextController.text.trim().isEmpty) {
      showErrorToast('Please tell us about your experience.', context);
      return;
    }
    setProcessingStatus(true);
    BlocProvider.of<VoucherBloc>(context).add(
      VoucherRating(
        id: widget.voucherId,
        rating: finalRating,
        comment: ratingTextController.text.trim(),
      ),
    );
  }
}
