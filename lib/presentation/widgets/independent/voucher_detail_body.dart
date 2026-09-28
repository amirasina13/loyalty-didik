import 'package:flutter/material.dart';

import '../../../app_setting/app_setting.dart';
import 'cache_network_image.dart';
import 'halal_widget.dart';

class VoucherDetailFact {
  final String label;
  final String value;
  final IconData icon;

  const VoucherDetailFact({
    required this.label,
    required this.value,
    this.icon = Icons.info_outline,
  });
}

class VoucherDetailSection {
  final String title;
  final Widget content;
  final bool initiallyExpanded;

  const VoucherDetailSection({
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
  });
}

/// Shared detail hierarchy for catalogue vouchers, owned vouchers and
/// History. Feature pages provide the server-backed actions and content.
class VoucherDetailBody extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String? label;
  final String? muslimCategory;
  final bool isMuslim;
  final List<VoucherDetailFact> facts;
  final List<VoucherDetailSection> sections;
  final String? paymentSummary;
  final String? paymentSubtext;
  final String? couponCode;
  final bool isFavourite;
  final bool favouriteLoading;
  final VoidCallback? onFavourite;
  final VoidCallback? onShare;
  final Widget? bottomAction;
  final PagePalette palette;

  const VoucherDetailBody({
    super.key,
    required this.title,
    this.imageUrl,
    this.label,
    this.muslimCategory,
    this.isMuslim = false,
    this.facts = const [],
    this.sections = const [],
    this.paymentSummary,
    this.paymentSubtext,
    this.couponCode,
    this.isFavourite = false,
    this.favouriteLoading = false,
    this.onFavourite,
    this.onShare,
    this.bottomAction,
    this.palette = AppDesign.voucherDetails,
  });

  @override
  Widget build(BuildContext context) {
    final hasBottomAction =
        bottomAction != null || onFavourite != null || onShare != null;
    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        hasBottomAction ? 160 + MediaQuery.paddingOf(context).bottom : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildArtwork(),
          const SizedBox(height: AppDesign.spaceLg),
          _buildTitleRow(),
          if (paymentSummary != null) ...[
            const SizedBox(height: AppDesign.spaceLg),
            _buildPaymentSummary(),
          ],
          if (facts.isNotEmpty) ...[
            const SizedBox(height: AppDesign.spaceLg),
            _buildFacts(),
          ],
          if (sections.isNotEmpty) ...[
            const SizedBox(height: AppDesign.spaceLg),
            ...sections.map((section) => _buildSection(context, section)),
          ],
          if (couponCode != null) ...[
            const SizedBox(height: AppDesign.spaceLg),
            _buildCoupon(),
          ],
        ],
      ),
    );

    if (!hasBottomAction) {
      return content;
    }

    return Stack(
      children: [
        content,
        if (bottomAction != null || onFavourite != null || onShare != null)
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomAction()),
      ],
    );
  }

  Widget _buildArtwork() {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child:
                hasImage
                    ? CachedImage(imageUrl: imageUrl!, boxFit: BoxFit.cover)
                    : ColoredBox(
                      color: colorBlueDidik.withValues(alpha: 0.1),
                      child: Image.asset(
                        'assets/icons/no_deals.webp',
                        fit: BoxFit.contain,
                      ),
                    ),
          ),
          if (isMuslim && muslimCategory != null && muslimCategory!.isNotEmpty)
            Positioned(
              right: 10,
              top: 10,
              child: HalalWidget(muslimCategory: muslimCategory!, width: 34),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null && label!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDesign.spaceSm),
                  child: _DetailLabel(text: label!, palette: palette),
                ),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.text,
                  fontFamily: fontFamilyMain,
                  fontSize: AppDesign.titleSize,
                  fontWeight: FontWeight.w700,
                  height: 1.18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    final actionChildren = <Widget>[];

    if (onFavourite != null) {
      actionChildren.add(
        _DetailIconButton(
          icon:
              favouriteLoading
                  ? Icons.hourglass_top_rounded
                  : (isFavourite ? Icons.favorite : Icons.favorite_border),
          label: isFavourite ? 'Remove from favourites' : 'Save as favourite',
          color: isFavourite ? palette.favButton : palette.muted,
          onTap: favouriteLoading ? null : onFavourite,
          palette: palette,
        ),
      );
    }

    if (onShare != null) {
      if (actionChildren.isNotEmpty) {
        actionChildren.add(const SizedBox(width: AppDesign.spaceSm));
      }
      actionChildren.add(
        _DetailIconButton(
          icon: Icons.share_outlined,
          label: 'Share voucher',
          color: palette.text,
          onTap: onShare,
          palette: palette,
        ),
      );
    }

    if (bottomAction != null) {
      if (actionChildren.isNotEmpty) {
        actionChildren.add(const SizedBox(width: AppDesign.spaceSm));
      }
      actionChildren.add(Expanded(child: bottomAction!));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDesign.spaceLg,
        10,
        AppDesign.spaceLg,
        AppDesign.spaceMd,
      ),
      decoration: BoxDecoration(
        color: palette.background.withValues(alpha: 0.97),
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Row(children: actionChildren),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDesign.spaceLg,
        AppDesign.spaceLg,
        AppDesign.spaceLg,
        AppDesign.spaceLg,
      ),
      decoration: BoxDecoration(
        // color: colorBlueDidik.withValues(alpha: 0.1),
        color: mainColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment',
            style: TextStyle(
              color: palette.background,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.smallSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDesign.spaceXs),
          Text(
            paymentSummary!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.background,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.sectionTitleSize,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          if (paymentSubtext != null && paymentSubtext!.trim().isNotEmpty) ...[
            const SizedBox(height: AppDesign.spaceXs),
            Text(
              paymentSubtext!,
              style: TextStyle(
                color: palette.background,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.smallSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFacts() {
    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < facts.length; i++) ...[
            _FactRow(fact: facts[i], palette: palette),
            if (i != facts.length - 1)
              Divider(height: 1, color: palette.border),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, VoucherDetailSection section) {
    return Container(
      margin: const EdgeInsets.only(top: AppDesign.spaceSm),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: colorBlueDidik.withValues(alpha: 0.1),
          highlightColor: colorBlueDidik.withValues(alpha: 0.1),
        ),
        child: ExpansionTile(
          initiallyExpanded: section.initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(
            0,
            0,
            0,
            AppDesign.spaceLg,
          ),
          iconColor: palette.action,
          collapsedIconColor: palette.muted,
          title: Text(
            section.title,
            style: TextStyle(
              color: palette.text,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.bodySize,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [section.content],
        ),
      ),
    );
  }

  Widget _buildCoupon() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.contentPadding),
      decoration: BoxDecoration(
        color: colorBlueDidik.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.spaceMd,
              vertical: AppDesign.spaceLg,
            ),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.text, width: 1.5),
            ),
            child: Text(
              couponCode!.trim().isEmpty ? '—' : couponCode!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.text,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.bodySize,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: AppDesign.spaceMd),
          Text(
            'This coupon code is for single use only.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.muted,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.smallSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  final String text;
  final PagePalette palette;

  const _DetailLabel({required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorBlueDidik.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
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

class _DetailIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final PagePalette palette;

  const _DetailIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colorBlueDidik.withValues(alpha: 0.1),
        shape: CircleBorder(side: BorderSide(color: palette.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: Icon(icon, color: color, size: 21)),
          ),
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final VoucherDetailFact fact;
  final PagePalette palette;

  const _FactRow({required this.fact, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spaceLg,
        vertical: 13,
      ),
      child: Row(
        children: [
          Icon(fact.icon, color: palette.action, size: 22),
          const SizedBox(width: AppDesign.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fact.label,
                  style: TextStyle(
                    color: palette.muted,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.captionSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fact.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.bodySize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
