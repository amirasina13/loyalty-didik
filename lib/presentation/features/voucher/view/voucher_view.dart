import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../../locator.dart';
import '../../../widgets/widgets.dart';
import '../../authentication/authentication.dart';
import '../../rewards/reward.dart';
import '../voucher.dart';

class VoucherView extends StatefulWidget {
  final Function changeView;
  final int selectedTab;
  final String filterBy;
  final String filterValue;

  const VoucherView({
    super.key,
    required this.changeView,
    required this.selectedTab,
    required this.filterBy,
    required this.filterValue,
  });

  @override
  State<VoucherView> createState() => _VoucherViewState();
}

class _VoucherViewState extends State<VoucherView>
    with SingleTickerProviderStateMixin {
  /* --------------------------------------------------------------------------- set variable */

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<VoucherRewardsTabState> genarateWidgetKey =
      GlobalKey<VoucherRewardsTabState>();

  late TabController _tabController;
  late ScrollController _scrollController;
  String barcodeScanRes = '';
  late Timer durationLoading;
  bool isProcessing = false;
  String? categoryName;
  var formatter = DateFormat(appDateFormat);
  FilterData? filterData;
  bool isSelected = false;
  // int? selectedCategory;
  String updatedFilterBy = '', updatedFilterValue = '';
  bool tabChange = false;

  /* ------------------------------------------------------------------------ */

  MerchantCategory? merchantCategory;
  bool isRefresh = false;
  // late String filterState;
  FilterData? filterState;
  RewardState? updatedState;
  Color buttonColor = colorBlack;
  RewardState? updateEmptyReward;

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  void onSelectionChange(String filterBy, String filterValue) {
    setState(() {
      updatedFilterBy = filterBy;
      updatedFilterValue = filterValue;
    });
  }

  /* --------------------------------------------------------------------------- initState - Called when this object is inserted into the tree */
  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.selectedTab,
    );

    categoryName = 'All';

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    fToast = FToast();
    fToast.init(context);

    updatedFilterBy = widget.filterBy;
    updatedFilterValue = widget.filterValue;
  }

  /* --------------------------------------------------------------------------- dispose - Called when this object is removed from the tree permanently. */
  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /* --------------------------------------------------------------------------- Full body */
  @override
  Widget build(BuildContext context) {
    /* ------------------------------------------------------------------------- Scaffold */
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          OderRoutes.home,
          (Route<dynamic> route) => false,
        );
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: OderScaffold(
          scaffoldKey: _scaffoldKey,
          showAppbar: false,
          bottomMenuIndex: 2,
          isShow: true,
          canClick: false,

          /* ----------------------------------------------------------------------- Main body */
          body: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBarSection(),
                // Use Expanded instead of fixed height Container for responsiveness
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      BlocProvider<RewardBloc>(
                        create:
                            (context) => RewardBloc(
                              context: context,
                              rewardRepository: sl(),
                            ),
                        child: VoucherRewardsTab(
                          filterBy: updatedFilterBy,
                          filterValue: updatedFilterValue,
                        ),
                      ),
                      const MyVoucherTab(),
                      const MyVoucherPastTab(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        AppDesign.spaceLg,
        20,
        AppDesign.spaceLg,
      ),
      child: SizedBox(
        height: 50,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/logo/didik_logo.png',
                      height: 34,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const SizedBox(width: AppDesign.spaceXs),
                  Text('REWARDS', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
            const SizedBox(width: AppDesign.spaceMd),
            _buildScannerButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerButton() {
    return Semantics(
      button: true,
      label: 'Scan promo code',
      child: Material(
        color: secondaryColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            Storage().page = 'voucher';
            scanBarcodeNormal();
          },
          child: SizedBox(
            width: 50,
            height: 50,
            child: Padding(
              padding: const EdgeInsets.all(AppDesign.spaceMd),
              child: Image.asset(
                'assets/icons/global/scanner.webp',
                color: colorWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarSection() {
    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(20, 2, 20, AppDesign.spaceXl),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colorBlueDidik.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: _tabController,
              unselectedLabelColor: AppDesign.deals.muted,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              unselectedLabelStyle: TextStyle(
                fontSize: AppDesign.captionSize,
                fontFamily: fontFamilyMain,
                fontWeight: FontWeight.w500,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 0,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: AppDesign.deals.background,
              ),
              labelColor: AppDesign.deals.action,
              labelPadding: EdgeInsets.zero,
              labelStyle: TextStyle(
                fontSize: AppDesign.captionSize,
                fontFamily: fontFamilyMain,
                fontWeight: FontWeight.w700,
              ),
              onTap: (value) {
                FocusManager.instance.primaryFocus?.unfocus();

                tabChange = true;
                Storage().isTabChange = tabChange;

                setState(() {});
              },
              tabs: [
                const Tab(text: 'Deals'),
                const Tab(text: 'My Vouchers'),
                const Tab(text: 'History'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* --------------------------------------------------------------------------- Scan barcode function */
  Future<void> scanBarcodeNormal() async {
    /* Navigate to scan view page */
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (BuildContext context) =>
                AppBarcodeScannerWidget.defaultStyle(tabFor: 'voucher'),
      ),
      (Route<dynamic> route) => false,
    );
  }

  /* --------------------------------------------------------------------------- Session expired function */
  void sessionExpiredLogOut(String error) {
    /* Show error toast */
    showErrorToast('$error\nYou will be logged out.', context);

    /* Call Authentication logout bloc */
    BlocProvider.of<AuthenticationBloc>(context).add(AuthenticationLoggedOut());

    /* Navigate to login page directly */
    Navigator.of(context).pushNamedAndRemoveUntil(
      OderRoutes.login,
      (Route<dynamic> route) => false,
    );
  }
}

/* ----------------------------------------------------------------------------- MyTabs class */
class MyTabs {
  final String title;
  MyTabs({required this.title});
}

/* ----------------------------------------------------------------------------- SliverAppbarDelegate class */
class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => math.max(maxHeight, minHeight);
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
