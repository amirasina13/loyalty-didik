import 'package:flutter/material.dart';
import '../../../data/data.dart';
import '../independent/favourite_card.dart';

extension View on OutletFavourite {
  Widget getOutletFavListTile({
    required BuildContext context,
    required VoidCallback onTap,
    required VoidCallback onTapFav,
  }) {
    return FavouriteCard(
      image: image ?? '',
      title: brandName ?? '',
      description: '',
      subtitle: outletName ?? '',
      openLabel: 'View outlet',
      removeLabel: 'Remove',
      onOpen: onTap,
      onRemove: onTapFav,
    );
  }
}
