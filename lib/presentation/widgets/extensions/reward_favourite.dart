import 'package:flutter/material.dart';
import '../../../data/data.dart';
import '../widgets.dart';
import '../independent/favourite_card.dart';

extension View on RewardFavourite {
  Widget getRewardFavouriteListTile({
    required BuildContext context,
    required VoidCallback onTap,
    required VoidCallback onTapFavourite,
  }) {
    return FavouriteCard(
      image: image ?? '',
      title: name ?? '',
      description: desc ?? '',
      openLabel: 'View deal',
      removeLabel: 'Remove',
      onOpen: onTap,
      onRemove: onTapFavourite,
      badge:
          isMuslim == 1 && muslimCategory != null
              ? HalalWidget(muslimCategory: muslimCategory!, width: 20)
              : null,
    );
  }
}
