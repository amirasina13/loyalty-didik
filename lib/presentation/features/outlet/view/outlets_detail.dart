import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:map_launcher/map_launcher.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../../util/utils.dart';
import '../../../widgets/extensions/outlet_operation_view.dart';
import '../../../widgets/extensions/outlet_voucher_view.dart';
import '../../../widgets/widgets.dart';
import '../../ordering/ordering.dart';
import '../../rewards/reward.dart';
import '../../voucher/voucher.dart';
import '../outlet.dart';

class OutletDetailsView extends StatefulWidget {
  final Function? changeView;
  final String? outletId;

  const OutletDetailsView({super.key, this.changeView, this.outletId});

  @override
  State<OutletDetailsView> createState() => _OutletDetailsViewState();
}

class _OutletDetailsViewState extends State<OutletDetailsView>
    with TickerProviderStateMixin {
  bool isProcessing = false;
  bool isFavouriteClick = false;
  bool isFavClick = false;
  List<Operation> operations = [];
  List<VoucherOutlet> outletVoucher = [];
  List<OutletFav> outletFav = [];
  // int _current = 0;
  late TabController _tabController;
  late ScrollController _scrollController;
  // final CarouselController _controller = CarouselController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);

    _tabController.addListener(() {
      setState(() {
        // _selectedIndex = _tabController.index;
        _tabController.index;
      });
    });
  }

  /* --------------------------------------------------------------------------- dispose - Called when this object is removed from the tree permanently. */
  @override
  void dispose() {
    super.dispose();

    _scrollController.dispose();
  }

  Future _refreshData() async {
    await Future.delayed(Duration(seconds: 1));
    BlocProvider.of<OutletBloc>(
      // ignore: use_build_context_synchronously
      context,
    ).add(OutletDetailsLoad(outletId: widget.outletId!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: Container(
        color: colorBackground,
        // margin: EdgeInsets.symmetric(horizontal: marginHorizontal),
        child: BlocConsumer<OutletBloc, OutletState>(
          listener: (context, state) {
            if (state is OutletDetailsLoaded) {
              isFavClick = false;
              //   isFavouriteClick = state.details.isFavourite!;
              //   // print('CALL LISTENER: ${state.details}');
              //   debugPrint('CALL LISTENER: ${state.details}');
            }
          },
          builder: (context, state) {
            if (state is OutletDetailsLoaded) {
              var detail = state.details;
              var outletId = detail.id;
              var distance =
                  Storage().distance!.isNotEmpty ? Storage().distance : '0';
              var dist = double.parse(distance!);
              var operation = state.details.operations!.length;
              var availableVoucher = state.details.vouchers!.length;
              isFavouriteClick = detail.isFavourite!;

              if (outletId != null) {
                return _buildModernOutletPage(context, detail);
                // ignore: dead_code
                return RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refreshData,
                  child: NestedScrollView(
                    controller: _scrollController,
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        /* ----------------------------------------------------------------- Tabbar section */
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: SliverAppBarDelegate(
                            minHeight: ScreenSize.height * 0.06,
                            maxHeight: ScreenSize.height * 0.06,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorBackground,
                                border: Border(
                                  bottom: BorderSide(color: colorGreyBox),
                                ),
                              ),
                              child: TabBar(
                                // isScrollable: true,
                                controller: _tabController,
                                unselectedLabelColor: Color(0xFF929292),
                                unselectedLabelStyle: TextStyle(
                                  fontSize: AppDesign.smallSize,
                                  fontFamily: fontFamilyMain,
                                  fontWeight: FontWeight.w600,
                                ),
                                labelColor: colorBlack,
                                labelStyle: TextStyle(
                                  fontSize: AppDesign.smallSize,
                                  fontFamily: fontFamilyMain,
                                  fontWeight: FontWeight.w600,
                                ),
                                indicatorColor: colorMulberry,
                                indicatorWeight: 5,
                                labelPadding: EdgeInsets.symmetric(
                                  horizontal: 0.0,
                                ),
                                tabs: [
                                  Tab(
                                    // text: 'My Vo/ucher',
                                    child: Container(
                                      alignment: Alignment.center,
                                      color: colorTransparent,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: ScreenSize.width * 0.05,
                                            margin: EdgeInsets.only(right: 3),
                                            child: Image(
                                              image: AssetImage(
                                                'assets/icons/outlet/about_tab.png',
                                              ),
                                              color:
                                                  _tabController.index == 0
                                                      ? colorBlack
                                                      : null,
                                            ),
                                          ),
                                          Text(
                                            'About',
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    // text: 'Subscription Plan',
                                    child: Container(
                                      color: colorTransparent,
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: ScreenSize.width * 0.05,
                                            margin: EdgeInsets.only(right: 3),
                                            child: Image(
                                              image: AssetImage(
                                                'assets/icons/outlet/deals_tab.png',
                                              ),
                                              color:
                                                  _tabController.index == 1
                                                      ? colorBlack
                                                      : null,
                                            ),
                                          ),
                                          Text(
                                            'Deals',
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ];
                    },
                    /* ------------------------------------------------------------------- Body Sliver */
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        SingleChildScrollView(
                          child: Container(
                            // height: height * 0.12,
                            color: colorBackground,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      // color: colorBabyBlue,
                                      margin: EdgeInsets.only(bottom: 5),
                                      height: ScreenSize.width * 0.46,
                                      child: CachedImage(
                                        imageUrl: detail.image!,
                                        boxFit: BoxFit.cover,
                                      ),
                                    ),
                                    BlocConsumer<OrderingBloc, OrderingState>(
                                      listener: (context, state) {
                                        if (state is FavouriteAddRemove) {
                                          setState(() {
                                            // isFavouriteClick =
                                            //     state.favOutlet['data']
                                            //         ['isFavourite'];

                                            BlocProvider.of<OutletBloc>(context)
                                              ..isReload = true
                                              ..add(
                                                OutletDetailsLoad(
                                                  outletId: widget.outletId!,
                                                ),
                                              );
                                          });
                                        }
                                      },
                                      builder: (context, state) {
                                        return Positioned(
                                          top: 27,
                                          right: 30,
                                          // bottom: -5,
                                          // right: 10,
                                          child: InkWell(
                                            child: Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: colorBackground,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: colorGreyBorder,
                                                ),
                                              ),
                                              child:
                                                  isFavClick == false
                                                      ? isFavouriteClick ==
                                                              false
                                                          // outletFav.any(
                                                          //         (e) => e.id == outletId)
                                                          ? Icon(
                                                            Icons
                                                                .favorite_border,
                                                            size: 28,
                                                            color:
                                                                colorCountGrey,
                                                          )
                                                          : Icon(
                                                            Icons.favorite,
                                                            size: 28,
                                                            color:
                                                                colorRaspberyRed,
                                                          )
                                                      : Container(
                                                        padding: EdgeInsets.all(
                                                          2,
                                                        ),
                                                        width:
                                                            ScreenSize.width *
                                                            0.063,
                                                        height:
                                                            ScreenSize.width *
                                                            0.063,
                                                        child:
                                                            CircularProgressIndicator(
                                                              color: colorSoftGrey
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                            ),
                                                      ),
                                            ),
                                            onTap: () {
                                              if (isFavClick) return;
                                              setState(() {
                                                isFavClick = true;

                                                Storage().page =
                                                    'outlet_details';
                                                BlocProvider.of<OrderingBloc>(
                                                  context,
                                                ).add(
                                                  OutletAddRemoveFavouriteLoad(
                                                    outletId:
                                                        widget.outletId
                                                            .toString(),
                                                    merchantId:
                                                        detail.merchantId
                                                            .toString(),
                                                  ),
                                                );
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: marginHorizontal,
                                    vertical: AppDesign.spaceLg,
                                  ),
                                  child:
                                      detail.links!.isNotEmpty
                                          ? Row(
                                            children: [
                                              Expanded(
                                                child: InkWell(
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: colorGoldButton,
                                                      border: Border.all(
                                                        color: colorWhite,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: colorGreyBox,
                                                          blurRadius: 3.0,
                                                          offset: Offset(
                                                            0.0,
                                                            2.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          height:
                                                              ScreenSize
                                                                  .height *
                                                              0.02,
                                                          padding:
                                                              EdgeInsets.only(
                                                                right: 5,
                                                              ),
                                                          child: Image(
                                                            image: AssetImage(
                                                              'assets/icons/location/map_pin.webp',
                                                            ),
                                                            color: colorBlack,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Map',
                                                          style: TextStyle(
                                                            fontSize:
                                                                AppDesign
                                                                    .bodySize,
                                                            fontFamily:
                                                                fontFamilyMain,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                colorOutletAddressLabelGrey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    launchMapDirection(detail);
                                                  },
                                                ),
                                              ),
                                              SizedBox(
                                                width: ScreenSize.width * 0.05,
                                              ),
                                              Expanded(
                                                child: InkWell(
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: colorDeliveryGreen,
                                                      border: Border.all(
                                                        color: colorWhite,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: colorGreyBox,
                                                          blurRadius: 3.0,
                                                          offset: Offset(
                                                            0.0,
                                                            2.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          height:
                                                              ScreenSize
                                                                  .height *
                                                              0.02,
                                                          padding:
                                                              EdgeInsets.only(
                                                                right: 5,
                                                              ),
                                                          child: Image(
                                                            image: AssetImage(
                                                              'assets/icons/location/delivery.webp',
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          'Delivery',
                                                          style: TextStyle(
                                                            fontSize:
                                                                AppDesign
                                                                    .bodySize,
                                                            fontFamily:
                                                                fontFamilyMain,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: colorWhite,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    launchDelivery(
                                                      context,
                                                      detail,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          )
                                          : Container(
                                            width:
                                                ScreenSize.width / 2 -
                                                ScreenSize.width * 0.04,
                                            padding: EdgeInsets.all(3),
                                            alignment: Alignment.centerRight,
                                            child: InkWell(
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorGoldButton,
                                                  border: Border.all(
                                                    color: colorWhite,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: colorGreyBox,
                                                      blurRadius: 3.0,
                                                      offset: Offset(0.0, 2.0),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      height:
                                                          ScreenSize.height *
                                                          0.02,
                                                      padding: EdgeInsets.only(
                                                        right: 5,
                                                      ),
                                                      child: Image(
                                                        image: AssetImage(
                                                          'assets/icons/location/map_pin.webp',
                                                        ),
                                                        color: colorBlack,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Map',
                                                      style: TextStyle(
                                                        fontSize:
                                                            AppDesign.bodySize,
                                                        fontFamily:
                                                            fontFamilyMain,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            colorOutletAddressLabelGrey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              onTap: () {
                                                launchMapDirection(detail);
                                              },
                                            ),
                                          ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: marginHorizontal,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(
                                                top: 10,
                                                bottom: 5,
                                              ),
                                              child: Text(
                                                detail.merchantName!,
                                                style: TextStyle(
                                                  color: colorBlack,
                                                  fontFamily: fontFamilyMain,
                                                  fontSize:
                                                      AppDesign.bodyLargeSize,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                textAlign: TextAlign.center,
                                                textScaler: TextScaler.linear(
                                                  scaleFactor,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              detail.place!,
                                              style: TextStyle(
                                                color: colorBlack,
                                                fontFamily: fontFamilyMain,
                                                fontSize:
                                                    AppDesign.bodyLargeSize,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              // textAlign: TextAlign.center,
                                              textScaler: TextScaler.linear(
                                                scaleFactor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      dist == 0
                                          ? SizedBox()
                                          : Text(
                                            '${dist.toStringAsFixed(2)} km',
                                            style: TextStyle(
                                              fontSize: AppDesign.captionSize,
                                              color: colorTextGrey,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: fontFamilyMain,
                                            ),
                                            textScaler: TextScaler.linear(
                                              scaleFactor,
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.fromLTRB(
                                    marginHorizontal,
                                    20,
                                    marginHorizontal,
                                    20,
                                  ),
                                  child: HtmlWidget(
                                    detail.merchantDesc!,
                                    onTapUrl:
                                        (url) => openInAppWebView(
                                          context,
                                          url,
                                          title: 'Merchant details',
                                        ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    marginHorizontal,
                                    20,
                                    marginHorizontal,
                                    10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: ScreenSize.height * 0.02,
                                        margin: EdgeInsets.only(right: 20),
                                        color: colorTransparent,
                                        child: Image(
                                          image: AssetImage(
                                            'assets/icons/outlet/location.png',
                                          ),
                                          color: colorBlackTab,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          detail.address!,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colorBlackTab,
                                            fontFamily: fontFamilyMain,
                                            fontSize: AppDesign.bodySize,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.start,
                                          textScaler: TextScaler.linear(
                                            scaleFactor,
                                          ),
                                          maxLines: 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  // margin: EdgeInsets.only(top: 10),
                                  padding: EdgeInsets.fromLTRB(
                                    marginHorizontal,
                                    10,
                                    marginHorizontal,
                                    10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: ScreenSize.height * 0.02,
                                        margin: EdgeInsets.only(right: 20),
                                        color: colorTransparent,
                                        child: Image(
                                          image: AssetImage(
                                            'assets/icons/outlet/contact.png',
                                          ),
                                          color: colorBlackTab,
                                        ),
                                      ),
                                      Text(
                                        detail.contact!,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colorBlackTab,
                                          fontFamily: fontFamilyMain,
                                          fontSize: AppDesign.bodySize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.start,
                                        textScaler: TextScaler.linear(
                                          scaleFactor,
                                        ),
                                        maxLines: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.fromLTRB(
                                    marginHorizontal,
                                    10,
                                    marginHorizontal,
                                    20,
                                  ),
                                  // height: height * 0.2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: ScreenSize.height * 0.02,
                                        margin: EdgeInsets.only(right: 20),
                                        color: colorTransparent,
                                        child: Image(
                                          image: AssetImage(
                                            'assets/icons/outlet/time.png',
                                          ),
                                          color: colorBlackTab,
                                        ),
                                      ),
                                      operation != 0
                                          ? Expanded(
                                            child: Container(
                                              child: _buildOperationListView(
                                                context,
                                                state,
                                              ),
                                            ),
                                          )
                                          : Container(
                                            margin: EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                                // ),
                              ],
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          child:
                              availableVoucher != 0
                                  ? Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: 20,
                                      horizontal: marginHorizontal,
                                    ),
                                    child: _buildOutletVoucherListView(
                                      context,
                                      state,
                                    ),
                                  )
                                  : SizedBox(
                                    height: ScreenSize.height * 0.7,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: ScreenSize.width * 0.2,
                                          width: ScreenSize.width * 0.2,
                                          // margin: EdgeInsets.only(top: height / AppDesign.spaceXs),
                                          padding: EdgeInsets.symmetric(
                                            vertical:
                                                ScreenSize.height /
                                                AppDesign.spaceSm,
                                            horizontal: ScreenSize.width,
                                          ),
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                              fit: BoxFit.contain,
                                              image: AssetImage(
                                                'assets/icons/outlet/no_merchant_voucher.webp',
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: ScreenSize.height * 0.03,
                                        ),
                                        Text(
                                          "No Voucher Yet",
                                          style: TextStyle(
                                            fontSize: AppDesign.smallSize,
                                            fontWeight: FontWeight.w300,
                                            color: colorNoVoucherGrey,
                                          ),
                                          textAlign: TextAlign.center,
                                          textScaler: TextScaler.linear(
                                            scaleFactor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container();
            }
            return Container(
              height: ScreenSize.height * 0.8,
              width: MediaQuery.of(context).size.width,
              color: colorWhite,
              child: Center(
                child: CircularProgressIndicator(color: colorDisableGrey),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernOutletPage(BuildContext context, OutletDetails detail) {
    return BlocListener<OrderingBloc, OrderingState>(
      listener: (context, state) {
        if (state is FavouriteAddRemove) {
          context.read<OutletBloc>()
            ..isReload = true
            ..add(OutletDetailsLoad(outletId: widget.outletId!));
        }
        if (state is OrderingError ||
            state is OrderingNetworkError ||
            state is OrderingSessionError ||
            state is OrderingMaintenanceError) {
          if (mounted) setState(() => isFavClick = false);
        }
      },
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _buildModernOutletHeader(context, detail),
            _buildModernOutletMap(context, detail),
            _buildModernOutletIdentity(detail),
            _buildModernOutletTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildModernOutletAbout(context, detail),
                  _buildModernOutletDeals(context, detail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernOutletHeader(BuildContext context, OutletDetails detail) {
    final palette = AppDesign.outletDetails;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesign.spaceLg,
        AppDesign.spaceSm,
        AppDesign.spaceLg,
        AppDesign.spaceSm,
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            _OutletHeaderCircleButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onTap: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text(
                (detail.place?.trim().isNotEmpty ?? false)
                    ? detail.place!.trim()
                    : 'Outlet details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.text,
                  fontFamily: fontFamilyMain,
                  fontSize: AppDesign.titleSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 46),
          ],
        ),
      ),
    );
  }

  Widget _buildModernOutletMap(BuildContext context, OutletDetails detail) {
    final palette = AppDesign.outletDetails;
    final imageUrl = detail.image?.trim() ?? '';
    return Container(
      height: MediaQuery.of(context).size.width * 0.42,
      margin: const EdgeInsets.fromLTRB(
        AppDesign.spaceLg,
        2,
        AppDesign.spaceLg,
        AppDesign.spaceLg,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl.isEmpty
              ? Icon(
                Icons.location_city_rounded,
                color: palette.action,
                size: 62,
              )
              : CachedImage(imageUrl: imageUrl, boxFit: BoxFit.cover),
        ],
      ),
    );
  }

  Widget _buildModernOutletIdentity(OutletDetails detail) {
    final palette = AppDesign.outletDetails;
    final merchantName = _displayValue(detail.merchantName, 'Merchant');
    final outletName = _displayValue(detail.place, 'Outlet');
    final distance = _formatOutletDistance(Storage().distance);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, AppDesign.spaceLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outletName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.sectionTitleSize,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppDesign.spaceXs),
                Text(
                  merchantName,
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
            ),
          ),
          if (distance.isNotEmpty)
            Text(
              distance,
              style: TextStyle(
                color: palette.muted,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.captionSize,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernOutletTabs() {
    final palette = AppDesign.outletDetails;
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: AppDesign.spaceLg),
      padding: const EdgeInsets.all(AppDesign.spaceXs),
      decoration: BoxDecoration(
        color: colorBlueDidik.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(21),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: colorTransparent,
        overlayColor: const WidgetStatePropertyAll(colorTransparent),
        labelColor: palette.action,
        unselectedLabelColor: palette.muted,
        labelStyle: TextStyle(
          color: palette.action,
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.smallSize,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          color: palette.muted,
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.smallSize,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [Tab(text: 'About'), Tab(text: 'Deals')],
      ),
    );
  }

  Widget _buildModernOutletAbout(BuildContext context, OutletDetails detail) {
    final palette = AppDesign.outletDetails;
    final bottomContentPadding = MediaQuery.paddingOf(context).bottom + 120;
    final description = detail.merchantDesc?.trim() ?? '';
    final address = detail.address?.trim() ?? '';
    final contact = detail.contact?.trim() ?? '';
    final openingHours = _openingHours(detail.operations);
    final hasLinks = detail.links?.isNotEmpty == true;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        AppDesign.spaceXl,
        20,
        bottomContentPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABOUT THE OUTLET',
            style: TextStyle(
              color: palette.action,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.captionSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppDesign.spaceMd),
          Text(
            _displayValue(detail.place, 'Outlet'),
            style: TextStyle(
              color: palette.text,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.sectionTitleSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppDesign.spaceMd),
            HtmlWidget(
              description,
              onTapUrl:
                  (url) => openInAppWebView(
                    context,
                    url,
                    title: _displayValue(detail.place, 'Outlet'),
                  ),
              textStyle: TextStyle(
                color: palette.text,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.bodySize,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: AppDesign.spaceLg),
          DirectoryInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: address,
          ),
          DirectoryInfoRow(
            icon: Icons.schedule_outlined,
            label: 'Opening hours',
            value: openingHours,
          ),
          if (contact.isNotEmpty)
            DirectoryInfoRow(
              icon: Icons.phone_outlined,
              label: 'Contact',
              value: contact,
            ),
          const SizedBox(height: AppDesign.spaceLg),
          _buildModernOutletActions(context, detail),
          if (hasLinks) ...[
            const SizedBox(height: AppDesign.spaceLg),
            _buildOrderViaButton(context, detail),
          ],
        ],
      ),
    );
  }

  Widget _buildModernOutletActions(BuildContext context, OutletDetails detail) {
    final palette = AppDesign.outletDetails;
    return Row(
      children: [
        Expanded(
          child: _OutletActionButton(
            icon: Icons.directions_outlined,
            label: 'Directions',
            onTap: () => launchMapDirection(detail),
            palette: palette,
          ),
        ),
        const SizedBox(width: 9),
        if (detail.contact?.trim().isNotEmpty == true)
          Expanded(
            child: _OutletActionButton(
              icon: Icons.call_outlined,
              label: 'Call',
              onTap: () => _callOutlet(detail),
              palette: palette,
            ),
          ),
        if (detail.contact?.trim().isNotEmpty == true) const SizedBox(width: 9),
        Expanded(
          child: _OutletActionButton(
            icon:
                isFavouriteClick
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
            label: 'Save',
            loading: isFavClick,
            active: isFavouriteClick,
            onTap: isFavClick ? null : () => _toggleOutletFavourite(detail),
            palette: palette,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderViaButton(BuildContext context, OutletDetails detail) {
    final palette = AppDesign.outletDetails;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => launchDelivery(context, detail),
        icon: Icon(Icons.delivery_dining_outlined, color: palette.action),
        label: Text(
          'Order via',
          style: TextStyle(
            color: palette.action,
            fontFamily: fontFamilyMain,
            fontSize: AppDesign.bodySize,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildModernOutletDeals(BuildContext context, OutletDetails detail) {
    final palette = AppDesign.outletDetails;
    final bottomContentPadding = MediaQuery.paddingOf(context).bottom + 120;
    final vouchers = (detail.vouchers ?? const <VoucherOutlet>[])
        .where((voucher) => voucher.purchaseMethod != 'redeemable')
        .toList(growable: false);

    if (vouchers.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, AppDesign.spaceXl, 20, 35),
        child: AccountEmptyState(
          palette: palette,
          title: 'No deals yet',
          message: 'This outlet has no available deals right now.',
          asset: 'assets/icons/outlet/no_merchant_voucher.webp',
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppDesign.spaceLg,
        10,
        AppDesign.spaceLg,
        bottomContentPadding,
      ),
      itemCount: vouchers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final voucher = vouchers[index];
        return voucher.getOutletVoucherTile(
          context: context,
          onTap: () {
            if (voucher.isSoldOut == true || voucher.id == null) return;
            setProcessingStatus(true);
            Navigator.of(context)
                .pushNamed(
                  OderRoutes.rewardDetails,
                  arguments: RewardDetailsParameters(
                    rewardId: voucher.id!,
                    title: detail.merchantName ?? '',
                    indexPage: 3,
                  ),
                )
                .then((value) => setProcessingStatus(false));
          },
        );
      },
    );
  }

  void _toggleOutletFavourite(OutletDetails detail) {
    // Guard synchronously as well as disabling the button. Two taps can arrive
    // before Flutter rebuilds the button, so the callback itself must be safe.
    if (isFavClick) return;
    setState(() => isFavClick = true);
    Storage().page = 'outlet_details';
    context.read<OrderingBloc>().add(
      OutletAddRemoveFavouriteLoad(
        outletId: widget.outletId ?? '',
        merchantId: (detail.merchantId ?? '').toString(),
      ),
    );
  }

  Future<void> _callOutlet(OutletDetails detail) async {
    final contact = detail.contact?.trim() ?? '';
    if (contact.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: contact));
  }

  String _displayValue(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _openingHours(List<Operation>? values) {
    final rows = (values ?? const <Operation>[])
        .where((item) => (item.dayName?.trim().isNotEmpty ?? false))
        .take(4)
        .map((item) {
          final day = item.dayName!.trim();
          final start = item.start?.trim() ?? '';
          final end = item.end?.trim() ?? '';
          final hours =
              start.isEmpty && end.isEmpty
                  ? 'Closed'
                  : end.isEmpty
                  ? start
                  : '$start – $end';
          return '$day: $hours';
        })
        .toList(growable: false);
    return rows.join('\n');
  }

  String _formatOutletDistance(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return '';
    return '${parsed.toStringAsFixed(2)} km';
  }

  Widget _buildOperationListView(BuildContext context, OutletState state) {
    if (state is OutletDetailsLoaded) {
      operations = state.details.operations!;

      var operationTiles = operations
          .map(
            (operation) => operation.getOutletOperationTile(context: context),
          )
          .toList(growable: false);

      return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: operations.length,
        itemBuilder: (context, index) {
          return operationTiles[index];
        },
        // ),
      );
    }
    return Container();
  }

  Widget _buildOutletVoucherListView(BuildContext context, OutletState state) {
    if (state is OutletDetailsLoaded) {
      // outletVoucher = state.details.vouchers!;

      outletVoucher =
          state.details.vouchers!
              .where((voucher) => voucher.purchaseMethod != 'redeemable')
              .toList();

      var voucherTiles = outletVoucher
          .map(
            (outletVoucher) => outletVoucher.getOutletVoucherTile(
              context: context,
              onTap: () {
                setProcessingStatus(true);

                Navigator.of(context)
                    .pushNamed(
                      OderRoutes.rewardDetails,
                      arguments: RewardDetailsParameters(
                        rewardId: outletVoucher.id!,
                        title: state.details.merchantName!,
                        indexPage: 3,
                      ),
                    )
                    .then((value) {
                      setProcessingStatus(false);
                    });
              },
            ),
          )
          .toList(growable: false);

      return outletVoucher.isNotEmpty
          ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: outletVoucher.length,
            itemBuilder: (context, index) {
              return voucherTiles[index];
            },
            // ),
          )
          : SizedBox(
            height: ScreenSize.height * 0.7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: ScreenSize.width * 0.2,
                  width: ScreenSize.width * 0.2,
                  // margin: EdgeInsets.only(top: height / AppDesign.spaceXs),
                  padding: EdgeInsets.symmetric(
                    vertical: ScreenSize.height / AppDesign.spaceSm,
                    horizontal: ScreenSize.width,
                  ),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.contain,
                      image: AssetImage(
                        'assets/icons/outlet/no_merchant_voucher.webp',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ScreenSize.height * 0.03),
                Text(
                  "No Voucher Yet",
                  style: TextStyle(
                    fontSize: AppDesign.smallSize,
                    fontWeight: FontWeight.w300,
                    color: colorNoVoucherGrey,
                  ),
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.linear(scaleFactor),
                ),
              ],
            ),
          );
    }
    return Container();
  }

  launchMapDirection(OutletDetails detail) async {
    final availableMaps = await MapLauncher.installedMaps;

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height:
                    availableMaps.length > 1
                        ? ScreenSize.height * 0.35
                        : ScreenSize.height * 0.25,
                padding: EdgeInsets.fromLTRB(10, AppDesign.spaceXxl, 10, 20),
                child: CustomScrollView(
                  primary: false,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: ScreenSize.width,
                            padding: EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 20,
                            ),
                            color: colorBackground,
                            child: Text('Open with: '),
                          ),
                          Container(
                            padding: EdgeInsets.only(bottom: 20),
                            color: colorBackground,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Wrap(
                                  children: <Widget>[
                                    for (var map in availableMaps)
                                      ListTile(
                                        onTap:
                                            () => map.showDirections(
                                              destination: Coords(
                                                double.parse(detail.latitude!),
                                                double.parse(detail.longitude!),
                                              ),
                                              destinationTitle: detail.address,
                                              // origin: Coords(),
                                              // waypoints:
                                              directionsMode:
                                                  DirectionsMode.driving,
                                            ),
                                        title: Text(map.mapName),
                                        leading: SvgPicture.asset(
                                          map.icon,
                                          height: 30.0,
                                          width: 30.0,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> launchDelivery(
    BuildContext context,
    OutletDetails detail,
  ) async {
    final palette = AppDesign.outletDetails;
    final links = detail.links ?? const <DeliveryLink>[];
    final selected = await showAccountSheet<DeliveryLink>(
      context,
      palette,
      Builder(
        builder:
            (sheetContext) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                sheetTitle('Order via', palette),
                const SizedBox(height: AppDesign.spaceSm),
                Text(
                  'Choose where to place your order.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted),
                ),
                const SizedBox(height: AppDesign.spaceXl),
                for (final link in links)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDesign.spaceMd),
                    child: Material(
                      color: colorBlueDidik.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDesign.cardRadius),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDesign.cardRadius,
                          ),
                          side: BorderSide(color: palette.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDesign.spaceLg,
                          vertical: AppDesign.spaceSm,
                        ),
                        leading: SizedBox(
                          width: 40,
                          height: 40,
                          child: switch (link.type) {
                            'Grab' => Image.asset(
                              'assets/icons/location/food_grab.webp',
                            ),
                            'Foodpanda' => Image.asset(
                              'assets/icons/location/food_panda.webp',
                            ),
                            'Whatsapp' => Image.asset(
                              'assets/icons/location/food_ws.webp',
                            ),
                            _ => Icon(
                              Icons.link_rounded,
                              color: palette.action,
                            ),
                          },
                        ),
                        title: Text(
                          switch (link.type) {
                            'Grab' => 'GrabFood',
                            'Foodpanda' => 'foodpanda',
                            'Whatsapp' => 'WhatsApp',
                            'Others' || null || '' => 'Order online',
                            _ => link.type!,
                          },
                          style: TextStyle(
                            color: palette.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: palette.muted,
                        ),
                        onTap: () => Navigator.pop(sheetContext, link),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: TextButton.styleFrom(foregroundColor: palette.action),
                  child: const Text('Cancel'),
                ),
              ],
            ),
      ),
    );
    if (selected == null || !context.mounted) return;
    final uri = Uri.tryParse(selected.url ?? '');
    if (uri == null || !uri.hasScheme) {
      showErrorToast('This ordering link is unavailable.', context);
      return;
    }
    if (selected.type == 'Others') {
      Navigator.push(
        context,
        NoAnimationPageRoute(
          builder:
              (_) => WidgetWebView(
                widgetUrl: uri.toString(),
                title: 'Order online',
              ),
        ),
      );
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        showErrorToast('Unable to open this ordering link.', context);
      }
    } catch (_) {
      if (context.mounted) {
        showErrorToast('Unable to open this ordering link.', context);
      }
    }
  }

  // Future<void> _saveList(favList) async {
  //   await Storage().secureStorage.write(key: 'favList', value: favList);
  // }
}

class _OutletHeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutletHeaderCircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colorBlueDidik.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: AppDesign.outletDetails.text, size: 24),
          ),
        ),
      ),
    );
  }
}

class _OutletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool loading;
  final PagePalette palette;

  const _OutletActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.palette,
    this.active = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon:
          loading
              ? FavouriteLoadingIcon(color: palette.action, size: 19)
              : Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? palette.favButton : palette.text,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: AppDesign.spaceSm),
        side: BorderSide(color: active ? palette.action : palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.captionSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
