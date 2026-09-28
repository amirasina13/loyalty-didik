import '../../../app_setting/app_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../locator.dart';
import '../../widgets/widgets.dart';
import '../profile/profile.dart';
import '../wrapper.dart';
import 'delete_acc.dart';

class DeleteAccMobileScreen extends StatefulWidget {
  const DeleteAccMobileScreen({super.key});

  @override
  State<DeleteAccMobileScreen> createState() => _DeleteAccMobileScreenState();
}

class _DeleteAccMobileScreenState extends State<DeleteAccMobileScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileProcessing) {
          return Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: colorWhite,
            child: LoadingWidget(),
          );
        }
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: OderScaffold(
            background: AppDesign.deleteAccount.background,
            appBarColor: AppDesign.deleteAccount.background,
            title: Text(
              'Delete My Account',
              style: TextStyle(
                fontFamily: fontFamilyMain,
                color: AppDesign.deleteAccount.text,
                fontSize: AppDesign.appBarTitleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            body: DeleteAccMobileWrapper(),
            bottomMenuIndex: 3,
          ),
        );
      },
    );
  }
}

class DeleteAccMobileWrapper extends StatefulWidget {
  const DeleteAccMobileWrapper({super.key});

  @override
  OderWrapperState<DeleteAccMobileWrapper> createState() =>
      _DeleteAccMobileWrapperState();
}

class _DeleteAccMobileWrapperState
    extends OderWrapperState<DeleteAccMobileWrapper> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<DeleteAccBloc>(
      create: (context) {
        return DeleteAccBloc(userRepository: sl());
        // return DeleteAccBloc(userRepository: sl())..add(DeleteAccLoad());
      },
      child: BlocConsumer<DeleteAccBloc, DeleteAccState>(
        listener: (context, state) {},
        builder: (context, state) {
          return getPageView(<Widget>[
            DeleteMobileView(changeView: changePage),
          ]);
        },
      ),
    );
  }
}
