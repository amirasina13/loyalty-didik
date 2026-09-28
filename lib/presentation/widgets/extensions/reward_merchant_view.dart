import 'package:flutter/material.dart';

import '../../../app_setting/app_setting.dart';
import '../../../data/data.dart';
import '../widgets.dart';

/// Builds a merchant's deals with the same card language as the main Deals tab.
extension RewardMerchantView on RewardMerchant {
  Widget getRewardMerchantTile({
    required BuildContext context,
    required VoidCallback onTap,
    required VoidCallback onFavouriteTap,
    required bool isFavClick,
  }) {
    final primaryPrice = purchaseText?.trim() ?? '';
    final oldPrice = _oldPrice(faceAmount);
    final soldOut = isSoldOut ?? false;

    return DealListingCard(
      imageUrl: image,
      title: name,
      description: desc,
      label: null,
      muslimCategory: muslimCategory,
      isMuslim: isMuslim ?? false,
      onTap: onTap,
      footerLeading: _MerchantPriceSummary(
        value: primaryPrice,
        oldValue: oldPrice,
      ),
      footerTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label:
                isFavourite == true
                    ? 'Remove from favourites'
                    : 'Save as favourite',
            child: Material(
              color: AppDesign.deals.background,
              shape: CircleBorder(
                side: BorderSide(color: AppDesign.deals.border),
              ),
              child: InkWell(
                onTap: isFavClick ? null : onFavouriteTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(
                    child:
                        isFavClick
                            ? FavouriteLoadingIcon(
                              color: AppDesign.deals.action,
                              size: 20,
                            )
                            : Icon(
                              isFavourite == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 21,
                              color:
                                  isFavourite == true
                                      ? AppDesign.deals.action
                                      : AppDesign.deals.muted,
                            ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDesign.spaceSm),
          Semantics(
            button: true,
            label: soldOut ? 'Sold out' : 'Buy Now',
            child: Material(
              color: soldOut ? AppDesign.deals.border : colorGoldButton,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: soldOut ? null : onTap,
                borderRadius: BorderRadius.circular(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 82,
                    minHeight: 42,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: Text(
                        soldOut ? 'Sold out' : 'Buy Now',
                        style: TextStyle(
                          color:
                              soldOut ? AppDesign.deals.muted : colorBlackText,
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
          ),
        ],
      ),
    );
  }
}

String? _oldPrice(String? value) {
  final parsed = num.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed <= 0) return null;
  final formatted =
      parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toStringAsFixed(2);
  return '$formatted Credits';
}

class _MerchantPriceSummary extends StatelessWidget {
  final String value;
  final String? oldValue;

  const _MerchantPriceSummary({required this.value, this.oldValue});

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
