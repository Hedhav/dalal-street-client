import 'package:dalal_street_client/grpc/client.dart';
import 'package:dalal_street_client/proto_build/actions/Login.pb.dart';
import 'package:dalal_street_client/proto_build/datastreams/Subscribe.pb.dart';
import 'package:dalal_street_client/proto_build/models/User.pb.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'user_event.dart';
part 'user_state.dart';

/// Handles the Authentication State of User. Also persists the state using [HydratedBloc]
///
/// Must be provided at the root of the app widget tree
///
/// The [UserBloc] object can be accesed from anywhere in the widget tree easily using a [BuildContext] :
/// ```dart
/// final userBloc = context.read<UserBloc>();
/// userBloc.add(const UserLogOut());
/// ```
class UserBloc extends HydratedBloc<UserEvent, UserState> {
  late String sessionId;
  late SubscriptionId subscriptionId;

  UserBloc() : super(const UserLoggedOut()) {
    on<UserLogIn>((event, emit) async {
      emit(UserLoggedIn(
          event.loginResponse.user, event.loginResponse.sessionId));
      // Stream Testing
      try {
        sessionId = event.loginResponse.sessionId;
        final subResp = await streamClient.subscribe(
            SubscribeRequest(dataStreamType: DataStreamType.TRANSACTIONS),
            options: sessionOptions(sessionId));
        print('Subscription status = ${subResp.statusCode}');
        subscriptionId = subResp.subscriptionId;
        final stream = streamClient.getTransactionUpdates(subscriptionId,
            options: sessionOptions(sessionId));
        await for (var update in stream) {
          print('New Transaction: $update');
        }
      } catch (e) {
        print('Error during subscribe: $e');
      }
    });
    on<UserLogOut>((event, emit) async {
      emit(const UserLoggedOut());
      // Stream Testing
      try {
        final unSubResp = await streamClient.unsubscribe(
            UnsubscribeRequest(subscriptionId: subscriptionId),
            options: sessionOptions(sessionId));
        print('UnSubscribe Status: ${unSubResp.statusCode}');
      } catch (e) {
        print('Error during unsubscribe: $e');
      }
    });
  }

  // Methods required by HydratedBloc to persist state
  @override
  UserState? fromJson(Map<String, dynamic> json) {
    try {
      final user = User.fromJson(json['user']);
      final sessionId = json['sessionId'];
      return UserLoggedIn(user, sessionId);
    } catch (_) {
      return const UserLoggedOut();
    }
  }

  @override
  Map<String, dynamic>? toJson(UserState state) {
    if (state is UserLoggedIn) {
      return {
        'user': state.user.writeToJson(),
        // TODO: Encrypt sessionId
        'sessionId': state.sessionId,
      };
    }
    return {};
  }
}
