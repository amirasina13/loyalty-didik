import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../../app_setting/app_setting.dart';
import '../../../../../data/data.dart';
import '../../../../widgets/extensions/reward_list_view.dart';
import '../../../../widgets/widgets.dart';
import '../../../authentication/authentication.dart';
import '../../../maintenance/maintenance.dart';
import '../../../rewards/reward.dart';
import '../../../webview/webview_deeplink.dart';

class VoucherRewardsTab extends StatefulWidget {
  final String? filterBy;
  final String? filterValue;

  const VoucherRewardsTab({
    super.key,
    required this.filterBy,
    required this.filterValue,
  });

  @override
  State<VoucherRewardsTab> createState() => VoucherRewardsTabState();
}

class VoucherRewardsTabState extends State<VoucherRewardsTab>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  FilterData? filterData;

  String updatedFilterBy = '';
  String updatedFilterValue = '';

  int currentTabIndex = 0;

  late TabController _voucherRewardTabController;
  final Map<int, List<VoucherReward>> rewardsByTab = {};
  final Set<int> exhaustedRewardTabs = {};

  /// Keep track of which tabs have been visited.
  final Set<int> visitedRewardTabs = {0};

  /// Each tab has its own ScrollController.
  final Map<int, ScrollController> scrollControllers = {};
  final Map<String, bool> _favouriteLoadingStates = {};
  final Map<String, bool> _favouriteValues = {};

  /// The compact Deals toolbar keeps search local to the loaded page and
  /// leaves server filtering/pagination on the existing category controls.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _squareLayout = false;

  /// Used for pagination.
  String pagingFilterBy = 'all';
  String pagingFilterValue = 'all';

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    fToast = FToast();
    fToast.init(context);

    if (Storage().isTabChange == false) {
      updatedFilterBy = widget.filterBy ?? 'all';
      updatedFilterValue = widget.filterValue ?? 'all';
    } else {
      updatedFilterBy = 'all';
      updatedFilterValue = 'all';
    }

    _voucherRewardTabController = TabController(length: 0, vsync: this);

    context.read<RewardBloc>().add(FilterCategoryLoad());
  }

  // ---------------------------------------------------------------------------
  // SCROLL CONTROLLER
  // ---------------------------------------------------------------------------

  ScrollController _controllerFor(int tabIndex) {
    return scrollControllers.putIfAbsent(tabIndex, () {
      final controller = ScrollController();

      controller.addListener(() => _onScrollForTab(tabIndex));

      return controller;
    });
  }

  void _onScrollForTab(int tabIndex) {
    final controller = scrollControllers[tabIndex];

    if (controller == null ||
        !controller.hasClients ||
        tabIndex != currentTabIndex ||
        exhaustedRewardTabs.contains(tabIndex) ||
        controller.position.userScrollDirection != ScrollDirection.reverse) {
      return;
    }

    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 200) {
      final bloc = context.read<RewardBloc>();

      if (!bloc.isRewardFetching) {
        final filterBy = _filterByForTab(tabIndex);
        final filterValue = _filterValueForTab(tabIndex);

        pagingFilterBy = filterBy;
        pagingFilterValue = filterValue;

        bloc
          ..isRewardFetching = true
          ..add(RewardListLoad(filterBy: filterBy, filterValue: filterValue));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // GET FILTER FOR TAB
  // ---------------------------------------------------------------------------

  String _filterByForTab(int tabIndex) {
    return tabIndex == 0 ? 'all' : 'category';
  }

  String _filterValueForTab(int tabIndex) {
    if (tabIndex == 0) {
      return 'all';
    }

    if (filterData?.options == null) {
      return '';
    }

    final optionIndex = tabIndex - 1;

    if (optionIndex < 0 || optionIndex >= filterData!.options!.length) {
      return '';
    }

    return filterData!.options![optionIndex].id.toString();
  }

  // ---------------------------------------------------------------------------
  // GET CURRENT TAB REWARDS
  // ---------------------------------------------------------------------------

  List<VoucherReward> _rewardsForTab(int tabIndex) {
    return rewardsByTab[tabIndex] ?? <VoucherReward>[];
  }

  // ---------------------------------------------------------------------------
  // CLEAR TAB
  // ---------------------------------------------------------------------------

  void _clearTabRewards(int tabIndex) {
    rewardsByTab[tabIndex] = <VoucherReward>[];
    exhaustedRewardTabs.remove(tabIndex);
  }

  // ---------------------------------------------------------------------------
  // TAB CLICK
  // ---------------------------------------------------------------------------

  void _onTabSelected(int tabIndex) {
    FocusManager.instance.primaryFocus?.unfocus();

    final targetFilterBy = _filterByForTab(tabIndex);
    final targetFilterValue = _filterValueForTab(tabIndex);

    setState(() {
      currentTabIndex = tabIndex;

      visitedRewardTabs.add(tabIndex);

      // IMPORTANT:
      // Clear ONLY the selected tab's old rewards.
      _clearTabRewards(tabIndex);
    });

    final bloc = context.read<RewardBloc>();

    pagingFilterBy = targetFilterBy;
    pagingFilterValue = targetFilterValue;

    // Reset pagination.
    bloc
      ..rewardPage = 0
      ..isRewardFetching = true
      ..add(
        RewardListLoad(
          filterBy: targetFilterBy,
          filterValue: targetFilterValue,
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    for (final controller in scrollControllers.values) {
      controller.dispose();
    }

    _voucherRewardTabController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<RewardBloc, RewardState>(
      listener: (context, state) {
        // ---------------------------------------------------------------------
        // FILTER CATEGORY LOADED
        // ---------------------------------------------------------------------

        if (state is FilterCategoryLoaded) {
          filterData = state.filterData;

          final options = filterData!.options ?? [];
          final newLength = options.length + 1;

          // Find the category passed from previous page.
          //
          // IMPORTANT:
          // Compare String to String because widget.filterValue
          // is passed using category.id.toString().
          final initialIndexTab = options.indexWhere(
            (el) => el.id.toString() == widget.filterValue.toString(),
          );

          final selectedIndex =
              updatedFilterBy == 'all'
                  ? 0
                  : (initialIndexTab >= 0 ? initialIndexTab + 1 : 0);

          // Create TabController.
          if (_voucherRewardTabController.length != newLength) {
            _voucherRewardTabController.dispose();

            _voucherRewardTabController = TabController(
              length: newLength,
              vsync: this,
              initialIndex: selectedIndex,
            );
          } else {
            if (_voucherRewardTabController.index != selectedIndex) {
              _voucherRewardTabController.index = selectedIndex;
            }
          }

          // Set current tab.
          currentTabIndex = selectedIndex;

          // Make sure selected tab is visited.
          visitedRewardTabs.add(selectedIndex);

          // Clear selected tab's old data.
          _clearTabRewards(selectedIndex);

          // Initial API request.
          final targetFilterBy = updatedFilterBy == 'all' ? 'all' : 'category';

          final targetFilterValue =
              updatedFilterBy == 'all' ? 'all' : updatedFilterValue;

          pagingFilterBy = targetFilterBy;
          pagingFilterValue = targetFilterValue;

          context.read<RewardBloc>()
            ..rewardPage = 0
            ..isRewardFetching = true
            ..add(
              RewardListLoad(
                filterBy: targetFilterBy,
                filterValue: targetFilterValue,
              ),
            );
        }

        // ---------------------------------------------------------------------
        // REWARD LIST LOADED
        // ---------------------------------------------------------------------

        if (state is RewardAddRemoveFavouriteLoaded) {
          setState(() {
            _favouriteLoadingStates.remove(state.voucherId);
            _favouriteValues[state.voucherId] = state.isFavourite;
          });
        }

        if (state is RewardListLoaded) {
          final currentTab = currentTabIndex;
          if (!state.hasMore) {
            exhaustedRewardTabs.add(currentTab);
          }

          final newRewards =
              (state.voucherRewards.vouchers ?? [])
                  .where((voucher) => voucher.purchaseMethod != 'redeemable')
                  .toList();

          final currentRewards = rewardsByTab[currentTab] ?? <VoucherReward>[];

          // Refresh existing items too, including their favourite status.
          for (final item in newRewards) {
            if (!_favouriteLoadingStates.containsKey(item.id)) {
              _favouriteValues.remove(item.id);
            }
            final index = currentRewards.indexWhere(
              (existing) => existing.id == item.id,
            );
            if (index < 0) {
              currentRewards.add(item);
            } else {
              currentRewards[index] = item;
            }
          }

          setState(() {
            rewardsByTab[currentTab] = currentRewards;
          });

          context.read<RewardBloc>().isRewardFetching = false;
        }

        // ---------------------------------------------------------------------
        // REWARD EMPTY
        // ---------------------------------------------------------------------

        if (state is RewardEmpty) {
          exhaustedRewardTabs.add(currentTabIndex);
          context.read<RewardBloc>().isRewardFetching = false;

          setState(() {
            rewardsByTab[currentTabIndex] = <VoucherReward>[];
          });
        }

        // ---------------------------------------------------------------------
        // NO MORE PAGINATION
        // ---------------------------------------------------------------------

        if (state is RewardListStop) {
          exhaustedRewardTabs.add(currentTabIndex);

          context.read<RewardBloc>().isRewardFetching = false;
        }

        // ---------------------------------------------------------------------
        // ERRORS
        // ---------------------------------------------------------------------

        if (state is RewardError) {
          _favouriteLoadingStates.clear();
          context.read<RewardBloc>().isRewardFetching = false;

          showErrorToast(state.error, context);
        }

        if (state is RewardSessionError) {
          context.read<RewardBloc>().isRewardFetching = false;

          sessionExpiredLogOut(state.error);
        }

        if (state is RewardNetworkError) {
          context.read<RewardBloc>().isRewardFetching = false;

          showErrorToast('No internet connection', context);

          Navigator.of(context).pushNamedAndRemoveUntil(
            OderRoutes.home,
            (Route<dynamic> route) => false,
          );
        }

        if (state is RewardMaintenanceError) {
          context.read<RewardBloc>().isRewardFetching = false;

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

      // -----------------------------------------------------------------------
      // BUILDER
      // -----------------------------------------------------------------------
      builder: (context, state) {
        if (state is RewardInitial) {
          return Column(
            children: [
              Container(height: ScreenSize.height * 0.04),
              Expanded(child: LoadingWidget()),
            ],
          );
        }

        if (filterData == null) {
          return Column(
            children: [
              Container(height: ScreenSize.height * 0.04),
              Expanded(child: LoadingWidget()),
            ],
          );
        }

        return Column(
          children: [
            _buildDealsToolbar(context),
            Expanded(
              child: TabBarView(
                // Categories are selected through the filter sheet, which loads
                // their data. Swiping bypasses that selection handler.
                controller: _voucherRewardTabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // -----------------------------------------------------------
                  // ALL / FOR YOU
                  // -----------------------------------------------------------
                  _buildRewardTab(context, 0, state),

                  // -----------------------------------------------------------
                  // CATEGORY TABS
                  // -----------------------------------------------------------
                  for (int i = 0; i < (filterData!.options ?? []).length; i++)
                    _buildRewardTab(context, i + 1, state),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD ONE TAB
  // ---------------------------------------------------------------------------

  Widget _buildRewardTab(
    BuildContext context,
    int tabIndex,
    RewardState state,
  ) {
    final filterBy = _filterByForTab(tabIndex);

    final filterValue = _filterValueForTab(tabIndex);

    final allRewards = _rewardsForTab(tabIndex);
    final rewards = _filterRewards(allRewards);

    final bool isCurrentTab = currentTabIndex == tabIndex;

    // Only show loading on the currently requested tab.
    if (isCurrentTab && (state is RewardLoading || state is RewardInitial)) {
      return LoadingWidget();
    }

    // Current tab has no rewards.
    if (rewards.isEmpty) {
      return emptyDeals(
        message: _searchQuery.isEmpty ? 'No Deals Yet' : 'No deals found',
      );
    }

    return Column(
      children: [
        Expanded(
          child: _buildRewardListView(
            context,
            rewards,
            filterBy,
            filterValue,
            tabIndex,
            state,
          ),
        ),

        if (isCurrentTab && state is RewardNextLoading)
          SizedBox(child: LoadingWidget()),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REWARD LIST
  // ---------------------------------------------------------------------------

  Widget _buildRewardListView(
    BuildContext context,
    List<VoucherReward> rewards,
    String filterBy,
    String filterValue,
    int tabIndex,
    RewardState state,
  ) {
    final list = ListView.builder(
      padding: EdgeInsets.only(
        bottom: AppDesign.spaceXxl + MediaQuery.paddingOf(context).bottom,
      ),
      controller: _controllerFor(tabIndex),
      itemCount: rewards.length,
      itemBuilder: (BuildContext context, int index) {
        final reward = rewards[index];

        final bool isItemLoading =
            _favouriteLoadingStates[reward.id ?? ''] ?? false;

        return reward.getRewardListTile(
          context: context,
          onTap:
              () =>
                  _openReward(context, reward, tabIndex, filterBy, filterValue),
          onFavouriteTap:
              () => _toggleFavourite(context, reward, filterBy, filterValue),
          isFavClick: isItemLoading,
          favouriteOverride: _favouriteValues[reward.id],
        );
      },
    );

    if (!_squareLayout) {
      return Container(
        margin: const EdgeInsets.fromLTRB(
          marginHorizontal,
          10,
          marginHorizontal,
          0,
        ),
        child: list,
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        marginHorizontal,
        10,
        marginHorizontal,
        0,
      ),
      child: GridView.builder(
        padding: EdgeInsets.only(
          bottom: AppDesign.spaceXxl + MediaQuery.paddingOf(context).bottom,
        ),
        controller: _controllerFor(tabIndex),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 0,
          // Keep enough height for the square image, wrapped price and actions
          // without reserving a large blank area below the price.
          childAspectRatio: 0.4,
        ),
        itemCount: rewards.length,
        itemBuilder: (context, index) {
          final reward = rewards[index];
          final isItemLoading =
              _favouriteLoadingStates[reward.id ?? ''] ?? false;
          return reward.getRewardListTile(
            context: context,
            onTap:
                () => _openReward(
                  context,
                  reward,
                  tabIndex,
                  filterBy,
                  filterValue,
                ),
            onFavouriteTap:
                () => _toggleFavourite(context, reward, filterBy, filterValue),
            isFavClick: isItemLoading,
            favouriteOverride: _favouriteValues[reward.id],
            squareLayout: true,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY
  // ---------------------------------------------------------------------------

  Widget emptyDeals({String message = 'No Deals Yet'}) {
    final isSearchResult = _searchQuery.trim().isNotEmpty;
    return Center(
      child: AccountEmptyState(
        palette: AppDesign.deals,
        title: message,
        message:
            isSearchResult
                ? 'Try a different search term.'
                : 'New deals will appear here.',
        asset: 'assets/icons/no_deals.webp',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SESSION EXPIRED
  // ---------------------------------------------------------------------------

  void sessionExpiredLogOut(String error) {
    showErrorToast('$error\nYou will be logged out.', context);

    BlocProvider.of<AuthenticationBloc>(context).add(AuthenticationLoggedOut());

    Navigator.of(context).pushNamedAndRemoveUntil(
      OderRoutes.login,
      (Route<dynamic> route) => false,
    );
  }

  List<VoucherReward> _filterRewards(List<VoucherReward> rewards) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return rewards;

    return rewards
        .where((reward) {
          final name = reward.name?.toLowerCase() ?? '';
          final description = reward.desc?.toLowerCase() ?? '';
          return name.contains(query) || description.contains(query);
        })
        .toList(growable: false);
  }

  Widget _buildDealsToolbar(BuildContext context) {
    final options = filterData?.options ?? [];
    final filterLabel =
        currentTabIndex == 0
            ? 'All'
            : (currentTabIndex - 1 < options.length
                ? options[currentTabIndex - 1].name ?? 'All'
                : 'All');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        marginHorizontal,
        10,
        marginHorizontal,
        2,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  color: AppDesign.deals.text,
                  fontFamily: fontFamilyMain,
                  fontSize: AppDesign.bodySize,
                ),
                decoration: InputDecoration(
                  hintText: 'Search deals',
                  hintStyle: TextStyle(
                    color: AppDesign.deals.muted,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.bodySize,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppDesign.deals.muted,
                    size: 21,
                  ),
                  filled: true,
                  fillColor: AppDesign.deals.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDesign.spaceMd,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppDesign.deals.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppDesign.deals.action),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDesign.spaceSm),
          _DealsToolbarButton(
            label: filterLabel,
            icon: Icons.tune,
            onTap: _showFilterSheet,
          ),
          const SizedBox(width: AppDesign.spaceSm),
          _DealsLayoutSwitch(
            squareLayout: _squareLayout,
            onChanged: (squareLayout) {
              setState(() => _squareLayout = squareLayout);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    final options = filterData?.options ?? [];
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppDesign.deals.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.sheetRadius),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, AppDesign.spaceMd, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppDesign.deals.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: AppDesign.spaceLg),
                Text(
                  'Filter deals',
                  style: TextStyle(
                    color: AppDesign.deals.text,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDesign.spaceSm),
                _DealsFilterOption(
                  label: 'All',
                  selected: currentTabIndex == 0,
                  onTap: () => Navigator.pop(sheetContext, 0),
                ),
                for (int i = 0; i < options.length; i++)
                  _DealsFilterOption(
                    label: options[i].name ?? 'Category',
                    selected: currentTabIndex == i + 1,
                    onTap: () => Navigator.pop(sheetContext, i + 1),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted ||
        selected == null ||
        selected >= _voucherRewardTabController.length) {
      return;
    }

    _voucherRewardTabController.index = selected;
    _onTabSelected(selected);
  }

  void _openReward(
    BuildContext context,
    VoucherReward reward,
    int tabIndex,
    String filterBy,
    String filterValue,
  ) {
    TempData.voucherRefCode = '';
    Storage().page = '';
    final bloc = context.read<RewardBloc>();
    Navigator.of(context)
        .pushNamed(
          OderRoutes.rewardDetails,
          arguments: RewardDetailsParameters(
            rewardId: reward.id.toString(),
            title: reward.name ?? 'Voucher',
            indexPage: 3,
          ),
        )
        .then((value) {
          if (!mounted) return;
          _clearTabRewards(tabIndex);
          bloc
            ..rewardPage = 0
            ..isRewardFetching = true
            ..add(RewardListLoad(filterBy: filterBy, filterValue: filterValue));
        });
  }

  void _toggleFavourite(
    BuildContext context,
    VoucherReward reward,
    String filterBy,
    String filterValue,
  ) {
    final rewardId = reward.id ?? '';
    if (rewardId.isEmpty || _favouriteLoadingStates[rewardId] == true) return;
    setState(() => _favouriteLoadingStates[rewardId] = true);
    Storage().page = 'reward_wishlist';
    context.read<RewardBloc>().add(
      RewardAddRemoveFavouriteLoad(
        voucherId: rewardId,
        filterBy: filterBy,
        filterValue: filterValue,
      ),
    );
  }
}

class _DealsToolbarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DealsToolbarButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Filter: $label',
      child: Material(
        color: AppDesign.deals.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 42,
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppDesign.deals.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppDesign.deals.text,
                      fontFamily: fontFamilyMain,
                      fontSize: AppDesign.captionSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppDesign.spaceXs),
                Icon(icon, size: 16, color: AppDesign.deals.action),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DealsLayoutSwitch extends StatelessWidget {
  final bool squareLayout;
  final ValueChanged<bool> onChanged;

  const _DealsLayoutSwitch({
    required this.squareLayout,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Voucher layout',
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: colorBlueDidik.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppDesign.deals.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LayoutChoice(
              icon: Icons.view_list_rounded,
              label: 'Price-first view',
              selected: !squareLayout,
              onTap: () => onChanged(false),
            ),
            _LayoutChoice(
              icon: Icons.grid_view_rounded,
              label: 'Square cards view',
              selected: squareLayout,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LayoutChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: selected ? AppDesign.deals.background : colorTransparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(
                icon,
                size: 18,
                color:
                    selected ? AppDesign.deals.action : AppDesign.deals.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DealsFilterOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DealsFilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          color: AppDesign.deals.text,
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.bodySize,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppDesign.deals.action : AppDesign.deals.border,
      ),
    );
  }
}
