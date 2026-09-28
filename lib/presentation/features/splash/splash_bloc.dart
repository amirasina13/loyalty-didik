import 'package:bloc/bloc.dart';
// import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

import '../authentication/authentication.dart';
import 'splash.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final AuthenticationBloc authenticationBloc;
  bool _hasStarted = false;
  // final dynamicLink = FirebaseDynamicLinks.instance;

  SplashBloc({required this.authenticationBloc}) : super(SplashInitial()) {
    on<SplashStart>((event, emit) {
      // A splash route can be rebuilt while the first frame is still being
      // drawn. Do not start the authentication bootstrap more than once.
      if (_hasStarted) return;

      _hasStarted = true;
      emit(SplashLoading());

      // AuthenticationBloc performs the authoritative connectivity,
      // configuration and token checks. Start it immediately instead of
      // waiting through the old artificial two-second delay.
      authenticationBloc.add(AuthenticationAppStarted());
    });
  }
}
