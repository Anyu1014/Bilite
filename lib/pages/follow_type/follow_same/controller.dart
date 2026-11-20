import 'package:bilite/http/loading_state.dart';
import 'package:bilite/http/user.dart';
import 'package:bilite/models_new/follow/data.dart';
import 'package:bilite/pages/follow_type/controller.dart';

class FollowSameController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.sameFollowing(mid: mid, pn: page);
}
