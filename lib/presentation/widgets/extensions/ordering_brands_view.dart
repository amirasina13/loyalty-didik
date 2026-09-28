import 'package:flutter/material.dart';

import '../../../data/data.dart';
import '../widgets.dart';

/// Builds a merchant card for the Directory brand grid.
extension OrderingBrandView on MerchantList {
  Widget getListBrandTile({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return DirectoryMerchantCard(
      imageUrl: image,
      name: name,
      outletCount: total,
      isMuslim: isMuslim ?? false,
      muslimCategory: muslimCategory,
      onTap: onTap,
    );
  }
}
