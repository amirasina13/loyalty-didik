import 'dart:convert';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
// import 'package:url_launcher/url_launcher.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../../locator.dart';
import '../../../widgets/extensions/reward_merchant_view.dart';
import '../../../widgets/widgets.dart';
import '../../outlet/outlet.dart';
import '../../rewards/reward.dart';
import '../ordering.dart';

class OrderingOutletView extends StatefulWidget {
  final Function? changeView;
  final String brandsId;

  const OrderingOutletView({
    super.key,
    this.changeView,
    required this.brandsId,
  });

  @override
  State<OrderingOutletView> createState() => _OrderingOutletViewState();
}

class _OrderingOutletViewState extends State<OrderingOutletView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool isProcessing = false;
  bool isBookmark = false;
  bool isFavOutlet = false;
  bool isDealEmpty = false;
  String fullAddress = '';
  int totalOutlets = 0;
  OutletInfo? outletInfo;
  List<OutletList> outlets = [];
  List<OutletList> outletDisplay = [];
  List<RewardMerchant> listVoucher = [];
  List<RewardMerchant> listVoucherDisplay = [];
  // List<dynamic> favoriteOutlet = [];
  List<OutletList> favOutlet = [];
  List<Map<String, dynamic>> newFavList = [];
  List<OutletFav> outletFav = [];
  List<GroupedItem> cachedOutletList = [];
  List<GroupedItem> displayList = [];
  TextEditingController editingController = TextEditingController();
  bool isClickFollow = false;
  // bool isClickOutletFav = false;
  bool tabChange = false;

  final Map<String, bool> _favouriteLoadingStates = {};
  final Map<String, bool> _favOutletLoadingStates = {};

  late TabController _tabController, stateController;

  final ScrollController _outerScrollController = ScrollController();
  final ScrollController dealScrollController = ScrollController();
  final ScrollController outletScrollController = ScrollController();
  final ScrollController menuScrollController = ScrollController();

  int selectedStateTabIndex = 0;

  List<String> cityState = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Kuala Lumpur',
    'Labuan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Pulau Pinang',
    'Putrajaya',
    'Perak',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
  ];

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);

    _getList();

    // Initialize with empty controller to avoid null issues
    stateController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _outerScrollController.dispose();
    dealScrollController.dispose();
    outletScrollController.dispose();
    menuScrollController.dispose();
    super.dispose();
  }

  // int _calculateTabLength() {
  //   int length = 4; // Always has "About" and "Gallery"
  //   if (!isDealEmpty) length++;
  //   if (totalOutlets > 0) length++;
  //   return length;
  // }

  @override
  bool get wantKeepAlive => true; // ✅ Keep state alive

  @override
  Widget build(BuildContext context) {
    super.build(context); // required with mixin

    return BlocConsumer<OrderingBloc, OrderingState>(
      listener: (context, state) {
        // If location is not enable, popup dialog
        if (state is OrderingLocationRequested) {
          YesNoDialog.showYesNoDialog(
            context,
            'Enable Location Service',
            Platform.isAndroid ? androidLocText : iosLocText,
            colorBlack,
            TextAlign.justify,
            _buildEnableButton(context),
          );
        }

        if (state is OutletsLoaded) {
          isClickFollow = false;
          // isClickOutletFav = false;
        }

        if (state is OutletAddRemoveFavouriteLoaded) {
          setState(() {
            _favOutletLoadingStates.clear();
          });
        }

        if (state is OrderingError ||
            state is OrderingNetworkError ||
            state is OrderingSessionError ||
            state is OrderingMaintenanceError) {
          if (mounted) setState(() => isClickFollow = false);
        }
      },
      builder: (context, state) {
        if (state is OrderingStarted) {
          BlocProvider.of<OrderingBloc>(
            context,
          ).add(OutletOrderLoad(brandId: widget.brandsId));
          // BlocProvider.of<OrderingBloc>(context).add(BrandsLoad());
        }

        if (state is OrderingInitial ||
            state is OrderingLoading ||
            state is OrderingStarted) {
          // return Container(
          return LoadingWidget();
        }

        if (state is OutletsLoaded) {
          outletInfo = state.outlets;
          isBookmark = outletInfo!.merchant!.isFavourite!;

          return _buildModernMerchantPage(context, state);
        }
        return Container();
      },
    );
  }

  Widget _buildModernMerchantPage(BuildContext context, OrderingState state) {
    final merchant = outletInfo?.merchant;
    if (merchant == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          _buildModernMerchantHeader(context, merchant),
          _buildModernMerchantTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDesign.spaceXl,
                    AppDesign.spaceXl,
                    AppDesign.spaceXl,
                    35,
                  ),
                  child: _buildModernAbout(context, merchant),
                ),
                _buildModernMerchantDeals(context),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDesign.spaceLg,
                    20,
                    AppDesign.spaceLg,
                    35,
                  ),
                  child: _buildModernMerchantOutlets(context, state),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDesign.spaceLg,
                    20,
                    AppDesign.spaceLg,
                    35,
                  ),
                  child: _buildModernGallery(context, state),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMerchantHeader(
    BuildContext context,
    MerchantInfo merchant,
  ) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final palette = AppDesign.merchantDetails;
    final merchantName =
        merchant.name?.trim().isNotEmpty == true
            ? merchant.name!.trim()
            : 'Merchant';
    final imageUrl = merchant.image?.trim() ?? '';

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDesign.spaceLg,
        statusBarHeight + 16,
        AppDesign.spaceLg,
        AppDesign.spaceLg,
      ),
      decoration: const BoxDecoration(gradient: AppDesign.directoryHeaderDidik),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _MerchantHeaderCircleButton(onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: AppDesign.spaceMd),
          SizedBox(
            width: 58,
            height: 58,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child:
                  imageUrl.isEmpty
                      ? ColoredBox(
                        color: colorBlueDidik.withValues(alpha: 0.1),
                        child: Image.asset(
                          'assets/icons/outlet/no_merchant_outlet.webp',
                          fit: BoxFit.contain,
                        ),
                      )
                      : CachedImage(imageUrl: imageUrl, boxFit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: AppDesign.spaceMd),
          Expanded(
            child: Text(
              merchantName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.sectionTitleSize,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: AppDesign.spaceMd),
          Semantics(
            button: true,
            label: isBookmark ? 'Unfollow merchant' : 'Follow merchant',
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap:
                    isClickFollow
                        ? null
                        : () {
                          if (isClickFollow) return;
                          setState(() => isClickFollow = true);
                          Storage().page = 'merchant_bookmark';
                          context.read<OrderingBloc>().add(
                            MerchantAddRemoveFavouriteLoad(
                              merchantId: merchant.id ?? widget.brandsId,
                            ),
                          );
                        },
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesign.spaceLg,
                    vertical: 11,
                  ),
                  child:
                      isClickFollow
                          ? FavouriteLoadingIcon(
                            color: palette.action,
                            size: 19,
                          )
                          : Text(
                            isBookmark ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: palette.action,
                              fontFamily: fontFamilyMain,
                              fontSize: AppDesign.captionSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMerchantDeals(BuildContext context) {
    return BlocProvider<RewardBloc>(
      create:
          (context) =>
              RewardBloc(context: context, rewardRepository: sl())
                ..add(RewardMerchantLoad(merchantId: widget.brandsId)),
      child: BlocBuilder<RewardBloc, RewardState>(
        builder:
            (context, state) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDesign.spaceLg,
                AppDesign.spaceSm,
                AppDesign.spaceLg,
                35,
              ),
              child: _buildVoucherListView(context, state),
            ),
      ),
    );
  }

  Widget _buildModernMerchantTabs() {
    final palette = AppDesign.merchantDetails;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: palette.tabIndicator,
        indicatorWeight: 2,
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: AppDesign.spaceLg,
        ),
        labelColor: palette.action,
        unselectedLabelColor: palette.muted,
        labelStyle: const TextStyle(
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.smallSize,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.smallSize,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'About'),
          Tab(text: 'Deals'),
          Tab(text: 'Outlets'),
          Tab(text: 'Gallery'),
        ],
      ),
    );
  }

  Widget _buildModernAbout(BuildContext context, MerchantInfo merchant) {
    final palette = AppDesign.merchantDetails;
    final description = merchant.merchantDesc?.trim() ?? '';
    final links = merchant.socials ?? const <SocialList>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ABOUT THE MERCHANT',
          style: TextStyle(
            color: palette.action,
            fontFamily: fontFamilyMain,
            fontSize: AppDesign.captionSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: AppDesign.spaceLg),
        Text(
          merchant.name?.trim().isNotEmpty == true
              ? merchant.name!.trim()
              : 'Merchant',
          style: TextStyle(
            color: palette.text,
            fontFamily: fontFamilyMain,
            fontSize: AppDesign.sectionTitleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: AppDesign.spaceLg),
          HtmlWidget(
            description,
            onTapUrl:
                (url) => openInAppWebView(
                  context,
                  url,
                  title: merchant.name ?? 'Merchant details',
                ),
            textStyle: TextStyle(
              color: palette.text,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.bodySize,
              height: 1.55,
            ),
          ),
        ],
        if (links.isNotEmpty) ...[
          const SizedBox(height: AppDesign.spaceXl),
          ...links.map(_buildModernMerchantLink),
        ],
      ],
    );
  }

  Widget _buildModernMerchantLink(SocialList item) {
    final palette = AppDesign.merchantDetails;
    final type =
        item.type?.trim().isNotEmpty == true ? item.type!.trim() : 'Link';
    final url = item.url?.trim() ?? '';
    final icon = _merchantLinkIcon(type);

    return InkWell(
      onTap:
          url.isEmpty
              ? null
              : () async {
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDesign.spaceMd),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorBlueDidik.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: palette.action, size: 18),
            ),
            const SizedBox(width: AppDesign.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      color: palette.text,
                      fontFamily: fontFamilyMain,
                      fontSize: AppDesign.smallSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    url.isEmpty ? 'Details unavailable' : url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.muted,
                      fontFamily: fontFamilyMain,
                      fontSize: AppDesign.captionSize,
                    ),
                  ),
                ],
              ),
            ),
            if (url.isNotEmpty)
              Icon(
                Icons.arrow_outward_rounded,
                color: palette.action,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  IconData _merchantLinkIcon(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('instagram')) return FontAwesomeIcons.instagram;
    if (normalized.contains('facebook')) return FontAwesomeIcons.facebook;
    if (normalized.contains('tiktok')) return FontAwesomeIcons.tiktok;
    if (normalized.contains('whatsapp')) return FontAwesomeIcons.whatsapp;
    if (normalized.contains('youtube')) return FontAwesomeIcons.youtube;
    if (normalized == 'x' || normalized.contains('twitter')) {
      return FontAwesomeIcons.xTwitter;
    }
    if (normalized.contains('website') || normalized.contains('web')) {
      return FontAwesomeIcons.globe;
    }
    return Icons.public_rounded;
  }

  Widget _buildModernMerchantOutlets(
    BuildContext context,
    OrderingState state,
  ) {
    final palette = AppDesign.merchantDetails;
    final merchantOutlets =
        state is OutletsLoaded
            ? state.outlets.outlets ?? const <OutletList>[]
            : outlets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Outlets',
              style: TextStyle(
                color: palette.text,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.sectionTitleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${merchantOutlets.length} ${merchantOutlets.length == 1 ? 'outlet' : 'outlets'}',
              style: TextStyle(
                color: palette.muted,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.smallSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDesign.spaceLg),
        if (merchantOutlets.isEmpty)
          AccountEmptyState(
            palette: palette,
            title: 'No outlets yet',
            message: 'This merchant has no outlets to display.',
            asset: 'assets/icons/outlet/no_merchant_outlet.webp',
          )
        else
          ...merchantOutlets.map(
            (outlet) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DirectoryOutletCard(
                name:
                    outlet.place?.trim().isNotEmpty == true
                        ? outlet.place
                        : outlet.merchantName,
                location: _stateFromAddress(outlet.address),
                address: outlet.address,
                distance: _formatDistance(outlet.distance),
                showStatus: outlet.isOpen != null,
                isOpen: outlet.isOpen,
                onTap: () {
                  Storage().distance = outlet.distance ?? '';
                  Navigator.of(context).pushNamed(
                    OderRoutes.outletDetails,
                    arguments: OutletDetailsParameters(
                      outletId: outlet.id ?? '',
                      outlet: outlet.place ?? outlet.merchantName ?? 'Outlet',
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModernGallery(BuildContext context, OrderingState state) {
    final merchant =
        state is OutletsLoaded ? state.outlets.merchant : outletInfo?.merchant;
    final menus = merchant?.menus ?? const <String>[];
    if (menus.isEmpty) {
      return AccountEmptyState(
        palette: AppDesign.merchantDetails,
        title: 'No gallery yet',
        message: 'Photos will appear here when they are available.',
        asset: 'assets/icons/outlet/no_merchant_gallery.webp',
      );
    }

    final palette = AppDesign.merchantDetails;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Tap a photo to view it full screen.',
                style: TextStyle(
                  color: palette.muted,
                  fontFamily: fontFamilyMain,
                  fontSize: AppDesign.captionSize,
                ),
              ),
            ),
            Text(
              '${menus.length} ${menus.length == 1 ? 'item' : 'items'}',
              style: TextStyle(
                color: palette.muted,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.smallSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDesign.spaceLg),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: menus.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            return _buildModernGalleryTile(context, menus, index);
          },
        ),
      ],
    );
  }

  Widget _buildModernGalleryTile(
    BuildContext context,
    List<String> menus,
    int index,
  ) {
    final palette = AppDesign.merchantDetails;
    final url = menus[index].trim();
    final isVideo = _isGalleryVideo(url);
    return Semantics(
      button: !isVideo,
      label: isVideo ? 'Video' : 'Open gallery image ${index + 1}',
      child: Material(
        color: colorBlueDidik.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: isVideo ? null : () => _showGalleryImage(context, url, menus),
          borderRadius: BorderRadius.circular(15),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                isVideo
                    ? Container(
                      color: palette.action,
                      child: Icon(
                        Icons.play_circle_outline_rounded,
                        color: palette.onAction,
                        size: 42,
                      ),
                    )
                    : CachedImage(imageUrl: url, boxFit: BoxFit.cover),
                if (isVideo)
                  Positioned(
                    left: 10,
                    bottom: 9,
                    child: Text(
                      'Video',
                      style: TextStyle(
                        color: palette.onAction,
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.captionSize,
                        fontWeight: FontWeight.w700,
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

  bool _isGalleryVideo(String url) {
    final normalized = url.toLowerCase();
    return normalized.contains('video') ||
        normalized.endsWith('.mp4') ||
        normalized.endsWith('.mov') ||
        normalized.endsWith('.m4v');
  }

  void _showGalleryImage(BuildContext context, String url, List<String> menus) {
    final imageUrls =
        menus
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty && !_isGalleryVideo(item))
            .toList();
    final initialIndex = imageUrls.indexOf(url.trim());
    if (imageUrls.isEmpty || initialIndex < 0) return;

    final pageController = ExtendedPageController(
      initialPage: initialIndex,
      shouldIgnorePointerWhenScrolling: true,
    );
    var currentIndex = initialIndex;

    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.94),
      barrierDismissible: true,
      barrierLabel: 'Close gallery',
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Material(
              color: Colors.transparent,
              child: SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ExtendedImageGesturePageView.builder(
                      controller: pageController,
                      itemCount: imageUrls.length,
                      onPageChanged: (index) {
                        setState(() => currentIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return ExtendedImage.network(
                          imageUrls[index],
                          fit: BoxFit.contain,
                          mode: ExtendedImageMode.gesture,
                          initGestureConfigHandler:
                              (state) => GestureConfig(
                                inPageView: true,
                                initialScale: 1,
                                maxScale: 4,
                                animationMaxScale: 5,
                              ),
                        );
                      },
                    ),
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _galleryOverlayButton(
                            icon: Icons.close_rounded,
                            label: 'Close gallery',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDesign.spaceLg,
                                vertical: AppDesign.spaceSm,
                              ),
                              child: Text(
                                '${currentIndex + 1} / ${imageUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: AppDesign.smallSize,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (imageUrls.length > 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 18,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List<Widget>.generate(
                            imageUrls.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: index == currentIndex ? 18 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color:
                                    index == currentIndex
                                        ? Colors.white
                                        : Colors.white54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(pageController.dispose);
  }

  Widget _galleryOverlayButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onPressed,
        tooltip: label,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black54,
          foregroundColor: Colors.white,
          iconSize: 26,
          padding: EdgeInsets.zero,
        ),
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }

  String _stateFromAddress(String? address) {
    final value = address?.trim() ?? '';
    if (value.isEmpty) return '';
    const states = [
      'Johor',
      'Kedah',
      'Kelantan',
      'Kuala Lumpur',
      'Labuan',
      'Melaka',
      'Negeri Sembilan',
      'Pahang',
      'Penang',
      'Pulau Pinang',
      'Putrajaya',
      'Perak',
      'Perlis',
      'Sabah',
      'Sarawak',
      'Selangor',
      'Terengganu',
    ];
    for (final state in states) {
      if (value.toLowerCase().contains(state.toLowerCase())) return state;
    }
    return value;
  }

  String _formatDistance(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return '';
    return '${parsed.toStringAsFixed(2)} km';
  }

  Widget _buildVoucherListView(BuildContext context, RewardState state) {
    dynamic voucherTiles;

    if (state is RewardLoading) {
      return Padding(
        padding: EdgeInsets.only(top: ScreenSize.height * 0.2),
        child: LoadingWidget(),
      );
    }

    if (state is RewardMerchantLoaded) {
      // listVoucher = state.rewards;
      listVoucher =
          state.rewards
              .where((voucher) => voucher.purchaseMethod != 'redeemable')
              .toList();
    }

    voucherTiles = listVoucher
        .map((listVoucher) {
          final bool isItemLoading =
              _favouriteLoadingStates[listVoucher.id!] ?? false;

          if (state is RewardAddRemoveFavouriteLoaded) {
            if (listVoucher.id == state.voucherId.toString()) {
              _favouriteLoadingStates.clear();
            }
          }

          return listVoucher.getRewardMerchantTile(
            context: context,
            onTap: () {
              setProcessingStatus(true);

              Navigator.of(context)
                  .pushNamed(
                    OderRoutes.rewardDetails,
                    arguments: RewardDetailsParameters(
                      rewardId: listVoucher.id.toString(),
                      title: Storage().brandName!,
                      indexPage: 3,
                    ),
                  )
                  .then((value) {
                    setProcessingStatus(false);
                  })
                  .then((value) {
                    if (!context.mounted) return;
                    BlocProvider.of<RewardBloc>(
                      context,
                    ).add(RewardMerchantLoad(merchantId: widget.brandsId));
                  });
            },
            onFavouriteTap: () {
              // Set the loading state for THIS specific item to true
              setState(() {
                _favouriteLoadingStates[listVoucher.id!] = true;
              });

              // Dispatch the Bloc event
              Storage().page = 'merchant_wishlist';
              Storage().merchantId = widget.brandsId;

              BlocProvider.of<RewardBloc>(context).add(
                RewardAddRemoveFavouriteLoad(
                  voucherId: listVoucher.id!.toString(),
                  filterBy: '',
                  filterValue: '',
                ),
              );
            },
            isFavClick: isItemLoading,
            // isFavClick: state is FavClick ? true : false,
          );
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        state is RewardEmpty || listVoucher.isEmpty
            ? AccountEmptyState(
              palette: AppDesign.merchantDetails,
              title: 'No deals yet',
              message: 'This merchant has no voucher yet.',
              asset: 'assets/icons/outlet/no_merchant_voucher.webp',
            )
            //  Center(
            //   child: Container(
            //     color: colorBackground,
            //     height: ScreenSize.height * 0.5,
            //     // margin: EdgeInsets.symmetric(vertical: 10),
            //     child: Column(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         Container(
            //           height: ScreenSize.width * 0.2,
            //           width: ScreenSize.width * 0.2,
            //           // margin: EdgeInsets.only(top: height / AppDesign.spaceXs),
            //           padding: EdgeInsets.symmetric(
            //             vertical: ScreenSize.height / AppDesign.spaceSm,
            //             horizontal: ScreenSize.width,
            //           ),
            //           decoration: const BoxDecoration(
            //             image: DecorationImage(
            //               fit: BoxFit.contain,
            //               image: AssetImage(
            //                 'assets/icons/outlet/no_merchant_voucher.webp',
            //               ),
            //             ),
            //           ),
            //         ),
            //         SizedBox(height: ScreenSize.height * 0.03),
            //         Text(
            //           "No Deals Yet",
            //           style: TextStyle(
            //             fontSize: AppDesign.smallSize,
            //             fontWeight: FontWeight.w300,
            //             color: colorNoVoucherGrey,
            //           ),
            //           textAlign: TextAlign.center,
            //           textScaler: TextScaler.linear(scaleFactor),
            //         ),
            //       ],
            //     ),
            //   ),
            // )
            : Container(
              color: colorBackground,
              margin: EdgeInsets.only(
                bottom: Platform.isIOS ? 80 : AppDesign.spaceXxl,
              ),
              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                itemCount: listVoucher.length,
                itemBuilder: (context, index) {
                  return voucherTiles[index];
                },
              ),
            ),
      ],
    );
  }

  // Widget _buildGallery(BuildContext context, OrderingState state) {
  //   if (state is OutletsLoaded) {
  //     outletInfo = state.outlets;
  //   }

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       outletInfo!.merchant!.menus!.isNotEmpty
  //           ? Expanded(
  //             child: Container(
  //               // height: height,
  //               // color: colorBabyBlue,
  //               margin: EdgeInsets.fromLTRB(
  //                 marginHorizontal,
  //                 20,
  //                 marginHorizontal,
  //                 20,
  //               ),
  //               child: GridView.builder(
  //                 padding: EdgeInsets.zero,
  //                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //                   crossAxisCount: 3, // number of items in each row
  //                   mainAxisSpacing: 10.0, // spacing between rows
  //                   crossAxisSpacing: 10.0, // spacing between columns
  //                   // childAspectRatio: 0.6,
  //                 ),
  //                 itemBuilder: (BuildContext context, int index) {
  //                   final String url = outletInfo!.merchant!.menus![index];
  //                   return GestureDetector(
  //                     child: AspectRatio(
  //                       aspectRatio: 1.0,
  //                       child: Hero(
  //                         tag: url,
  //                         child:
  //                             url == 'This is an video'
  //                                 ? Container(
  //                                   alignment: Alignment.center,
  //                                   child: const Text('This is an video'),
  //                                 )
  //                                 : ExtendedImage.network(
  //                                   url,
  //                                   fit: BoxFit.cover,
  //                                   shape: BoxShape.rectangle,
  //                                   borderRadius: BorderRadius.circular(10),
  //                                 ),
  //                       ),
  //                     ),
  //                     onTap: () {
  //                       Navigator.push(
  //                         context,
  //                         MaterialPageRoute(
  //                           builder:
  //                               (context) => SimplePicsWiper(
  //                                 url: url,
  //                                 images: outletInfo!.merchant!.menus!,
  //                               ),
  //                         ),
  //                       );
  //                     },
  //                   );
  //                 },
  //                 itemCount: outletInfo!.merchant!.menus!.length,
  //               ),
  //             ),
  //           )
  //           : Center(
  //             child: Container(
  //               color: colorBackground,
  //               height: ScreenSize.height * 0.5,
  //               // margin: EdgeInsets.symmetric(vertical: 10),
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Container(
  //                     height: ScreenSize.width * 0.2,
  //                     width: ScreenSize.width * 0.2,
  //                     // margin: EdgeInsets.only(top: height / AppDesign.spaceXs),
  //                     padding: EdgeInsets.symmetric(
  //                       vertical: ScreenSize.height / AppDesign.spaceSm,
  //                       horizontal: ScreenSize.width,
  //                     ),
  //                     decoration: const BoxDecoration(
  //                       image: DecorationImage(
  //                         fit: BoxFit.contain,
  //                         image: AssetImage(
  //                           'assets/icons/outlet/no_merchant_gallery.webp',
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   SizedBox(height: ScreenSize.height * 0.03),
  //                   Text(
  //                     "No Gallery Yet",
  //                     style: TextStyle(
  //                       fontSize: AppDesign.smallSize,
  //                       fontWeight: FontWeight.w300,
  //                       color: colorNoVoucherGrey,
  //                     ),
  //                     textAlign: TextAlign.center,
  //                     textScaler: TextScaler.linear(scaleFactor),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //     ],
  //   );
  // }

  // For enable buton in location dialog
  Widget _buildEnableButton(BuildContext context) {
    return OderStyleButton(
      title: 'Continue',
      backgroundColor: mainColor,
      onPressed: () async {
        BlocProvider.of<OrderingBloc>(context).add(OrderingLocationEnable());
        Navigator.pop(context);
      },
    );
  }

  // Future<void> _saveList(favList) async {
  //   await Storage().secureStorage.write(key: 'favList', value: favList);
  // }

  Future<void> _getList() async {
    final String? favList = await Storage().secureStorage.read(key: 'favList');
    if (favList != null) {
      final List<dynamic> fav = jsonDecode(favList);

      // setState(() {
      outletFav =
          fav.map((item) {
            final Map<String, dynamic> itemMap = item as Map<String, dynamic>;
            return OutletFav.fromJson(itemMap);
          }).toList();
      // });
    }
  }
}

class GroupedItem {
  final String cityState;
  final List<OutletList> outletList;

  GroupedItem(this.cityState, this.outletList);
}

class OutletFav {
  final int id;
  final String merchantName;
  final String image;
  final String place;
  final String distance;

  OutletFav({
    required this.id,
    required this.merchantName,
    required this.image,
    required this.place,
    required this.distance,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "merchantName": merchantName,
      "image": image,
      "place": place,
      "distance": distance,
    };
  }

  factory OutletFav.fromJson(Map<String, dynamic> json) => OutletFav(
    id: json['id'] as int,
    merchantName: json['merchantName'] as String,
    image: json['image'] as String,
    place: json['place'] as String,
    distance: json['distance'] as String,
  );
}

class _MerchantHeaderCircleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MerchantHeaderCircleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.arrow_back_rounded, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
