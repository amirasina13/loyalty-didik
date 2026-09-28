import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_setting/app_setting.dart';
import '../../../data/data.dart';
import '../widgets.dart';

/// Shared price-first presentation for a past voucher in History.
extension VoucherPastListView on VoucherPast {
  Widget getVoucherPastTile({
    required BuildContext context,
    required VoidCallback onTap,
    required VoidCallback ontapRate,
    required bool past,
  }) {
    final date = _historyDate(expiredAt);
    final dateLabel =
        expiredAt?.trim().isNotEmpty == true && isExpired!
            ? 'Expired at'
            : 'Expiry date';
    final hasRating =
        (rating ?? 0) > 0 && (comment?.trim().isNotEmpty ?? false);
    final isRateDisabled = hasRating;

    return DealListingCard(
      imageUrl: image,
      title: name,
      description: desc,
      label: null,
      isMuslim: false,
      imageFilter:
          (isExpired ?? false)
              ? ColorFilter.mode(colorUsedGray, BlendMode.color)
              : null,
      palette: AppDesign.history,
      onTap: isExpired! ? null : onTap,
      footerLeading: _HistoryDate(label: dateLabel, value: date ?? '—'),
      footerTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isExpired!
              ? SizedBox.shrink()
              : _HistoryActionButton(
                label: 'View',
                onTap: onTap,
                filled: false,
              ),
          const SizedBox(width: AppDesign.spaceSm),
          _HistoryActionButton(
            label:
                isExpired!
                    ? 'Expired'
                    : hasRating
                    ? 'Rated'
                    : 'Rate',
            onTap:
                isExpired!
                    ? null
                    : isRateDisabled
                    ? null
                    : ontapRate,
            filled: isExpired! ? true : hasRating,
          ),
        ],
      ),
    );
  }
}

String? _historyDate(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return DateFormat(appDateFormat).format(parsed);
}

class _HistoryDate extends StatelessWidget {
  final String label;
  final String value;

  const _HistoryDate({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 70, maxWidth: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppDesign.history.muted,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.captionSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDesign.spaceXs),
          Text(
            value,
            textAlign: TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppDesign.history.text,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.captionSize,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  const _HistoryActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color:
            filled
                ? (enabled
                    ? AppDesign.history.action
                    : AppDesign.history.border)
                : AppDesign.history.background,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 74, minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: AppDesign.spaceMd),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color:
                    filled && enabled
                        ? AppDesign.history.action
                        : AppDesign.history.border,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    filled && enabled
                        ? AppDesign.history.onAction
                        : AppDesign.history.text,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.smallSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
