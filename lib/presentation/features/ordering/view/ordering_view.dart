import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../../locator.dart';
import '../../../widgets/extensions/ordering_brands_view.dart';
import '../../../widgets/widgets.dart';
import '../../ordering/ordering.dart';

/// Directory entry screen.
///
/// The API and bloc remain responsible for loading the data. This widget owns
/// only the selected category, local search text, and the shared Directory
/// layout used by Brand and Nearby tabs.
class OrderingView extends StatefulWidget {
  final Function changeView;
  final int selectedTab;
  final String? categoryId;

  const OrderingView({
    super.key,
    required this.changeView,
    required this.selectedTab,
    this.categoryId,
  });

  @override
  State<OrderingView> createState() => _OrderingViewState();
}

class _OrderingViewState extends State<OrderingView> {
  late final TextEditingController _brandSearchController;
  late final List<dynamic> _categoryList;

  String _selectedCategoryId = '';
  String _brandSearchQuery = '';
  late bool _showNearby;
  List<MerchantList> _loadedMerchants = const <MerchantList>[];

  @override
  void initState() {
    super.initState();

    _brandSearchController = TextEditingController();
    final rawCategories = Storage().globalValue?['brands'];
    _categoryList = rawCategories is List ? rawCategories : <dynamic>[];

    final requestedCategory = widget.categoryId?.trim() ?? '';
    final requestedIndex = _categoryList.indexWhere(
      (category) =>
          category is Map && category['id'].toString() == requestedCategory,
    );
    final selectedIndex = requestedIndex >= 0 ? requestedIndex : 0;
    _selectedCategoryId =
        _categoryList.isEmpty
            ? ''
            : _categoryList[selectedIndex]['id'].toString();

    _showNearby = widget.selectedTab.clamp(0, 1) == 1;
  }

  @override
  void dispose() {
    _brandSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(OderRoutes.home, (route) => false);
      },
      child: BlocProvider<OrderingBloc>(
        create: (context) {
          final bloc = OrderingBloc(orderingRepository: sl());
          bloc.add(
            BrandsLoad(categoryId: _selectedCategoryId, loadingFirst: false),
          );
          return bloc;
        },
        child: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              Divider(
                height: 1,
                thickness: 1,
                color: AppDesign.directory.border,
              ),
              Expanded(
                child:
                    _showNearby
                        ? const OrderingNearbyView(embedded: true)
                        : _buildBrandTab(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final palette = AppDesign.directory;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.contentPadding,
        vertical: AppDesign.spaceSm,
      ),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'Directory',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.text,
                  fontFamily: fontFamilyMain,
                  fontSize: AppDesign.appBarTitleSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _DirectoryCircleButton(
              icon:
                  _showNearby
                      ? Icons.storefront_outlined
                      : Icons.location_on_outlined,
              label: _showNearby ? 'Show brands' : 'Show nearby outlets',
              onTap: () => setState(() => _showNearby = !_showNearby),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandTab(BuildContext context) {
    final palette = AppDesign.directory;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 82,
          decoration: BoxDecoration(
            color: palette.background,
            border: Border(right: BorderSide(color: palette.border)),
          ),
          child: _buildCategoryRail(context),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDesign.spaceMd,
              AppDesign.spaceMd,
              AppDesign.spaceLg,
              0,
            ),
            child: Column(
              children: [
                DirectorySearchField(
                  controller: _brandSearchController,
                  hintText: 'Search brands',
                  onChanged: (value) {
                    setState(() => _brandSearchQuery = value);
                  },
                ),
                const SizedBox(height: AppDesign.spaceMd),
                Expanded(
                  child: BlocBuilder<OrderingBloc, OrderingState>(
                    builder: (context, state) {
                      return _buildBrandResults(context, state);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRail(BuildContext context) {
    if (_categoryList.isEmpty) {
      return Center(
        child: Icon(Icons.category_outlined, color: AppDesign.directory.muted),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        // top: AppDesign.spaceXs,
        bottom: 20 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: _categoryList.length,
      itemBuilder: (context, index) {
        final category = _categoryList[index];
        if (category is! Map) return const SizedBox.shrink();

        final id = category['id'].toString();
        final name = category['name']?.toString().trim() ?? 'Category';
        return DirectoryCategoryTile(
          label: name,
          image: directoryCategoryImage(category['image']),
          selected: _selectedCategoryId == id,
          onTap: () {
            if (_selectedCategoryId == id) return;

            FocusManager.instance.primaryFocus?.unfocus();
            _brandSearchController.clear();
            setState(() {
              _selectedCategoryId = id;
              _brandSearchQuery = '';
            });
            context.read<OrderingBloc>().add(
              BrandsLoad(categoryId: id, loadingFirst: false),
            );
          },
        );
      },
    );
  }

  Widget _buildBrandResults(BuildContext context, OrderingState state) {
    if (state is BrandsLoading || state is OrderingLoading) {
      return const Center(child: LoadingWidget());
    }

    if (state is OrderingEmpty) {
      return _buildEmptyBrandState(searching: _brandSearchQuery.isNotEmpty);
    }

    if (state is BrandsLoaded) _loadedMerchants = state.merchants;
    final source = state is BrandsLoaded ? state.merchants : _loadedMerchants;
    final query = _brandSearchQuery.trim().toLowerCase();
    final merchants =
        query.isEmpty
            ? source
            : source
                .where(
                  (merchant) =>
                      (merchant.name?.toLowerCase().contains(query) ?? false),
                )
                .toList(growable: false);

    if (merchants.isEmpty) {
      return _buildEmptyBrandState(searching: query.isNotEmpty);
    }

    return GridView.builder(
      padding: EdgeInsets.only(
        bottom: AppDesign.spaceXxl + MediaQuery.paddingOf(context).bottom,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 8,
        childAspectRatio: 0.67,
      ),
      itemCount: merchants.length,
      itemBuilder: (context, index) {
        final merchant = merchants[index];
        return merchant.getListBrandTile(
          context: context,
          onTap: () {
            Storage().brandName = merchant.name;
            Navigator.of(context).pushNamed(
              OderRoutes.orderingOutlet,
              arguments: OrderingOutletParameters(
                brandsId: merchant.id.toString(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyBrandState({required bool searching}) {
    return Center(
      child: AccountEmptyState(
        palette: AppDesign.directory,
        title: searching ? 'No brands found' : 'No brands yet',
        message:
            searching
                ? 'Try a different search term.'
                : 'Brands will appear here when they are available.',
        asset: 'assets/icons/outlet/no_merchant_outlet.webp',
      ),
    );
  }
}

class _DirectoryCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DirectoryCircleButton({
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
            width: 48,
            height: 48,
            child: Icon(icon, color: AppDesign.directory.text, size: 25),
          ),
        ),
      ),
    );
  }
}
