import 'package:flutter/material.dart';
import '../../../data/data.dart';
import '../widgets.dart';
import '../independent/favourite_card.dart';

extension View on MerchantBookmark {
  Widget getMerchantBookmarkListTile({
    required BuildContext context,
    required VoidCallback onTap,
    required VoidCallback onTapBookmark,
  }) {
    return FavouriteCard(
      image: image ?? '',
      title: name ?? '',
      description: '',
      subtitle: desc ?? '',
      openLabel: 'View merchants',
      removeLabel: 'Unfollow',
      onOpen: onTap,
      onRemove: onTapBookmark,
      badge:
          isMuslim == 1 && muslimCategory != null
              ? HalalWidget(muslimCategory: muslimCategory!, width: 20)
              : null,
    );
  }
}
