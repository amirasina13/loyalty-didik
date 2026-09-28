import '../../../widgets/independent/favourite_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/extensions/outlet_favourite_view.dart';
import '../../ordering/ordering.dart';
import '../../outlet/outlet.dart';

class FavOutletView extends StatefulWidget {
  final Function changeView;
  const FavOutletView({super.key, required this.changeView});

  @override
  State<FavOutletView> createState() => _FavOutletViewState();
}

class _FavOutletViewState extends State<FavOutletView>
    with SingleTickerProviderStateMixin {
  List<OutletFavourite> outletFav = [];
  // int totalFav = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return OderScaffold(
      background: AppDesign.favourites.background,
      appBarColor: AppDesign.favourites.background,
      bottomMenuIndex: 3,
      isShow: true,
      showAppbar: true,
      systemUiOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: colorWhite,
        statusBarIconBrightness: Brightness.dark,
      ),
      title: Text(
        'Favourites',
        style: TextStyle(
          fontFamily: fontFamilyMain,
          color: AppDesign.favourites.text,
          fontWeight: FontWeight.w700,
          fontSize: AppDesign.appBarTitleSize,
        ),
        textScaler: TextScaler.linear(scaleFactor),
      ),
      canClick: true,
      isCenterTitle: true,
      body: Column(
        children: [
          FavouritesTabs(selected: 1),
          Expanded(
            child: BlocConsumer<OrderingBloc, OrderingState>(
              listener: (context, state) {},
              builder: (context, state) {
                if (state is OrderingInitial || state is OrderingLoading) {
                  return LoadingWidget();
                }

                if (state is OrderingStarted) {
                  BlocProvider.of<OrderingBloc>(
                    context,
                  ).add(OutletFavListLoad());
                }

                if (state is FavOutletListLoaded) {
                  outletFav = state.outletListFav;

                  return SingleChildScrollView(
                    child: _buildFavOutletView(context, state),
                  );
                }

                return LoadingWidget();
              },
            ),
          ),
        ],
      ),
    );
  }

  /* --------------------------------------------------------------------------- All Voucher ListView section */
  Widget _buildFavOutletView(BuildContext context, OrderingState state) {
    /* IF API call success and not empty, set List variable */
    if (state is FavOutletListLoaded) {
      outletFav = state.outletListFav;
    }

    /* the extension for gridview voucher */
    var outletFavListTiles = outletFav
        .map(
          (favOutlet) => favOutlet.getOutletFavListTile(
            context: context,
            onTap: () {
              // Storage().distance = favOutlet.distance;

              Navigator.of(context)
                  .pushNamed(
                    OderRoutes.outletDetails,
                    arguments: OutletDetailsParameters(
                      outletId: favOutlet.id!,
                      outlet: favOutlet.outletName!,
                    ),
                  )
                  .then((value) {
                    setState(() {
                      BlocProvider.of<OrderingBloc>(context)
                        ..isReload = true
                        ..add(OrderingCheck());
                    });
                  });
            },
            onTapFav: () {
              setState(() {
                Storage().page = 'wallet_outletFav';
                BlocProvider.of<OrderingBloc>(context).add(
                  OutletAddRemoveFavouriteLoad(
                    outletId: favOutlet.id!.toString(),
                    merchantId: '',
                  ),
                );

                //
              });
              // if (outletFav.any((fav) => fav.id == favOutlet.id)) {
              //   // print('ISCONTAIN: TRUE');

              //   outletFav
              //       .removeWhere((outletFav) => outletFav.id == favOutlet.id);

              //   String encodedFavList = jsonEncode(outletFav);

              //   setState(() {
              //     _saveList(encodedFavList);
              //   });
              // }
            },
          ),
        )
        .toList(growable: false);

    return FavouritesList(
      category: 1,
      items: outletFavListTiles,
      onExplore: () {
        Navigator.of(context).pushNamed(
          OderRoutes.orderingMerchant,
          arguments: OrderingScreenParameters(selectedTab: 0),
        );
      },
    );
  }
}
