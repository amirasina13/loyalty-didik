// ignore_for_file: unused_field

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../../util/utils.dart';
import '../../../widgets/widgets.dart';
import '../../bulletin/bulletin.dart';
import '../../ordering/ordering.dart';
import '../../rewards/reward.dart';
import '../../voucher/voucher.dart';
import '../../webview/webview_deeplink.dart';
import '../home.dart';

class HomeViewNew extends StatefulWidget {
  final String? token;
  final Function changeView;

  const HomeViewNew({super.key, this.token, required this.changeView});

  @override
  State<HomeViewNew> createState() => _HomeViewNewState();
}

class _HomeViewNewState extends State<HomeViewNew> {
  List<Slideshow> slideshowImage = [];
  List<CategoryVoucher> categories = [];
  List<VouchersCat> catVouchers = [];
  List<Upcoming> upcoming = [];
  List<Merchant> merchants = [];
  List<Highlight> highlight = [];
  List<MiniProgram> miniProgram = [];
  int _current = 0;
  String announcement = '';
  bool isClose = false;
  final bool _enabled = true;
  // final CarouselController _controller = CarouselController();
  CarouselSliderController carouselController = CarouselSliderController();

  var top = 0.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is HomeLoaded) {
          slideshowImage = state.homePage.slideshow ?? const [];
          categories = state.homePage.categories ?? const [];
          upcoming = state.homePage.upcoming ?? const [];
          merchants = state.homePage.merchants ?? const [];
          highlight = state.homePage.highlight ?? const [];
          miniProgram = state.homePage.mini ?? const [];
          announcement = state.homePage.announcements ?? '';

          return CustomScrollView(
            slivers: [
              // ----------------------------------------------------------------- Dynamic appbar
              SliverAppBar(
                expandedHeight: ScreenSize.height * 0.30,
                collapsedHeight: (ScreenSize.height * 0.14).clamp(
                  kToolbarHeight,
                  double.infinity,
                ),
                floating: true,
                pinned: true,
                snap: true,
                elevation: 0,
                clipBehavior: Clip.none,
                backgroundColor: colorWhite,
                surfaceTintColor: colorTransparent,
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: mainColor,
                  statusBarIconBrightness:
                      Brightness.light, //this will take care of the icon color
                ),
                flexibleSpace: Stack(
                  children: <Widget>[
                    // ----------------------------------------------------------- Slideshow image
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(top: 0, bottom: 34),
                        child: _buildslideshowImage(context, state),
                      ),
                    ),
                    // ----------------------------------------------------------- Search box
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _searchBar(true),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ----------------------------------------------------------- API shortcut icons
                    _buildCategory(),
                    announcement.isNotEmpty && isClose == false
                        ? _announcementWidget(announcement)
                        : Container(),
                    // ----------------------------------------------------------- Upcoming Event
                    _buildUpcomingEvent(state),
                    // ----------------------------------------------------------- Merchant/ Brand
                    _buildTopBrand(state),
                  ],
                ),
              ),
              // ----------------------------------------------------------------- Category voucher(Trending voucher/ hot deals voucher)
              SliverList(
                delegate: SliverChildBuilderDelegate((
                  BuildContext context,
                  int index,
                ) {
                  return _buildCategoryVoucher(index);
                }, childCount: categories.length),
              ),
              // ----------------------------------------------------------------- Highlight/ bulletin list
              SliverToBoxAdapter(child: _buildHighlight()),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + 16,
                ),
              ),
            ],
          );
        }

        return _homeLoading();
      },
    );
  }

  Widget _homeLoading() {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Container(
        height: ScreenSize.height,
        color: colorTransparent,
        child: Shimmer.fromColors(
          baseColor: colorLightGray,
          highlightColor: colorWhiteQrLight,
          enabled: _enabled,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: ScreenSize.height * 0.31,
                  color: colorWhite,
                  padding: EdgeInsets.fromLTRB(
                    marginHorizontal,
                    50,
                    marginHorizontal,
                    10,
                  ),
                ),
                Container(
                  height: ScreenSize.height * 0.1,
                  // color: colorWhite,
                  margin: EdgeInsets.fromLTRB(
                    marginHorizontal,
                    AppDesign.spaceSm,
                    marginHorizontal,
                    20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (int i = 0; i < 5; i++)
                        Container(
                          height: ScreenSize.height * 0.07,
                          width: ScreenSize.height * 0.07,
                          padding: EdgeInsets.all(AppDesign.spaceMd),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorWhite,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: ScreenSize.height * 0.03),
                Container(
                  height: ScreenSize.height * 0.03,
                  width: ScreenSize.width,
                  padding: EdgeInsets.symmetric(vertical: 23),
                  margin: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: marginHorizontal,
                  ),
                  color: colorWhite,
                ),
                Container(
                  height: ScreenSize.height * 0.15,
                  width: ScreenSize.width,
                  margin: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: marginHorizontal,
                  ),
                  color: colorWhite,
                ),
                SizedBox(height: ScreenSize.height * 0.04),
                Container(
                  height: ScreenSize.height * 0.03,
                  width: ScreenSize.width,
                  padding: EdgeInsets.symmetric(vertical: 23),
                  margin: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: marginHorizontal,
                  ),
                  color: colorWhite,
                ),
                Container(
                  height: ScreenSize.height * 0.15,
                  width: ScreenSize.width,
                  margin: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: marginHorizontal,
                  ),
                  color: colorWhite,
                ),
                SizedBox(height: ScreenSize.height * 0.04),
                Container(
                  height: ScreenSize.height * 0.03,
                  width: ScreenSize.width,
                  padding: EdgeInsets.symmetric(vertical: 23),
                  margin: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: marginHorizontal,
                  ),
                  color: colorWhite,
                ),
                Container(
                  height: ScreenSize.height * 0.15,
                  width: ScreenSize.width,
                  margin: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: marginHorizontal,
                  ),
                  color: colorWhite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Slideshow image body
  Widget _buildslideshowImage(BuildContext context, HomeState state) {
    if (slideshowImage.isEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        child: Container(
          color: colorRedDark,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_outlined,
            color: colorWhite.withValues(alpha: 0.55),
            size: 38,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          // borderRadius: const BorderRadius.vertical(
          //   bottom: Radius.circular(26),
          // ),
          child: CarouselSlider(
            items:
                slideshowImage.map((item) {
                  final imagePath = item.displayUrl.trim();
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      imagePath.isEmpty
                          ? Container(color: colorRedDark)
                          : CachedNetworkImage(
                            imageUrl: imagePath,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  color: colorLightGray,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Image.asset(
                                  'assets/icons/no_photo.webp',
                                  fit: BoxFit.cover,
                                ),
                          ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x66000000)],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
            carouselController: carouselController,
            options: CarouselOptions(
              height: double.infinity,
              padEnds: false,
              viewportFraction: 1.0,
              enableInfiniteScroll: slideshowImage.length > 1,
              autoPlay: slideshowImage.length > 1,
              autoPlayInterval: const Duration(seconds: 5),
              onPageChanged: (index, reason) {
                if (mounted) setState(() => _current = index);
              },
            ),
          ),
        ),
        if (slideshowImage.length > 1)
          Positioned(
            bottom: 42,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slideshowImage.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _current ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        index == _current
                            ? colorGoldButton
                            : colorWhite.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // search box body
  Widget _searchBar(bool? showSuffix) {
    var width = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: () {
        // Navigator.of(context).pushNamed(OderRoutes.searchResultsPage);
        Navigator.of(context).pushNamed(
          OderRoutes.searchAPIPage,
          arguments: SearchScreenParameters(tabFor: 'home'),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: marginHorizontal),
        padding: EdgeInsets.symmetric(
          horizontal: AppDesign.spaceLg,
          vertical: AppDesign.spaceLg,
        ),
        decoration: BoxDecoration(
          color: colorWhite,
          border: Border.all(color: colorGreyBox),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8.0,
              offset: Offset(0.0, 3.0),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: width * 0.05,
              child: Image(
                image: AssetImage('assets/icons/outlet/search.webp'),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  'Search brands and deals',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorSoftGrey,
                    fontSize: AppDesign.smallSize,
                    fontWeight: FontWeight.w400,
                    fontFamily: fontFamilyMain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory() {
    // 1. Dynamic pool of secondary items
    final poolItems = <Widget>[
      ...categories.map(_buildCategoryItem),
      ...miniProgram.map(_buildMiniProgramItem),
    ];

    // 2. Determine slot availability: Top Brand takes Slot 1, leaving up to 4 remaining slots
    final totalItemsCount = 1 + poolItems.length; // Top Brand + rest
    final showViewAll = totalItemsCount > 5;

    // 3. Assemble visible items (Slot 1 is always Top Brand)
    final visibleItems = <Widget>[
      _buildTopBrandsItem(), // Slot 1: Always Top Brand
      ...poolItems.take(
        showViewAll ? 3 : 4,
      ), // Slots 2-4 (with View All) or 2-5 (without View All)
    ];

    if (showViewAll) {
      visibleItems.add(_buildViewAllItem());
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        marginHorizontal,
        34,
        marginHorizontal,
        AppDesign.spaceSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: visibleItems
            .map((item) => Expanded(child: item))
            .toList(growable: false),
      ),
    );
  }

  // Widget _buildCategory() {
  //   final apiItems = <Widget>[
  //     ...categories.map(_buildCategoryItem),
  //     ...miniProgram.map(_buildMiniProgramItem),
  //   ];

  //   if (apiItems.length < 2) {
  //     return const SizedBox.shrink();
  //   }

  //   final showViewAll = apiItems.length > 5;
  //   final visibleItems = <Widget>[...apiItems.take(showViewAll ? 4 : 5)];
  //   if (showViewAll) {
  //     visibleItems.add(_buildViewAllItem());
  //   }

  //   return Padding(
  //     padding: EdgeInsets.fromLTRB(
  //       marginHorizontal,
  //       34,
  //       marginHorizontal,
  //       AppDesign.spaceSm,
  //     ),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: visibleItems
  //           .map((item) => Expanded(child: item))
  //           .toList(growable: false),
  //     ),
  //   );
  // }

  void _openCategory(CategoryVoucher category) {
    Storage().isTabChange = false;
    final isMerchant = category.filterBy?.trim().toLowerCase() == 'merchant';
    Navigator.of(context).pushNamedAndRemoveUntil(
      isMerchant ? OderRoutes.orderingMerchant : OderRoutes.voucher,
      (Route<dynamic> route) => false,
      arguments:
          isMerchant
              ? OrderingScreenParameters(
                selectedTab: 0,
                categoryId: category.id,
              )
              : VoucherParameters(
                selectedTab: 0,
                filterBy: category.filterBy ?? 'all',
                filterValue: category.id?.toString() ?? '1',
              ),
    );
  }

  Widget _buildTopBrandsItem() {
    return InkWell(
      splashColor: colorTransparent,
      highlightColor: colorTransparent,
      onTap: () {
        Navigator.of(context).pushNamedAndRemoveUntil(
          OderRoutes.orderingMerchant,
          (Route<dynamic> route) => false,
          arguments: OrderingScreenParameters(selectedTab: 0, categoryId: '0'),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 48,
            width: 48,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: colorWhiteGrey,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icons/homePage/top.webp',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              'Top Brands',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: colorBlack,
                fontSize: AppDesign.captionSize,
                fontWeight: FontWeight.w300,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryVoucher category) {
    return InkWell(
      splashColor: colorTransparent,
      highlightColor: colorTransparent,
      onTap: () => _openCategory(category),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 48,
            width: 48,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: colorWhiteGrey,
            ),
            child: ClipOval(
              child: _homeImage(category.image, fit: BoxFit.contain),
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              category.name ?? 'Category',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: colorBlack,
                fontSize: AppDesign.captionSize,
                fontWeight: FontWeight.w300,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProgramItem(dynamic item) {
    return InkWell(
      splashColor: colorTransparent,
      highlightColor: colorTransparent,
      onTap: () {
        if (item.url != null) {
          Navigator.push(
            context,
            NoAnimationPageRoute(
              builder:
                  (context) => WidgetWebView(
                    widgetUrl: item.url!,
                    title: item.name ?? '',
                  ),
            ),
          );
        } else {
          showErrorToast('Not available', context);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 48,
            width: 48,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: colorWhiteGrey,
            ),
            child: ClipOval(child: _homeImage(item.image, fit: BoxFit.contain)),
          ),
          Container(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              item.name ?? 'Service',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: colorBlack,
                fontSize: AppDesign.captionSize,
                fontWeight: FontWeight.w300,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllItem() {
    return InkWell(
      splashColor: colorTransparent,
      highlightColor: colorTransparent,
      onTap: () => modalBottomSheetMenu(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            width: 48,
            padding: const EdgeInsets.all(5),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const ClipOval(
                child: Image(
                  image: AssetImage('assets/icons/homePage/viewall.png'),
                ),
              ),
            ),
          ),
          SizedBox(
            child: const Text(
              'View All',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorBlack,
                fontSize: AppDesign.captionSize,
                fontWeight: FontWeight.w300,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _announcementWidget(String announcement) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        marginHorizontal,
        10,
        marginHorizontal,
        AppDesign.spaceXs,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesign.spaceMd,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: colorBlueDidik.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mainColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 34,
              width: 34,
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: colorGoldButton,
              ),
              child: Image.asset('assets/icons/homePage/announcement.png'),
            ),
            const SizedBox(width: AppDesign.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Announcement',
                    style: TextStyle(
                      color: mainColor,
                      fontFamily: fontFamilyMain,
                      fontSize: AppDesign.captionSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    announcement,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: colorBlack,
                      fontFamily: fontFamilyMain,
                      fontSize: AppDesign.captionSize,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDesign.spaceXs),
            IconButton(
              onPressed: () => setState(() => isClose = true),
              icon: const Icon(Icons.close_rounded),
              color: colorRedDark,
              iconSize: 19,
              visualDensity: VisualDensity.compact,
              tooltip: 'Dismiss announcement',
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    Widget? leading,
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        marginHorizontal,
        AppDesign.spaceLg,
        marginHorizontal,
        AppDesign.spaceMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            SizedBox(width: 24, height: 24, child: leading),
            const SizedBox(width: AppDesign.spaceSm),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: colorBlack,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.sectionTitleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onViewAll != null) _viewAllAction(onViewAll),
        ],
      ),
    );
  }

  Widget _viewAllAction(VoidCallback onTap) {
    return Material(
      color: colorTransparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colorBlueDidik.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View all',
                style: TextStyle(
                  color: mainColor,
                  fontFamily: fontFamilyMain,
                  fontSize: AppDesign.captionSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: AppDesign.spaceXs),
              Icon(Icons.arrow_forward_rounded, color: mainColor, size: 15),
            ],
          ),
        ),
      ),
    );
  }

  // Upcoming event body
  Widget _buildUpcomingEvent(HomeState state) {
    if (upcoming.isEmpty) {
      return Container();
    }

    /* IF API call success and not empty, show listView If Perks section*/
    return Container(
      color: colorBackground,
      height: ScreenSize.height * 0.2,
      padding: EdgeInsets.only(top: 5),
      child: Column(
        children: [
          _sectionHeader(
            title: 'Upcoming Events',
            leading: Image.asset('assets/icons/homePage/event.webp'),
            onViewAll:
                () => Navigator.of(context).pushNamed(OderRoutes.upcoming),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: marginHorizontal),
              itemCount: upcoming.length,
              // physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      OderRoutes.bulletinDetails,
                      arguments: BulletinDetailsParameters(
                        bulletinId: upcoming[index].id.toString(),
                        title: upcoming[index].name!,
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right:
                          index == upcoming.length - 1 ? 0 : AppDesign.spaceMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: ScreenSize.width * 0.28,
                          color: colorBackground,
                          child: AspectRatio(
                            aspectRatio: 1 / 1,
                            // child: InkWell(
                            child: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorGreyBox),
                              ),
                              child: _homeImage(upcoming[index].image),
                            ),
                            // ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Merchant body
  Widget _buildTopBrand(HomeState state) {
    if (merchants.isEmpty) {
      return Container();
    }

    /* IF API call success and not empty, show listView If Perks section*/
    return Container(
      color: colorBackground,
      height: ScreenSize.height * 0.24,
      padding: EdgeInsets.only(top: 5),
      //============================================== need cange to listview
      child: Column(
        children: [
          _sectionHeader(
            title: 'Top Brands',
            leading: Image.asset('assets/icons/homePage/top.webp'),
            onViewAll: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                OderRoutes.orderingMerchant,
                (Route<dynamic> route) => false,
                arguments: OrderingScreenParameters(selectedTab: 0),
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: marginHorizontal),
              itemCount: merchants.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Storage().brandName = merchants[index].name;
                    Navigator.of(context)
                        .pushNamed(
                          OderRoutes.orderingOutlet,
                          arguments: OrderingOutletParameters(
                            brandsId: merchants[index].id.toString(),
                          ),
                        )
                        .then((value) {});
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right:
                          index == merchants.length - 1 ? 0 : AppDesign.spaceMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: ScreenSize.width * 0.28,
                          color: colorBackground,
                          child: AspectRatio(
                            aspectRatio: 1 / 1,
                            // child: InkWell(
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colorGreyBox),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _homeImage(merchants[index].image),
                                  ),
                                ),
                                merchants[index].isMuslim == true
                                    ? Positioned(
                                      right: 5,
                                      top: 5,
                                      child: HalalWidget(
                                        muslimCategory:
                                            merchants[index].muslimCategory!,
                                        width: ScreenSize.width * 0.08,
                                      ),
                                    )
                                    : SizedBox(),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: ScreenSize.width * 0.24,
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            merchants[index].name!,
                            style: TextStyle(
                              fontSize: AppDesign.smallSize,
                              fontWeight: FontWeight.w400,
                              fontFamily: fontFamilyMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Categry voucher body
  Widget _buildCategoryVoucher(index) {
    final category = categories[index];
    catVouchers = category.vouchers ?? const [];

    if (catVouchers.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: ScreenSize.height * 0.25,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: category.name ?? 'Vouchers',
            leading: _homeImage(category.image, fit: BoxFit.contain),
            onViewAll: () => _openCategory(category),
          ),
          Expanded(child: _buildVoucher(context, catVouchers)),
        ],
      ),
    );
  }

  Widget _homeImage(String? url, {BoxFit fit = BoxFit.cover}) {
    final imagePath = url?.trim() ?? '';
    if (imagePath.isEmpty) {
      return Image.asset('assets/icons/no_photo.webp', fit: fit);
    }
    return CachedNetworkImage(
      imageUrl: imagePath,
      fit: fit,
      placeholder:
          (context, url) => Container(
            color: colorLightGray,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget:
          (context, url, error) =>
              Image.asset('assets/icons/no_photo.webp', fit: fit),
    );
  }

  Widget _buildVoucher(BuildContext context, List<VouchersCat> catVoucher) {
    // final cardWidth = (ScreenSize.width * 0.33).clamp(116.0, 148.0).toDouble();
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        marginHorizontal,
        0,
        marginHorizontal,
        AppDesign.spaceSm,
      ),
      itemCount: catVoucher.length,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      separatorBuilder:
          (context, index) => const SizedBox(width: AppDesign.spaceMd),
      itemBuilder: (context, indexCat) {
        final voucher = catVoucher[indexCat];
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            TempData.voucherRefCode = '';
            Navigator.of(context).pushNamed(
              OderRoutes.rewardDetails,
              arguments: RewardDetailsParameters(
                rewardId: voucher.id ?? '',
                title: voucher.name ?? 'Voucher',
                indexPage: 3,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: ScreenSize.width * 0.28,
                color: colorBackground,
                child: AspectRatio(
                  aspectRatio: 1 / 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      // fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: colorGreyBox),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _homeImage(voucher.image),
                          ),
                        ),
                        if (voucher.isMuslim == true)
                          Positioned(
                            right: 5,
                            top: 5,
                            child: HalalWidget(
                              muslimCategory: voucher.muslimCategory ?? '',
                              width: ScreenSize.width * 0.08,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              Container(
                width: ScreenSize.width * 0.24,
                padding: EdgeInsets.only(top: 5),
                // padding: const EdgeInsets.fromLTRB(2, AppDesign.spaceSm, 2, 0),
                child: Text(
                  voucher.name ?? 'Voucher',
                  style: const TextStyle(
                    color: colorBlack,
                    fontSize: AppDesign.smallSize,
                    fontWeight: FontWeight.w500,
                    fontFamily: fontFamilyMain,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Highlight/ bulletin body
  Widget _buildHighlight() {
    if (highlight.isEmpty) {
      return Container();
    }

    final cardWidth = (ScreenSize.width * 0.72).clamp(250.0, 330.0).toDouble();

    return Container(
      color: colorBackground,
      padding: const EdgeInsets.only(bottom: AppDesign.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Highlights',
            leading: Image.asset('assets/icons/homePage/highlight.webp'),
            onViewAll:
                () => Navigator.of(context).pushNamed(OderRoutes.bulletin),
          ),
          SizedBox(
            height: ScreenSize.height * 0.25,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: marginHorizontal),
              itemCount: highlight.length,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              separatorBuilder:
                  (context, index) => const SizedBox(width: AppDesign.spaceLg),
              itemBuilder: (context, index) {
                final item = highlight[index];
                return SizedBox(
                  width: cardWidth,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        OderRoutes.bulletinDetails,
                        arguments: BulletinDetailsParameters(
                          bulletinId: item.id ?? '',
                          title: item.name ?? 'Highlight',
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 2 / 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: colorGreyBox),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: _homeImage(item.image),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 9,
                            left: 2,
                            right: 2,
                          ),
                          child: Text(
                            item.name ?? 'Highlight',
                            style: const TextStyle(
                              color: colorBlack,
                              fontSize: AppDesign.smallSize,
                              fontWeight: FontWeight.w500,
                              fontFamily: fontFamilyMain,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // View all bottom body
  void modalBottomSheetMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorTransparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) {
        final maxSheetHeight = ScreenSize.height * 0.72;
        final maxContentHeight = (maxSheetHeight - 80).clamp(
          180.0,
          maxSheetHeight,
        );
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: Container(
              decoration: const BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  AppDesign.spaceMd,
                  20,
                  AppDesign.spaceMd,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorDisableGrey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceMd),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Explore',
                            style: TextStyle(
                              color: colorBlack,
                              fontFamily: fontFamilyMain,
                              fontSize: AppDesign.sectionTitleSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                          color: colorRedDark,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: maxContentHeight.toDouble(),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(
                            bottom: AppDesign.spaceLg,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (categories.isNotEmpty) ...[
                                _sheetSectionTitle('Categories'),
                                _sheetGrid([
                                  _buildTopBrandsItem(),
                                  ...categories.map(_buildCategoryItem),
                                ]),
                              ],
                              if (miniProgram.isNotEmpty) ...[
                                _sheetSectionTitle('Services'),
                                _sheetGrid(
                                  miniProgram
                                      .map(_buildMiniProgramItem)
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDesign.spaceSm, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: mainColor,
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.bodySize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sheetGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 76).floor().clamp(3, 6);
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 12,
          children:
              children
                  .map((child) => SizedBox(width: width, child: child))
                  .toList(),
        );
      },
    );
  }
}
