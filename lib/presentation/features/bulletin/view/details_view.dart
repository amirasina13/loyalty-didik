import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../widgets/widgets.dart';
import '../bulletin.dart';

class BulletinDetailsView extends StatefulWidget {
  final Function? changeView;
  final String bulletinId;

  const BulletinDetailsView({
    super.key,
    this.changeView,
    required this.bulletinId,
  });

  @override
  State<BulletinDetailsView> createState() => _BulletinDetailsViewState();
}

class _BulletinDetailsViewState extends State<BulletinDetailsView> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Future _refreshData() async {
    await Future.delayed(Duration(seconds: 1));
    BlocProvider.of<BulletinBloc>(
      // ignore: use_build_context_synchronously
      context,
    ).add(BulletinDetailsLoad(bulletinId: widget.bulletinId));
  }

  /* --------------------------------------------------------------------------- Main user interface */
  @override
  Widget build(BuildContext context) {
    /* ------------------------------------------------------------------------- Bulletin bloc. Lisen to bulletin state */
    return BlocConsumer<BulletinBloc, BulletinState>(
      listener: (context, state) {},
      builder: (context, state) {
        /* --------------------------------------------------------------------- if state now is BulletinLoading, will show loading progress indicator */
        if (state is BulletinDetailsLoading) {
          return LoadingWidget();
        }
        /* --------------------------------------------------------------------- if state now is BulletinDetailsLoaded, */
        if (state is BulletinDetailsLoaded) {
          /* decalre the detail and bulletinId */
          var detail = state.details;
          var bulletinId = detail.id;

          /* ------------------------------------------------------------------- if bulletin got value, show design */
          if (bulletinId != null) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: marginHorizontal),
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refreshData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Container(
                            color: colorWhite,
                            child: Container(
                              color: colorWhite,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  /* Container for bulletin detail.image */
                                  Container(
                                    color: colorTransparent,
                                    width: double.infinity,
                                    margin: EdgeInsets.only(
                                      bottom: AppDesign.spaceLg,
                                    ),
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: AspectRatio(
                                          aspectRatio: 2 / 1,
                                          child: CachedImage(
                                            imageUrl: detail.image ?? '',
                                            boxFit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  /* Container for detail.content in Html */
                                  Container(
                                    margin: EdgeInsets.symmetric(vertical: 20),
                                    child: HtmlWidget(
                                      detail.content ?? '',
                                      onTapUrl:
                                          (url) => openInAppWebView(
                                            context,
                                            url,
                                            title: detail.name ?? 'Highlight',
                                          ),
                                      textStyle: const TextStyle(
                                        color: colorBlack,
                                        fontSize: AppDesign.bodySize,
                                        fontFamily: fontFamilyMain,
                                        fontWeight: FontWeight.w400,
                                        height: 1.35,
                                      ),
                                      // customWidgetBuilder: (element) {
                                      //   if (element.localName == 'span') {
                                      //     return Text(
                                      //       element.text,
                                      //       style: TextStyle(
                                      //         fontFamily: fontFamilyMain,
                                      //         fontSize: 14,
                                      //         color: colorSoftGrey,
                                      //       ),
                                      //     );
                                      //   }
                                      //   return null;
                                      // },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    /* This part if details got button, show the button
                           else showing empty container */
                    if (detail.isButton == true)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          AppDesign.spaceXs,
                          0,
                          AppDesign.spaceXl,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: OderStyleButton(
                            title:
                                detail.button?.trim().isNotEmpty == true
                                    ? detail.button!
                                    : 'Learn more',
                            height: 54,
                            width: double.infinity,
                            backgroundColor: mainColor,
                            borderColor: mainColor,
                            borderRadius: 27,
                            textColor: colorWhite,
                            fontSize: AppDesign.bodySize,
                            fontWeight: FontWeight.w600,
                            onPressed: () {
                              if (detail.link?.trim().isNotEmpty != true) {
                                return;
                              }
                              openInAppWebView(
                                context,
                                detail.link!,
                                title: detail.name ?? 'Highlight',
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }
        }
        /* --------------------------------------------------------------------- if no bulletin details calling will show empty container */
        return Container();
      },
    );
  }
}
