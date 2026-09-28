import 'package:flutter/material.dart';

import '../../../app_setting/app_setting.dart';
import '../../../data/data.dart';
import '../widgets.dart';

/* Extension class for voucher list(based on outlet). Will use in features/outlet/view/outlets_details.dart  */
extension View on VoucherOutlet {
  Widget getOutletVoucherTile({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final soldOut = isSoldOut ?? false;
    final oldPrice = _outletOldPrice(faceAmount);
    return DealListingCard(
      imageUrl: image,
      title: name,
      description: desc,
      label: null,
      muslimCategory: muslimCategory,
      isMuslim: isMuslim ?? false,
      onTap: onTap,
      footerLeading: _OutletVoucherPrice(
        value: purchaseText?.trim() ?? '',
        oldValue: oldPrice,
      ),
      footerTrailing: _OutletVoucherBuyButton(
        label: soldOut ? 'Sold out' : 'Buy Now',
        enabled: !soldOut,
        onTap: onTap,
      ),
    );
  }
}

String? _outletOldPrice(String? value) {
  final parsed = num.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed <= 0) return null;
  final formatted =
      parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toStringAsFixed(2);
  return '$formatted Credits';
}

class _OutletVoucherPrice extends StatelessWidget {
  final String value;
  final String? oldValue;

  const _OutletVoucherPrice({required this.value, this.oldValue});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Price',
          style: TextStyle(
            color: AppDesign.deals.muted,
            fontFamily: fontFamilyMain,
            fontSize: AppDesign.smallSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDesign.spaceXs),
        Text(
          value.isEmpty ? '—' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppDesign.deals.text,
            fontFamily: fontFamilyMain,
            fontSize: AppDesign.bodySize,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        if (oldValue != null) ...[
          const SizedBox(height: 3),
          Text(
            oldValue!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppDesign.deals.muted,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.captionSize,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}

class _OutletVoucherBuyButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _OutletVoucherBuyButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: enabled ? secondaryColor : AppDesign.deals.border,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 82, minHeight: 42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: enabled ? colorWhite : AppDesign.deals.muted,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.smallSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
