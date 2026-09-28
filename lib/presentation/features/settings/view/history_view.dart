import '../../../widgets/independent/account_history_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../widgets/extensions/credit_history_view.dart';
import '../../../widgets/extensions/history_view.dart';
import '../../../widgets/widgets.dart';
import '../../authentication/authentication.dart';
import '../../history/history.dart';
import '../../maintenance/maintenance_screen.dart';
import '../../profile/profile.dart';

class HistoryView extends StatefulWidget {
  final Function changeView;
  final int selectedTab;
  const HistoryView({
    super.key,
    required this.changeView,
    required this.selectedTab,
  });

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  History? history;
  CreditHistory? creditHistory;
  late HistoryBloc historyBloc;
  HistoryTransactionsLoaded? _lastPointPage;
  CreditHistoryTransactionsLoaded? _lastCreditPage;
  final ScrollController _pointScrollController = ScrollController();
  final ScrollController _creditScrollController = ScrollController();
  List<Records> records = <Records>[];
  List<CreditRecords> creditRecords = <CreditRecords>[];
  bool isLoading = false;
  bool isCredits = false;
  var totalCredits = '0.00', totalPoints = '0.00';

  @override
  void initState() {
    super.initState();

    fToast = FToast();
    fToast.init(context);

    widget.selectedTab == 0 ? isCredits = true : false;
    _pointScrollController.addListener(_loadMorePoints);
    _creditScrollController.addListener(_loadMoreCredits);
  }

  void _loadMorePoints() {
    if (_pointScrollController.position.maxScrollExtent ==
        _pointScrollController.position.pixels) {
      final bloc = context.read<HistoryBloc>();
      if (!bloc.isFetching) {
        bloc
          ..isFetching = true
          ..add(HistoryTransactionsLoad());
        bloc.isFirstShowPoint = false;
      }
    }
  }

  void _loadMoreCredits() {
    if (_creditScrollController.position.maxScrollExtent ==
        _creditScrollController.position.pixels) {
      final bloc = context.read<HistoryBloc>();
      if (!bloc.isCreditFetching) {
        bloc
          ..isCreditFetching = true
          ..add(CreditHistoryTransactionsLoad());
        bloc.isFirstShow = false;
      }
    }
  }

