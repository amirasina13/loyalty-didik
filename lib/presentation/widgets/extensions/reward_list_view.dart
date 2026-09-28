import 'package:flutter/material.dart';

import '../../../app_setting/app_setting.dart';
import '../../../data/data.dart';
import '../widgets.dart';

/// Presentation helpers for a reward returned by the Deals endpoint.
///
/// The extension only formats values that already came from the API. It does
/// not invent a price or a description when either value is unavailable.
extension RewardListView on VoucherReward {
  Widget getRewardListTile({
    required BuildContext context,
    required VoidCallback onTap,
    required VoidCallback onFavouriteTap,
    required bool isFavClick,
    bool squareLayout = false,
    bool? favouriteOverride,
  }) {
    final primaryPrice = purchaseText?.trim() ?? '';
    final oldPrice = _oldPrice(faceAmount);
    final soldOut = isSoldOut ?? false;

    return DealListingCard(
      imageUrl: image,
      title: name,
      description: desc,
      // The tab already establishes that these are deals. Type labels such as
      // "purchase" or "downloadable" add noise to the artwork.
      label: null,
      muslimCategory: muslimCategory,
      isMuslim: isMuslim ?? false,
      squareLayout: squareLayout,
      onTap: onTap,
      // In square mode the price belongs under the description so the two
      // column card does not crop it beside the action row. The default
      // price-first list keeps the compact price footer from the prototype.
      copyFooter:
          squareLayout
              ? _PriceSummary(
                value: primaryPrice,
                oldValue: oldPrice,
                compact: true,
              )
              : null,
      footerLeading:
          squareLayout
              ? null
              : _PriceSummary(value: primaryPrice, oldValue: oldPrice),
      footerTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FavouriteButton(
            isFavourite: favouriteOverride ?? isFavourite ?? false,
            isLoading: isFavClick,
            onTap: onFavouriteTap,
          ),
          const SizedBox(width: AppDesign.spaceSm),
          _PrimaryActionButton(
            label: soldOut ? 'Sold out' : 'Buy Now',
            enabled: !soldOut,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

String? _oldPrice(String? value) {
  final trimmed = value?.trim() ?? '';
  final parsed = num.tryParse(trimmed);
  if (parsed == null || parsed <= 0) return null;

  // Keep the server's precision when it provides it, while avoiding a
  // floating point artefact such as 29.9000000001 in the card.
  final formatted =
      parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toStringAsFixed(2);
  return '$formatted Credits';
}

class _PriceSummary extends StatelessWidget {
  final String value;
  final String? oldValue;
  final bool compact;

  const _PriceSummary({
    required this.value,
    this.oldValue,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Price',
          style: TextStyle(
            color: AppDesign.deals.muted,
            fontFamily: fontFamilyMain,
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDesign.spaceXs),
        Text(
          value.isEmpty ? '—' : value,
          maxLines: compact ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppDesign.deals.text,
            fontFamily: fontFamilyMain,
            fontSize: compact ? 13 : 15,
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
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );

    if (!compact) return content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppDesign.spaceSm,
      ),
      decoration: BoxDecoration(
        color: colorBlueDidik.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: content,
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  final bool isFavourite;
  final bool isLoading;
  final VoidCallback onTap;

  const _FavouriteButton({
    required this.isFavourite,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isFavourite ? 'Remove from favourites' : 'Save as favourite',
      child: Material(
        color: AppDesign.deals.background,
        shape: CircleBorder(side: BorderSide(color: AppDesign.deals.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isLoading ? null : onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(
              child:
                  isLoading
                      ? FavouriteLoadingIcon(
                        color: AppDesign.deals.action,
                        size: 20,
                      )
                      : Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        size: 21,
                        color:
                            isFavourite
                                ? AppDesign.deals.favButton
                                : AppDesign.deals.muted,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _PrimaryActionButton({
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
          borderRadius: BorderRadius.circular(22),
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 80, minHeight: 42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
