import 'package:PiliPure/http/loading_state.dart';
import 'package:PiliPure/http/user.dart';
import 'package:PiliPure/models_new/follow/data.dart';
import 'package:PiliPure/pages/follow_type/controller.dart';

class FollowedController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.followedUp(mid: mid, pn: page);
}
