import 'package:bilite/http/loading_state.dart';
import 'package:bilite/http/user.dart';
import 'package:bilite/models_new/follow/data.dart';
import 'package:bilite/pages/follow_type/controller.dart';

class FollowedController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.followedUp(mid: mid, pn: page);
}
