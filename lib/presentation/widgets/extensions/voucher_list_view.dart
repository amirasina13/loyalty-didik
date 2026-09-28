import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_setting/app_setting.dart';
import '../../../data/data.dart';
import '../widgets.dart';

/// Shared price-first presentation for a voucher owned by the member.
extension VoucherListView on Voucher {
  Widget getVoucherListTile({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final quantityText = quantity == null ? '—' : 'x$quantity';

    return DealListingCard(
      imageUrl: image,
      title: name,
      description: desc,
      label: null,
      muslimCategory: muslimCategory,
      isMuslim: isMuslim ?? false,
      onTap: onTap,
      footerLeading: _VoucherMeta(
        date: _formatDate(expired),
        quantity: quantityText,
      ),
      footerTrailing: _VoucherActionButton(onTap: onTap),
    );
  }
}

String? _formatDate(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return DateFormat(appDateFormat).format(parsed);
}

class _VoucherMeta extends StatelessWidget {
  final String? date;
  final String quantity;

  const _VoucherMeta({required this.date, required this.quantity});

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: AppDesign.deals.muted,
      fontFamily: fontFamilyMain,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );
    final valueStyle = TextStyle(
      color: AppDesign.deals.text,
      fontFamily: fontFamilyMain,
      fontSize: AppDesign.captionSize,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VoucherMetaItem(
          label: 'Valid until',
          value: date ?? '—',
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        const SizedBox(width: AppDesign.spaceLg),
        _VoucherMetaItem(
          label: 'Quantity',
          value: quantity,
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
      ],
    );
  }
}

class _VoucherMetaItem extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _VoucherMetaItem({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 55, maxWidth: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
        ],
      ),
    );
  }
}

class _VoucherActionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _VoucherActionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Redeem Now',
      child: Material(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDesign.spaceLg,
              vertical: AppDesign.spaceMd,
            ),
            child: Text(
              'Redeem Now',
              style: TextStyle(
                color: colorWhite,
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
