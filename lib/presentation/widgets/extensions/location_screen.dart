import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_setting/app_setting.dart';
import '../../../data/data.dart';
import '../../features/outlet/outlet_details_screen.dart';
import '../widgets.dart';

/*
 * Outlet list used by voucher and reward details. The list is already loaded
 * by the calling feature, so this screen only owns presentation and search.
 */
class LocationScreenParameters {
  final List<RewardOutlet> locationDetails;

  const LocationScreenParameters({required this.locationDetails});
}

class LocationScreen extends StatefulWidget {
  final LocationScreenParameters parameters;

  const LocationScreen({super.key, required this.parameters});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController editingController = TextEditingController();
  late List<RewardOutlet> _outletDisplay;

  @override
  void initState() {
    super.initState();
    _outletDisplay = List<RewardOutlet>.of(widget.parameters.locationDetails);
  }

  @override
  void didUpdateWidget(covariant LocationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parameters.locationDetails !=
        widget.parameters.locationDetails) {
      searchOutlets(editingController.text);
    }
  }

  @override
  void dispose() {
    editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppDesign.outletDetails;

    return OderScaffold(
      background: palette.background,
      appBarColor: palette.background,
      systemUiOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: palette.background,
        statusBarIconBrightness: Brightness.dark,
      ),
      leading: IconButton(
        tooltip: 'Back',
        icon: Icon(Icons.arrow_back_ios_new, color: palette.text, size: 20),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'Outlets',
        style: TextStyle(
          fontFamily: fontFamilyMain,
          color: palette.text,
          fontWeight: FontWeight.w700,
          fontSize: AppDesign.appBarTitleSize,
        ),
        textScaler: TextScaler.linear(scaleFactor),
      ),
      body: SafeArea(top: false, child: _buildBody(context, palette)),
      bottomMenuIndex: 1,
      isShow: true,
    );
  }

  Widget _buildBody(BuildContext context, PagePalette palette) {
    final allOutlets = widget.parameters.locationDetails;

    if (allOutlets.isEmpty) {
      return _emptyState(
        palette: palette,
        title: 'No outlets available',
        message: 'There are no applicable outlets to show right now.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            AppDesign.spaceLg,
            20,
            AppDesign.spaceSm,
          ),
          child: _searchBar(palette),
        ),
        Expanded(
          child:
              _outletDisplay.isEmpty
                  ? _emptyState(
                    palette: palette,
                    title: 'No outlets found',
                    message: 'Try a different merchant or outlet name.',
                  )
                  : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      AppDesign.spaceSm,
                      20,
                      AppDesign.spaceXl,
                    ),
                    itemCount: _outletDisplay.length,
                    separatorBuilder:
                        (context, index) =>
                            const SizedBox(height: AppDesign.spaceMd),
                    itemBuilder:
                        (context, index) => _outletCard(
                          context,
                          _outletDisplay[index],
                          palette,
                        ),
                  ),
        ),
      ],
    );
  }

  Widget _searchBar(PagePalette palette) {
    final hasQuery = editingController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: TextField(
        controller: editingController,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: palette.text,
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.bodySize,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search outlets or merchants',
          hintStyle: TextStyle(
            color: palette.muted,
            fontFamily: fontFamilyMain,
            fontSize: AppDesign.bodySize,
          ),
          prefixIcon: Icon(Icons.search, color: palette.muted, size: 22),
          suffixIcon:
              hasQuery
                  ? IconButton(
                    tooltip: 'Clear search',
                    icon: Icon(Icons.close, color: palette.muted, size: 19),
                    onPressed: () {
                      editingController.clear();
                      searchOutlets('');
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppDesign.spaceLg,
          ),
        ),
        onChanged: searchOutlets,
      ),
    );
  }

  Widget _outletCard(
    BuildContext context,
    RewardOutlet outlet,
    PagePalette palette,
  ) {
    final merchantName = _valueOrFallback(outlet.merchantName, 'Merchant');
    final outletName = _valueOrFallback(outlet.place, merchantName);
    final address = outlet.address?.trim() ?? '';
    final imageUrl = outlet.merchantImg?.trim() ?? '';
    final distance = _formatDistance(outlet.distance);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDesign.cardRadius),
        onTap: () => _openOutlet(context, outlet),
        child: Ink(
          padding: const EdgeInsets.all(AppDesign.spaceLg),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(AppDesign.cardRadius),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _merchantImage(imageUrl, palette),
              const SizedBox(width: AppDesign.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.text,
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.bodySize,
                        fontWeight: FontWeight.w700,
                      ),
                      textScaler: TextScaler.linear(scaleFactor),
                    ),
                    const SizedBox(height: AppDesign.spaceSm),
                    Text(
                      outletName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.muted,
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.bodySize,
                        fontWeight: FontWeight.w500,
                      ),
                      textScaler: TextScaler.linear(scaleFactor),
                    ),
                    if (address.isNotEmpty && address != outletName) ...[
                      const SizedBox(height: AppDesign.spaceXs),
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.muted,
                          fontFamily: fontFamilyMain,
                          fontSize: AppDesign.captionSize,
                        ),
                        textScaler: TextScaler.linear(scaleFactor),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppDesign.spaceSm),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (distance != null)
                    Text(
                      distance,
                      style: TextStyle(
                        color: palette.action,
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.smallSize,
                        fontWeight: FontWeight.w700,
                      ),
                      textScaler: TextScaler.linear(scaleFactor),
                    ),
                  const SizedBox(height: AppDesign.spaceSm),
                  Icon(Icons.chevron_right, color: palette.muted, size: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _merchantImage(String imageUrl, PagePalette palette) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colorBlueDidik.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          imageUrl.isEmpty
              ? Icon(Icons.storefront_outlined, color: palette.muted, size: 30)
              : CachedImage(imageUrl: imageUrl, boxFit: BoxFit.cover),
    );
  }

  Widget _emptyState({
    required PagePalette palette,
    required String title,
    required String message,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDesign.spaceXl),
      child: AccountEmptyState(
        palette: palette,
        title: title,
        message: message,
        asset: 'assets/icons/no_location.webp',
      ),
    );
  }

  void _openOutlet(BuildContext context, RewardOutlet outlet) {
    final outletId = outlet.id?.trim() ?? '';
    if (outletId.isEmpty) return;

    final distance = double.tryParse(outlet.distance ?? '');
    Storage().distance = distance?.toStringAsFixed(2) ?? '';
    Navigator.of(context).pushNamed(
      OderRoutes.outletDetails,
      arguments: OutletDetailsParameters(
        outletId: outletId,
        outlet: _valueOrFallback(outlet.place, outlet.merchantName),
      ),
    );
  }

  void searchOutlets(String text) {
    final query = text.trim().toLowerCase();
    final source = widget.parameters.locationDetails;
    final filtered = _filterOutlets(source, query);

    if (!mounted) {
      _outletDisplay = filtered;
      return;
    }

    setState(() {
      _outletDisplay = filtered;
    });
  }

  List<RewardOutlet> _filterOutlets(List<RewardOutlet> source, String query) {
    if (query.isEmpty) return List<RewardOutlet>.of(source);

    return source
        .where((outlet) {
          final searchable =
              [
                outlet.merchantName,
                outlet.place,
                outlet.address,
              ].whereType<String>().join(' ').toLowerCase();
          return searchable.contains(query);
        })
        .toList(growable: false);
  }

  String _valueOrFallback(String? value, String? fallback) {
    final cleaned = value?.trim() ?? '';
    if (cleaned.isNotEmpty) return cleaned;
    final fallbackValue = fallback?.trim() ?? '';
    return fallbackValue.isNotEmpty ? fallbackValue : 'Outlet';
  }

  String? _formatDistance(String? value) {
    final parsed = double.tryParse(value ?? '');
    return parsed == null ? null : '${parsed.toStringAsFixed(2)} km';
  }
}
