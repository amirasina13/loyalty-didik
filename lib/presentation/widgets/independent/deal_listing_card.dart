import 'package:flutter/material.dart';

import '../../../app_setting/app_setting.dart';
import 'cache_network_image.dart';
import 'halal_widget.dart';

/// The shared card language used by Deals, My Vouchers and History.
///
/// The card deliberately accepts already formatted values. API-specific
/// business rules stay in the feature extensions while spacing, typography,
/// image treatment and actions remain consistent across all three lists.
class DealListingCard extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String? description;
  final String? label;
  final String? muslimCategory;
  final bool isMuslim;
  final bool squareLayout;
  final VoidCallback? onTap;
  final Widget? topTrailing;

  /// Optional content rendered directly below the description.
  ///
  /// Deals use this for the price so the purchase action stays focused on the
  /// button in the card footer. Keeping it here also makes the same placement
  /// work in both the price-first and square card layouts.
  final Widget? copyFooter;
  final Widget? footerLeading;
  final Widget? footerTrailing;
  final ColorFilter? imageFilter;
  final PagePalette palette;

  const DealListingCard({
    super.key,
    this.imageUrl,
    this.title,
    this.description,
    this.label,
    this.muslimCategory,
    this.isMuslim = false,
    this.squareLayout = false,
    this.onTap,
    this.topTrailing,
    this.copyFooter,
    this.footerLeading,
    this.footerTrailing,
    this.imageFilter,
    this.palette = AppDesign.deals,
  });

  static const _radius = 16.0;
  static const _imageRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.all(AppDesign.spaceMd),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: palette.border),
      ),
      child:
          squareLayout
              ? _buildSquareCard(context)
              : _buildPriceFirstCard(context),
    );
  }

  Widget _buildPriceFirstCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMainTap(
          context,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArtwork(context, width: 88, height: 88),
              const SizedBox(width: AppDesign.spaceMd),
              Expanded(
                child: _buildCopy(
                  context,
                  titleMaxLines: 2,
                  descriptionMaxLines: 3,
                  copyFooter: copyFooter,
                ),
              ),
              if (topTrailing != null) ...[
                const SizedBox(width: AppDesign.spaceSm),
                topTrailing!,
              ],
            ],
          ),
        ),
        if (footerLeading != null || footerTrailing != null) ...[
          const SizedBox(height: AppDesign.spaceMd),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: AppDesign.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (footerLeading != null) Expanded(child: footerLeading!),
              if (footerLeading == null) const Spacer(),
              if (footerTrailing != null) ...[
                if (footerLeading != null)
                  const SizedBox(width: AppDesign.spaceMd),
                footerTrailing!,
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSquareCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMainTap(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: _buildArtwork(
                  context,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              const SizedBox(height: AppDesign.spaceSm),
              _buildCopy(context, titleMaxLines: 2, descriptionMaxLines: 3),
            ],
          ),
        ),
        if (copyFooter != null ||
            footerLeading != null ||
            footerTrailing != null) ...[
          const Spacer(),
          const SizedBox(height: AppDesign.spaceMd),
          Divider(height: 1, color: palette.border),
          if (copyFooter != null) ...[
            const SizedBox(height: AppDesign.spaceMd),
            copyFooter!,
          ],
          if (footerLeading != null || footerTrailing != null)
            const SizedBox(height: AppDesign.spaceMd),
          if (footerLeading != null || footerTrailing != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (footerLeading != null) Expanded(child: footerLeading!),
                if (footerLeading == null) const Spacer(),
                if (footerTrailing != null) ...[
                  if (footerLeading != null)
                    const SizedBox(width: AppDesign.spaceSm),
                  footerTrailing!,
                ],
              ],
            ),
        ],
      ],
    );
  }

  Widget _buildMainTap(BuildContext context, Widget child) {
    if (onTap == null) return child;

    return Semantics(
      button: true,
      label: 'View ${title?.trim().isEmpty == false ? title : 'voucher'}',
      child: Material(
        color: colorTransparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  Widget _buildArtwork(
    BuildContext context, {
    required double width,
    required double height,
  }) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final artwork =
        hasImage
            ? CachedImage(
              imageUrl: imageUrl!,
              boxFit: BoxFit.cover,
              colorFilter: imageFilter,
            )
            : Image.asset(
              'assets/icons/no_deals.webp',
              fit: BoxFit.contain,
              color: imageFilter == null ? null : colorUsedGray,
              colorBlendMode: imageFilter == null ? null : BlendMode.color,
            );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_imageRadius),
            child: ColoredBox(
              color: colorBlueDidik.withValues(alpha: 0.1),
              child: artwork,
            ),
          ),
          if (label != null && label!.trim().isNotEmpty)
            Positioned(
              left: 7,
              bottom: 7,
              child: _DealLabel(text: label!, palette: palette),
            ),
          if (isMuslim && muslimCategory != null && muslimCategory!.isNotEmpty)
            Positioned(
              right: 5,
              top: 5,
              child: HalalWidget(muslimCategory: muslimCategory!, width: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildCopy(
    BuildContext context, {
    required int titleMaxLines,
    required int descriptionMaxLines,
    Widget? copyFooter,
  }) {
    final titleText = title?.trim() ?? '';
    final descriptionText = description?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titleText.isEmpty ? '—' : titleText,
          maxLines: titleMaxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: palette.text,
            fontFamily: fontFamilyMain,
            fontSize: AppDesign.bodySize,
            fontWeight: FontWeight.w700,
            height: 1.18,
          ),
        ),
        if (descriptionText.isNotEmpty) ...[
          const SizedBox(height: AppDesign.spaceSm),
          Text(
            descriptionText,
            maxLines: descriptionMaxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.muted,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.smallSize,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
        if (copyFooter != null) ...[
          const SizedBox(height: AppDesign.spaceSm),
          copyFooter,
        ],
      ],
    );
  }
}

class _DealLabel extends StatelessWidget {
  final String text;
  final PagePalette palette;

  const _DealLabel({required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: AppDesign.spaceXs,
      ),
      decoration: BoxDecoration(
        color: colorBlueDidik.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: palette.action,
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.captionSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The shared waiting state for favourite actions across deal cards and
/// directory detail pages.
class FavouriteLoadingIcon extends StatelessWidget {
  final Color color;
  final double size;

  const FavouriteLoadingIcon({
    super.key,
    this.color = colorMulberry,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.hourglass_top_rounded, color: color, size: size);
  }
}