  @override
  void dispose() {
    _pointScrollController.dispose();
    _creditScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return creditEnable == true &&
            creditHistoryEnable == true &&
            pointEnable == true &&
            pointHistory == true
        ? Container(
          color: AppDesign.history.background,
          // height: MediaQuery.of(context).size.height - // total height
          //     kToolbarHeight - // top AppBar height
          //     MediaQuery.of(context).padding.top - // top padding
          //     kBottomNavigationBarHeight, // BottomNavigationBar height
          margin: const EdgeInsets.symmetric(vertical: AppDesign.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocConsumer<ProfileBloc, ProfileState>(
                listener: (context, state) {
                  if (state is ProfileLoaded) {
                    double? numericCredit = double.tryParse(
                      state.userProfile.profile!.credits.toString(),
                    );
                    double? numericPoint = double.tryParse(
                      state.userProfile.profile!.points.toString(),
                    );
                    String formattedCredit = (numericCredit ?? 0.0)
                        .toStringAsFixed(2);
                    String formattedPoint = (numericPoint ?? 0.0)
                        .toStringAsFixed(2);

                    totalCredits = formattedCredit;
                    totalPoints = formattedPoint;
                  }
                },
                builder: (context, state) {
                  if (state is ProfileLoaded) {
                    totalCredits = (double.tryParse(
                              state.userProfile.profile?.credits.toString() ??
                                  '',
                            ) ??
                            0)
                        .toStringAsFixed(2);
                    totalPoints = (double.tryParse(
                              state.userProfile.profile?.points.toString() ??
                                  '',
                            ) ??
                            0)
                        .toStringAsFixed(2);
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesign.pagePadding,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: HistoryBalanceTab(
                            label: '$creditLabelTitle balance',
                            amount: totalCredits,
                            selected: isCredits,
                            onTap: () {
                              if (isCredits) return;
                              setState(() {
                                isCredits = true;
                                creditRecords.clear();
                                BlocProvider.of<HistoryBloc>(context)
                                    .isFirstShow = true;
                                BlocProvider.of<HistoryBloc>(
                                  context,
                                ).add(CreditHistoryTransactionsLoad());
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppDesign.spaceMd),
                        Expanded(
                          child: HistoryBalanceTab(
                            label: '$pointLabelTitle available',
                            amount: totalPoints,
                            selected: !isCredits,
                            onTap: () {
                              if (!isCredits) return;
                              setState(() {
                                isCredits = false;
                                records.clear();
                                BlocProvider.of<HistoryBloc>(context)
                                    .isFirstShowPoint = true;
                                BlocProvider.of<HistoryBloc>(
                                  context,
                                ).add(HistoryTransactionsLoad());
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDesign.spaceXl),
              isCredits
                  ? Expanded(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.68,
                      color: colorWhite,
                      child: BlocConsumer<HistoryBloc, HistoryState>(
                        listener: (context, state) {},
                        builder: (context, state) {
                          return _buildTabCredit(context);
                        },
                      ),
                    ),
                  )
                  : Expanded(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.68,
                      color: colorWhite,
                      child: BlocConsumer<HistoryBloc, HistoryState>(
                        listener: (context, state) {},
                        builder: (context, state) {
                          return _buildHistory(context);
                        },
                      ),
                    ),
                  ),
            ],
          ),
        )
        : Container(
          color: AppDesign.history.background,
          height: ScreenSize.height * 0.8,
          margin: EdgeInsets.zero,
          child:
              creditEnable == true && creditHistoryEnable == true
                  ? BlocProvider<HistoryBloc>(
                    create: (context) {
                      creditRecords.clear();
                      return HistoryBloc()
                        ..add(CreditHistoryTransactionsLoad());
                    },
                    child: BlocConsumer<HistoryBloc, HistoryState>(
                      listener: (context, state) {
                        if (state is HistoryError) {
                          showErrorToast(state.error, context);
                          // ErrorDialog.showErrorDialog(
                          //     context, state.error);
                        }
                        if (state is HistorySessionError) {
                          sessionExpiredLogOut(state.error);
                        }
                        /* --------------------------------------------- Listen to maintenance error, navigate to maintenance page */
                        if (state is HistoryMaintenanceError) {
                          Navigator.pushAndRemoveUntil<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder:
                                  (BuildContext context) => MaintenanceScreen(
                                    parameters: MaintenanceParameters(
                                      message: state.message,
                                    ),
                                  ),
                            ),
                            ModalRoute.withName('/'),
                          );
                        }
                      },
                      builder: (context, state) {
                        return _buildTabCredit(context);
                      },
                    ),
                  )
                  : pointEnable == true && pointHistory == true
                  ? BlocProvider<HistoryBloc>(
                    create: (context) {
                      records.clear();
                      return HistoryBloc()..add(HistoryTransactionsLoad());
                    },
                    child: BlocConsumer<HistoryBloc, HistoryState>(
                      listener: (context, state) {
                        if (state is HistoryError) {
                          showErrorToast(state.error, context);
                        }
                        if (state is HistorySessionError) {
                          sessionExpiredLogOut(state.error);
                        }
                        /* --------------------------------------------- Listen to maintenance error, navigate to maintenance page */
                        if (state is HistoryMaintenanceError) {
                          Navigator.pushAndRemoveUntil<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder:
                                  (BuildContext context) => MaintenanceScreen(
                                    parameters: MaintenanceParameters(
                                      message: state.message,
                                    ),
                                  ),
                            ),
                            ModalRoute.withName('/'),
                          );
                        }
                      },
                      builder: (context, state) {
                        return _buildHistory(context);
                      },
                    ),
                  )
                  : const SingleChildScrollView(
                    child: AccountEmptyState(
                      palette: AppDesign.history,
                      title: 'No transaction history yet',
                      message: 'Your transactions will appear here.',
                      asset: 'assets/icons/wallet/no_transaction.webp',
                    ),
                  ),
        );
  }

  Widget _buildHistory(BuildContext context) {
    return BlocConsumer<HistoryBloc, HistoryState>(
      listener: ((context, state) {
        if (state is HistoryListStop) {
          showPaginationToast('No more transaction', context);
        }
      }),
      builder: (context, state) {
        if (state is HistoryLoading) {
          return LoadingWidget();
        }

        if (state is HistoryTransactionsLoaded &&
            !identical(state, _lastPointPage)) {
          _lastPointPage = state;
          // first check if api returns any historical records,
          if (state.history.records != null &&
              state.history.records!.isNotEmpty) {
            // if history.records is neither null or empty
            // append to the global records variable (List<Records>)
            records.addAll(state.history.records!);
            BlocProvider.of<HistoryBloc>(context).isFetching = false;
            BlocProvider.of<HistoryBloc>(context).isFirstShowPoint = false;
          }

          // comment: instead of working with the records from api,
          // records.add(state.history.records);
          // comment: work with the global variable that has the records from API added above
          BlocProvider.of<HistoryBloc>(context).isFetching = false;
          BlocProvider.of<HistoryBloc>(context).isFirstShowPoint = false;
        }
        if (state is HistoryEmpty) {
          return const SingleChildScrollView(
            child: AccountEmptyState(
              palette: AppDesign.history,
              title: 'No points history yet',
              message: 'Your points transactions will appear here.',
              asset: 'assets/icons/wallet/no_transaction.webp',
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: Container(child: _buildTransactionList(context, state)),
            ),
            state is HistoryPointNextLoading
                ? SizedBox(child: LoadingWidget())
                : Container(),
          ],
        );
      },
    );
  }

  Widget _buildTransactionList(BuildContext context, HistoryState state) {
    if (state is HistoryTransactionsLoaded) {
      history = state.history;
    }

    if (history != null) {
      return ListView.builder(
        padding: EdgeInsets.only(bottom: 40),
        shrinkWrap: true,
        controller: _pointScrollController,
        itemCount: records.length,
        itemBuilder: (BuildContext context, int index) {
          final month = historyMonth(records[index].date);
          final previous =
              index == 0 ? null : historyMonth(records[index - 1].date);
          return Column(
            children: [
              if (month.isNotEmpty && month != previous)
                HistoryMonthHeader(month),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.pagePadding,
                ),
                child: records[index].getHistoryTile(
                  context: context,
                  state: state,
                ),
              ),
            ],
          );
        },
      );
    }

    return Container();
  }

  Widget _buildTabCredit(BuildContext context) {
    return BlocConsumer<HistoryBloc, HistoryState>(
      listener: ((context, state) {
        if (state is CreditHistoryListStop) {
          showPaginationToast('No more transaction', context);
        }
      }),
      builder: (context, state) {
        if (state is HistoryLoading) {
          return LoadingWidget();
        }

        if (state is CreditHistoryTransactionsLoaded &&
            !identical(state, _lastCreditPage)) {
          _lastCreditPage = state;
          // first check if api returns any historical records,
          if (state.history.records != null &&
              state.history.records!.isNotEmpty) {
            // if history.records is neither null or empty
            // append to the global records variable (List<CreditRecords>)
            creditRecords.addAll(state.history.records!);
            BlocProvider.of<HistoryBloc>(context).isCreditFetching = false;
            BlocProvider.of<HistoryBloc>(context).isFirstShow = false;
          }

          // comment: instead of working with the records from api,
          // records.add(state.history.records);
          // comment: work with the global variable that has the records from API added above
          BlocProvider.of<HistoryBloc>(context).isCreditFetching = false;
          BlocProvider.of<HistoryBloc>(context).isFirstShow = false;
        }

        if (state is CreditHistoryEmpty) {
          return const SingleChildScrollView(
            child: AccountEmptyState(
              palette: AppDesign.history,
              title: 'No credit history yet',
              message: 'Your credit transactions will appear here.',
              asset: 'assets/icons/wallet/no_transaction.webp',
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: Container(
                child: _buildCreditTransactionList(context, state),
              ),
            ),
            state is HistoryCreditNextLoading
                ? SizedBox(child: LoadingWidget())
                : Container(),
          ],
        );
      },
    );
  }

  Widget _buildCreditTransactionList(BuildContext context, HistoryState state) {
    if (state is CreditHistoryTransactionsLoaded) {
      creditHistory = state.history;
    }

    if (creditHistory != null) {
      return ListView.builder(
        padding: EdgeInsets.only(bottom: 40),
        shrinkWrap: true,
        controller: _creditScrollController,
        itemCount: creditRecords.length,
        itemBuilder: (BuildContext context, int index) {
          final month = historyMonth(creditRecords[index].date);
          final previous =
              index == 0 ? null : historyMonth(creditRecords[index - 1].date);
          return Column(
            children: [
              if (month.isNotEmpty && month != previous)
                HistoryMonthHeader(month),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.pagePadding,
                ),
                child: creditRecords[index].getCreditHistoryTile(
                  context: context,
                ),
              ),
            ],
          );
        },
      );
    }

    return Container();
  }

  void sessionExpiredLogOut(String error) {
    showErrorToast('$error\nYou will be logged out.', context);
    BlocProvider.of<AuthenticationBloc>(context).add(AuthenticationLoggedOut());
    Navigator.of(context).pushNamedAndRemoveUntil(
      OderRoutes.login,
      (Route<dynamic> route) => false,
    );
  }
}
