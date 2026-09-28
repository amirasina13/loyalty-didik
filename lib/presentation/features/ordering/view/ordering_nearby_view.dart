import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../../authentication/authentication.dart';
import '../../maintenance/maintenance.dart';
import '../../outlet/outlet_details_screen.dart';
import '../ordering.dart';

/// Nearby tab content used by the Directory shell and the standalone nearby
/// route. The parent supplies the [OrderingBloc] in both cases.
class OrderingNearbyView extends StatefulWidget {
  final Function? changeView;
  final bool embedded;

  const OrderingNearbyView({super.key, this.changeView, this.embedded = false});

  @override
  State<OrderingNearbyView> createState() => _OrderingNearbyViewState();
}

class _OrderingNearbyViewState extends State<OrderingNearbyView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<NearbyOutletList> _outlets = <NearbyOutletList>[];

  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    final bloc = context.read<OrderingBloc>();
    if (!bloc.isNearbyFetching && _outlets.isEmpty) {
      bloc
        ..isFirstLoad = true
        ..isNearbyFetching = true
        ..add(NearbyLoad());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 220) return;

    final bloc = context.read<OrderingBloc>();
    if (bloc.isNearbyFetching) return;

    bloc
      ..isFirstLoad = false
      ..isNearbyFetching = true
      ..add(NearbyLoad());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<OrderingBloc, OrderingState>(
      listener: (context, state) {
        if (state is NearbyLoaded) {
          final incoming = state.outlets.outlets ?? const <NearbyOutletList>[];
          final existingIds = _outlets.map((outlet) => outlet.id).toSet();
          setState(() {
            for (final outlet in incoming) {
              if (outlet.id == null || existingIds.add(outlet.id)) {
                _outlets.add(outlet);
              }
            }
          });
          context.read<OrderingBloc>().isNearbyFetching = false;
        }

        if (state is NearbyEmpty || state is NearbyListStop) {
          context.read<OrderingBloc>().isNearbyFetching = false;
        }

        if (state is OrderingError) {
          showErrorToast(state.error, context);
        }
        if (state is OrderingSessionError) {
          sessionExpiredLogOut(state.error);
        }
        if (state is OrderingMaintenanceError) {
          Navigator.pushAndRemoveUntil<void>(
            context,
            MaterialPageRoute<void>(
              builder:
                  (context) => MaintenanceScreen(
                    parameters: MaintenanceParameters(message: state.message),
                  ),
            ),
            ModalRoute.withName('/'),
          );
        }
      },
      builder: (context, state) {
        final isInitialLoading =
            _outlets.isEmpty &&
            (state is OrderingInitial ||
                state is OrderingLoading ||
                state is NearbyNextLoading);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDesign.spaceMd,
                horizontal: AppDesign.spaceLg,
              ),
              child: DirectorySearchField(
                controller: _searchController,
                hintText: 'Search outlets',
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            const SizedBox(height: AppDesign.spaceMd),
            Expanded(
              child:
                  isInitialLoading
                      ? const Center(child: LoadingWidget())
                      : _buildNearbyResults(context, state),
            ),
            if (state is NearbyNextLoading && _outlets.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: AppDesign.spaceMd),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNearbyResults(BuildContext context, OrderingState state) {
    final query = _searchQuery.trim().toLowerCase();
    final results =
        query.isEmpty
            ? _outlets
            : _outlets
                .where(
                  (outlet) =>
                      (outlet.merchantName?.toLowerCase().contains(query) ??
                          false) ||
                      (outlet.place?.toLowerCase().contains(query) ?? false) ||
                      (outlet.address?.toLowerCase().contains(query) ?? false),
                )
                .toList(growable: false);

    if (results.isEmpty) {
      return _buildEmptyState(searching: query.isNotEmpty, state: state);
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppDesign.spaceLg,
        0,
        AppDesign.spaceLg,
        AppDesign.spaceXxl,
      ),
      itemCount: results.length,
      separatorBuilder:
          (context, index) => const SizedBox(height: AppDesign.spaceMd),
      itemBuilder: (context, index) {
        final outlet = results[index];
        return DirectoryOutletCard(
          name: outlet.merchantName,
          location: outlet.place,
          address: outlet.address,
          distance: _formatDistance(outlet.distance),
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
        );
      },
    );
  }

  Widget _buildEmptyState({
    required bool searching,
    required OrderingState state,
  }) {
    if (searching) {
      return Center(
        child: AccountEmptyState(
          palette: AppDesign.directory,
          title: 'No outlets found',
          message: 'Try a different search term.',
          asset: 'assets/icons/outlet/no_merchant_outlet.webp',
        ),
      );
    }

    return Center(
      child: AccountEmptyState(
        palette: AppDesign.directory,
        title: 'Discover what’s nearby',
        message: 'Use your location to find outlets around you.',
        asset: 'assets/icons/outlet/no_merchant_outlet.webp',
        actionLabel: 'Use my location',
        onAction: () {
          context.read<OrderingBloc>().add(OrderingLocationEnable());
        },
      ),
    );
  }

  String _formatDistance(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return '';
    return '${parsed.toStringAsFixed(2)} km';
  }

  void sessionExpiredLogOut(String error) {
    showErrorToast('$error\nYou will be logged out.', context);
    context.read<AuthenticationBloc>().add(AuthenticationLoggedOut());
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(OderRoutes.login, (route) => false);
  }
}
