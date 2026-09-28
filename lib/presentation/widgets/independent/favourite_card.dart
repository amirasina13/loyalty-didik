import 'account_empty_state.dart';
import 'package:flutter/material.dart';
import '../../../app_setting/app_setting.dart';
import 'cache_network_image.dart';

class FavouriteCard extends StatelessWidget {
  final String image, title, description, openLabel, removeLabel;
  final VoidCallback onOpen, onRemove;
  final Widget? badge;
  final String subtitle;
  const FavouriteCard({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.openLabel,
    required this.removeLabel,
    required this.onOpen,
    required this.onRemove,
    this.badge,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    const palette = AppDesign.favourites;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDesign.pagePadding),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppDesign.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppDesign.cardRadius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipOval(
                                child: CachedImage(imageUrl: image),
                              ),
                            ),
                            if (badge != null)
                              Positioned(top: 0, right: 0, child: badge!),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDesign.spaceLg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: AppDesign.bodyLargeSize,
                                fontWeight: FontWeight.w700,
                                color: palette.text,
                              ),
                            ),
                            if (subtitle.trim().isNotEmpty) ...[
                              const SizedBox(height: AppDesign.spaceSm),
                              Text(
                                subtitle,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppDesign.smallSize,
                                  height: 1.7,
                                  color: palette.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (description.trim().isNotEmpty) ...[
                    const SizedBox(height: AppDesign.spaceLg),
                    Text(
                      description.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppDesign.smallSize,
                        height: 1.8,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDesign.spaceLg),
            Divider(height: 1, color: palette.border),
            const SizedBox(height: AppDesign.spaceMd),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: palette.action,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: onOpen,
                      child: Text(
                        openLabel,
                        style: const TextStyle(fontSize: AppDesign.smallSize),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDesign.spaceLg),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppDesign.favouritesRemove,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: onRemove,
                      child: Text(
                        removeLabel,
                        style: const TextStyle(fontSize: AppDesign.smallSize),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FavouritesTabs extends StatelessWidget {
  final int selected;
  const FavouritesTabs({super.key, required this.selected});
  @override
  Widget build(BuildContext context) {
    const routes = [
      OderRoutes.favMerchant,
      OderRoutes.favOutlet,
      OderRoutes.favDeal,
    ];
    const labels = ['Following', 'Outlets', 'Deals'];
    const palette = AppDesign.favourites;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDesign.spaceXl,
        AppDesign.spaceSm,
        AppDesign.spaceXl,
        26,
      ),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colorBlueDidik.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: List.generate(
          3,
          (i) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: TextButton(
                style: TextButton.styleFrom(
                  disabledBackgroundColor: palette.background,
                  backgroundColor:
                      selected == i ? palette.background : Colors.transparent,
                  foregroundColor:
                      selected == i ? palette.action : palette.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed:
                    selected == i
                        ? null
                        : () => Navigator.of(
                          context,
                        ).pushReplacementNamed(routes[i]),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: selected == i ? palette.action : palette.muted,
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

/// Shared caption, card spacing and empty state for all saved-item categories.
class FavouritesList extends StatelessWidget {
  final int category;
  final List<Widget> items;
  final VoidCallback onExplore;

  const FavouritesList({
    super.key,
    required this.category,
    required this.items,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    const palette = AppDesign.favourites;
    const labels = [
      'Following Merchant',
      'Favourite Brands’ Outlets',
      'Favourite Deals',
    ];
    final deals = category == 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDesign.spaceXl,
            0,
            AppDesign.spaceXl,
            17,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${labels[category]} · ${items.length}',
              maxLines: 1,
              style: TextStyle(
                fontSize: AppDesign.smallSize,
                color: palette.muted,
              ),
            ),
          ),
        ),
        if (items.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: AppDesign.spaceXxl),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
            separatorBuilder:
                (context, index) => const SizedBox(height: AppDesign.spaceLg),
          )
        else
          AccountEmptyState(
            palette: palette,
            title: deals ? 'No favourite deals yet' : 'Nothing saved here',
            message:
                deals
                    ? 'Save deals you like to find them here.'
                    : 'Follow merchants and save outlets to keep them close.',
            asset:
                deals
                    ? 'assets/icons/settings/fav-deal.webp'
                    : 'assets/icons/settings/fav_brand.webp',
            actionLabel: deals ? 'Explore Deals' : 'Explore Directory',
            onAction: onExplore,
          ),
      ],
    );
  }
}
