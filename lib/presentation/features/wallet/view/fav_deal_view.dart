import '../../voucher/voucher.dart';
import '../../../widgets/independent/favourite_card.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/extensions/reward_favourite.dart';
import '../../rewards/reward.dart';

class FavDealView extends StatefulWidget {
  final Function changeView;
  const FavDealView({super.key, required this.changeView});

  @override
  State<FavDealView> createState() => _FavDealViewState();
}

class _FavDealViewState extends State<FavDealView> {
  List<RewardFavourite> rewardFavouriteList = <RewardFavourite>[];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
          FavouritesTabs(selected: 2),
          Expanded(
            child: BlocConsumer<RewardBloc, RewardState>(
              listener: (context, state) {},
              builder: (context, state) {
                if (state is RewardOutletStarted) {
                  BlocProvider.of<RewardBloc>(
                    context,
                  ).add(RewardFavouriteLoad());
                }

                if (state is RewardFavouriteLoaded) {
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
  Widget _buildRewardWishlistView(BuildContext context, RewardState state) {
    /* IF API call success and not empty, set List variable */
    if (state is RewardFavouriteLoaded) {
      rewardFavouriteList = state.rewardFavourite;
    }

    /* the extension for gridview voucher */
    var rewardFavouriteListTiles = rewardFavouriteList
        .map(
          (favouriteList) => favouriteList.getRewardFavouriteListTile(
            context: context,
            onTap: () {
              Navigator.of(context)
                  .pushNamed(
                    OderRoutes.rewardDetails,
                    arguments: RewardDetailsParameters(
                      rewardId: favouriteList.id.toString(),
                      title: favouriteList.name!,
                      indexPage: 3,
                    ),
                  )
                  .then((value) {
                    if (context.mounted) {
                      BlocProvider.of<RewardBloc>(
                        context,
                      ).add(RewardOutletCheck());
                    }
                  });
            },
            onTapFavourite: () {
              setState(() {
                Storage().page = 'wallet_wishlist';
                BlocProvider.of<RewardBloc>(context).add(
                  RewardAddRemoveFavouriteLoad(
                    voucherId: favouriteList.id.toString(),
                    filterBy: '',
                    filterValue: '',
                  ),
                );
              });
            },
          ),
        )
        .toList(growable: false);

    return FavouritesList(
      category: 2,
      items: rewardFavouriteListTiles,
      onExplore: () {
        Storage().rewardReload = '';
        Navigator.of(context).pushNamed(
          OderRoutes.voucher,
          arguments: VoucherParameters(
            selectedTab: 0,
            filterBy: 'all',
            filterValue: '1',
          ),
        );
      },
    );
  }
}
