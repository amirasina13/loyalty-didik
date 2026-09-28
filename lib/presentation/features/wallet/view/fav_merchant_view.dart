import '../../../widgets/independent/favourite_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/extensions/ordering_bookmark.dart';
import '../../ordering/ordering.dart';

class FavMerchantView extends StatefulWidget {
  final Function changeView;
  const FavMerchantView({super.key, required this.changeView});

  @override
  State<FavMerchantView> createState() => _FavMerchantViewState();
}

class _FavMerchantViewState extends State<FavMerchantView>
    with SingleTickerProviderStateMixin {
  List<MerchantBookmark> merchantBookmarkList = <MerchantBookmark>[];

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
          FavouritesTabs(selected: 0),
          Expanded(
            child: BlocConsumer<OrderingBloc, OrderingState>(
              listener: (context, state) {},
              builder: (context, state) {
                if (state is OrderingStarted) {
                  BlocProvider.of<OrderingBloc>(
                    context,
                  ).add(MerchantBookmarkLoad());
                }

                // if (state is OrderingInitial ||
                //     state is OrderingStarted ||
                //     state is OrderingLoading) {
                //   return LoadingWidget();
                // }

                if (state is MerchantBookmarkLoaded) {
                  // var profileData = state.userQrcode;

                  return SingleChildScrollView(
                    child: _buildRewardWishlistView(context, state),
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
  Widget _buildRewardWishlistView(BuildContext context, OrderingState state) {
    /* IF API call success and not empty, set List variable */
    if (state is MerchantBookmarkLoaded) {
      merchantBookmarkList = state.merchantBookmark;
    }

    /* the extension for gridview voucher */
    var merchantBookmarkListTiles = merchantBookmarkList
        .map(
          (bookmarkList) => bookmarkList.getMerchantBookmarkListTile(
            context: context,
            onTap: () {
              Storage().brandName = bookmarkList.name;

              Navigator.of(context)
                  .pushNamed(
                    OderRoutes.orderingOutlet,
                    arguments: OrderingOutletParameters(
                      brandsId: bookmarkList.id!,
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
            onTapBookmark: () {
              setState(() {
                Storage().page = 'wallet_bookmark';
                BlocProvider.of<OrderingBloc>(context).add(
                  MerchantAddRemoveFavouriteLoad(
                    merchantId: bookmarkList.id!.toString(),
                  ),
                );

                //
              });
            },
            // controllerSlider: controller,
          ),
        )
        .toList(growable: false);

    return FavouritesList(
      category: 0,
      items: merchantBookmarkListTiles,
      onExplore: () {
        Navigator.of(context).pushNamed(
          OderRoutes.orderingMerchant,
          arguments: OrderingScreenParameters(selectedTab: 0),
        );
      },
    );
  }
}
