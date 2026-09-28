import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app_setting/app_setting.dart';
import 'cache_network_image.dart';
import 'halal_widget.dart';

/// Shared visual language for Directory, merchant details, and outlet details.
///
/// These widgets only receive values that have already been loaded from the
/// API. They keep the layout consistent while leaving navigation and business
/// actions in the feature screens.
class DirectorySearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const DirectorySearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppDesign.directory;
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: palette.text,
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.bodySize,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: palette.muted,
            fontFamily: fontFamilyMain,
            fontSize: AppDesign.bodySize,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: palette.muted),
          filled: true,
          fillColor: palette.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDesign.spaceLg,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: palette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: palette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: palette.action, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class DirectoryCategoryTile extends StatelessWidget {
  final String label;
  final ImageProvider<Object>? image;
  final bool selected;
  final VoidCallback onTap;

  const DirectoryCategoryTile({
    super.key,
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppDesign.directory;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color:
            selected
                ? colorBlueDidik.withValues(alpha: 0.1)
                : palette.background,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 82,
            height: 84,
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: AppDesign.spaceSm,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child:
                              image == null
                                  ? Icon(
                                    Icons.category_outlined,
                                    color: palette.muted,
                                    size: 25,
                                  )
                                  : Image(image: image!, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: AppDesign.spaceSm),
                        Text(
                          label,
                          maxLines: 2,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? palette.action : palette.muted,
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.captionSize,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selected)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 4,
                      height: 62,
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DirectoryMerchantCard extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final int? outletCount;
  final bool isMuslim;
  final String? muslimCategory;
  final VoidCallback onTap;

  const DirectoryMerchantCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.outletCount,
    required this.isMuslim,
    required this.muslimCategory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppDesign.directory;
    return Semantics(
      button: true,
      label: 'View ${name?.trim().isNotEmpty == true ? name : 'merchant'}',
      child: Material(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1 / 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ColoredBox(
                          color: colorBlueDidik.withValues(alpha: 0.05),
                          child: _DirectoryImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (isMuslim && muslimCategory?.trim().isNotEmpty == true)
                        Positioned(
                          top: 7,
                          right: 7,
                          child: HalalWidget(
                            muslimCategory: muslimCategory!,
                            width: 22,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  name?.trim().isNotEmpty == true
                      ? name!.trim()
                      : 'Unnamed merchant',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.smallSize,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                // const SizedBox(height: AppDesign.spaceSm),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 16,
                        color: palette.muted,
                      ),
                      const SizedBox(width: AppDesign.spaceXs),
                      Expanded(
                        child: Text(
                          '${outletCount ?? 0} outlet(s)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.muted,
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.captionSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: palette.action,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DirectoryOutletCard extends StatelessWidget {
  final String? name;
  final String? location;
  final String? address;
  final String? distance;
  final bool? isOpen;
  final bool showStatus;
  final VoidCallback onTap;

  const DirectoryOutletCard({
    super.key,
    required this.name,
    required this.location,
    this.address,
    this.distance,
    this.isOpen,
    this.showStatus = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppDesign.directory;
    final displayName =
        name?.trim().isNotEmpty == true ? name!.trim() : 'Unnamed outlet';
    final displayLocation = location?.trim() ?? '';
    final displayAddress = address?.trim() ?? '';
    final displayDistance = distance?.trim() ?? '';

    return Semantics(
      button: true,
      label: 'View $displayName',
      child: Material(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(AppDesign.spaceLg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colorBlueDidik.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: palette.action,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.text,
                          fontFamily: fontFamilyMain,
                          fontSize: AppDesign.bodySize,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (displayLocation.isNotEmpty) ...[
                        const SizedBox(height: AppDesign.spaceXs),
                        Text(
                          displayLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.muted,
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.smallSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (displayAddress.isNotEmpty) ...[
                        const SizedBox(height: AppDesign.spaceXs),
                        Text(
                          displayAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.muted,
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.captionSize,
                            height: 1.25,
                          ),
                        ),
                      ],
                      if (showStatus && isOpen != null) ...[
                        const SizedBox(height: AppDesign.spaceSm),
                        _DirectoryStatusLabel(isOpen: isOpen!),
                      ],
                    ],
                  ),
                ),
                if (displayDistance.isNotEmpty) ...[
                  const SizedBox(width: AppDesign.spaceSm),
                  Text(
                    displayDistance,
                    style: TextStyle(
                      color: palette.muted,
                      fontFamily: fontFamilyMain,
                      fontSize: AppDesign.captionSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(width: AppDesign.spaceSm),
                Icon(Icons.arrow_forward_rounded, color: palette.action),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DirectoryInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DirectoryInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppDesign.outletDetails;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.spaceLg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.muted, size: 22),
          const SizedBox(width: AppDesign.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: palette.muted,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.captionSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDesign.spaceXs),
                Text(
                  value.trim().isEmpty ? '—' : value.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.bodySize,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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

class _DirectoryStatusLabel extends StatelessWidget {
  final bool isOpen;

  const _DirectoryStatusLabel({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? colorTextGreen : colorTextRed;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spaceSm,
        vertical: AppDesign.spaceXs,
      ),
      decoration: BoxDecoration(
        color: isOpen ? colorLightGreen : colorLightRed,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isOpen ? 'Open now' : 'Closed',
        style: TextStyle(
          color: color,
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.captionSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DirectoryImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;

  const _DirectoryImage({required this.imageUrl, required this.fit});

  @override
  Widget build(BuildContext context) {
    final value = imageUrl?.trim() ?? '';
    if (value.isEmpty) {
      return Image.asset(
        'assets/icons/outlet/no_merchant_outlet.webp',
        fit: BoxFit.contain,
        color: AppDesign.directory.muted,
        colorBlendMode: BlendMode.modulate,
      );
    }

    return CachedImage(imageUrl: value, boxFit: fit);
  }
}

ImageProvider<Object>? directoryCategoryImage(dynamic value) {
  if (value is ImageProvider<Object>) return value;
  if (value is! String || value.trim().isEmpty) return null;

  final source = value.trim();
  if (source.startsWith('data:image')) {
    final comma = source.indexOf(',');
    if (comma < 0) return null;
    try {
      return MemoryImage(base64Decode(source.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }

  if (source.startsWith('http://') || source.startsWith('https://')) {
    return NetworkImage(source);
  }

  return null;
}
