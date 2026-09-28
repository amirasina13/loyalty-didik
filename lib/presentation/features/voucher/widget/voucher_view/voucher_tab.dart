import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../../app_setting/app_setting.dart';
import '../../../../../data/data.dart';
import '../../../../widgets/extensions/voucher_list_view.dart';
import '../../../../widgets/widgets.dart';
import '../../../authentication/authentication.dart';
import '../../../maintenance/maintenance.dart';
import '../../../rewards/reward.dart';
import '../../voucher.dart';

class MyVoucherTab extends StatefulWidget {
  const MyVoucherTab({super.key});

  @override
  State<MyVoucherTab> createState() => _MyVoucherTabState();
}

class _MyVoucherTabState extends State<MyVoucherTab>
    with TickerProviderStateMixin {
  FilterData? filterData;

  late TabController _myVoucherTabController;

  final Set<int> visitedVoucherTabs = {};

  final Map<int, VoucherBloc> voucherBlocs = {};

  int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();

    _myVoucherTabController = TabController(length: 0, vsync: this);

    fToast = FToast();
    fToast.init(context);

    final bloc = context.read<RewardBloc>();
    bloc.add(FilterCategoryLoad());
  }

  @override
  void dispose() {
    _myVoucherTabController.dispose();

    /// Dispose all tab-specific blocs.
    for (final bloc in voucherBlocs.values) {
      bloc.close();
    }

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Get filter information for a tab
  // ---------------------------------------------------------------------------

  String _filterByForTab(int tabIndex) {
    if (tabIndex == 0) {
      return 'all';
    }

    return 'category';
  }

  String _filterValueForTab(int tabIndex) {
    if (tabIndex == 0) {
      return 'all';
    }

    return filterData!.options![tabIndex - 1].id.toString();
  }

  // ---------------------------------------------------------------------------
  // Create/Get VoucherBloc for specific tab
  // ---------------------------------------------------------------------------

  VoucherBloc _getVoucherBloc(int tabIndex) {
    if (voucherBlocs.containsKey(tabIndex)) {
      return voucherBlocs[tabIndex]!;
    }

    final bloc = VoucherBloc();

    voucherBlocs[tabIndex] = bloc;

    return bloc;
  }

  // ---------------------------------------------------------------------------
  // Load vouchers for a specific tab
  // ---------------------------------------------------------------------------

  void _loadVoucherTab(int tabIndex, {bool forceReload = false}) {
    if (filterData == null) {
      return;
    }

    final filterBy = _filterByForTab(tabIndex);
    final filterValue = _filterValueForTab(tabIndex);

    final bloc = _getVoucherBloc(tabIndex);

    setState(() {
      currentTabIndex = tabIndex;
      visitedVoucherTabs.add(tabIndex);
    });

    bloc.add(
      VoucherCategoriesLoad(filterBy: filterBy, filterValue: filterValue),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return
    //  BlocProvider<RewardBloc>(
    //   create: (context) {
    //     return RewardBloc(context: context, rewardRepository: sl())
    //       ..add(FilterCategoryLoad());
    //   },
    //   child:
    BlocConsumer<RewardBloc, RewardState>(
      listener: (context, state) {
        // ---------------------------------------------------------------
        // Category loaded
        // ---------------------------------------------------------------

        if (state is FilterCategoryLoaded) {
          final options = state.filterData.options ?? [];

          final newLength = options.length + 1;

          setState(() {
            filterData = state.filterData;
          });

          // Create TabController only when we know the category count.
          if (_myVoucherTabController.length != newLength) {
            _myVoucherTabController.dispose();

            _myVoucherTabController = TabController(
              length: newLength,
              vsync: this,
              initialIndex: 0,
            );

            // Load "For You" initially.
            _loadVoucherTab(0, forceReload: true);
          }
        }

        // ---------------------------------------------------------------
        // Reward error
        // ---------------------------------------------------------------

        if (state is RewardError) {
          showErrorToast(state.error, context);
        }

        // ---------------------------------------------------------------
        // Session expired
        // ---------------------------------------------------------------

        if (state is RewardSessionError) {
          sessionExpiredLogOut(state.error);
        }

        // ---------------------------------------------------------------
        // Network error
        // ---------------------------------------------------------------

        if (state is RewardNetworkError) {
          showErrorToast('No internet connection', context);

          Navigator.of(context).pushNamedAndRemoveUntil(
            OderRoutes.home,
            (Route<dynamic> route) => false,
          );
        }

        // ---------------------------------------------------------------
        // Maintenance
        // ---------------------------------------------------------------

        if (state is RewardMaintenanceError) {
          Navigator.pushAndRemoveUntil<void>(
            context,
            MaterialPageRoute<void>(
              builder:
                  (BuildContext context) => MaintenanceScreen(
                    parameters: MaintenanceParameters(message: state.message),
                  ),
            ),
            ModalRoute.withName('/'),
          );
        }
      },
      builder: (context, state) {
        // ---------------------------------------------------------------
        // Loading categories
        // ---------------------------------------------------------------

        if (state is RewardInitial || state is RewardLoading) {
          return Column(
            children: [
              Container(height: ScreenSize.height * 0.04),
              Expanded(child: LoadingWidget()),
            ],
          );
        }

        // ---------------------------------------------------------------
        // No voucher / category data
        // ---------------------------------------------------------------

        if (filterData == null || _myVoucherTabController.length == 0) {
          return emptyVoucher();
        }

        // Owned vouchers are one collection. The category strip used by the
        // catalogue does not add useful context here and made the list look
        // different from the approved My Vouchers prototype.
        return Column(children: [Expanded(child: _buildVoucherTab(0))]);
      },
      // ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build individual voucher tab
  // ---------------------------------------------------------------------------

  Widget _buildVoucherTab(int tabIndex) {
    final bloc = _getVoucherBloc(tabIndex);

    return BlocBuilder<VoucherBloc, VoucherState>(
      bloc: bloc,
      builder: (context, state) {
        // ---------------------------------------------------------------
        // Loading
        // ---------------------------------------------------------------

        if (state is VoucherLoading) {
          return SizedBox(child: LoadingWidget());
        }

        // ---------------------------------------------------------------
        // Empty
        // ---------------------------------------------------------------

        if (state is VoucherEmpty) {
          return emptyVoucher();
        }

        // ---------------------------------------------------------------
        // Voucher list
        // ---------------------------------------------------------------

        if (state is VoucherCategoriesLoaded) {
          return _buildMyVouchersView(context, state);
        }

        // ---------------------------------------------------------------
        // Initial / unknown state
        // ---------------------------------------------------------------

        return emptyVoucher();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Voucher ListView
  // ---------------------------------------------------------------------------

  Widget _buildMyVouchersView(
    BuildContext context,
    VoucherCategoriesLoaded state,
  ) {
    final vouchers = state.vouchers.vouchers ?? [];

    if (vouchers.isEmpty) {
      return emptyVoucher();
    }

    final allListTiles = vouchers
        .map(
          (voucher) => voucher.getVoucherListTile(
            context: context,
            onTap: () {
              Navigator.of(context).pushNamed(
                OderRoutes.voucherDesc,
                arguments: VoucherDescParameters(
                  voucherId: voucher.voucherId!,
                  title: voucher.name!,
                  quantity: voucher.quantity,
                ),
              );
            },
          ),
        )
        .toList(growable: false);

    return Container(
      margin: EdgeInsets.fromLTRB(marginHorizontal, 10, marginHorizontal, 0),
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: ScreenSize.height * 0.1),
        itemCount: allListTiles.length,
        itemBuilder: (context, index) {
          return allListTiles[index];
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty Voucher
  // ---------------------------------------------------------------------------

  Widget emptyVoucher() {
    return Center(
      child: AccountEmptyState(
        palette: AppDesign.deals,
        title: 'No vouchers yet',
        message: 'Purchased vouchers will appear here.',
        asset: 'assets/icons/no_deals.webp',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Session expired
  // ---------------------------------------------------------------------------

  void sessionExpiredLogOut(String error) {
    showErrorToast('$error\nYou will be logged out.', context);

    BlocProvider.of<AuthenticationBloc>(context).add(AuthenticationLoggedOut());

    Navigator.of(context).pushNamedAndRemoveUntil(
      OderRoutes.login,
      (Route<dynamic> route) => false,
    );
  }
}
