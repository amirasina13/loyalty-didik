import 'package:flutter/material.dart';

import '../../../app_setting/app_setting.dart';
import '../../../data/data.dart';
import '../widgets.dart';

// Extension class for bulletin list. Will use in features/bulletin/view/bulletin_view.dart
extension View on Bulletin {
  Widget getBulletinTile({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spaceLg),
      child: InkWell(
        onTap: onTap,
        highlightColor: colorTransparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 1,
              child: Container(
                decoration: BoxDecoration(
                  color: colorBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorGreyBox),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 4.0),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedImage(
                    imageUrl: image ?? '',
                    boxFit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
              child: Text(
                name ?? 'Highlight',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: colorBlack,
                  fontFamily: fontFamilyMain,
                  fontSize: AppDesign.bodySize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
