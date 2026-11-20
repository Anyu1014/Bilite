import 'package:bilite/http/dynamics.dart';
import 'package:bilite/http/loading_state.dart';
import 'package:bilite/models_new/dynamic/dyn_topic_top/topic_item.dart';
import 'package:bilite/pages/common/common_list_controller.dart';

class DynTopicRcmdController
    extends CommonListController<List<TopicItem>?, TopicItem> {
  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<LoadingState<List<TopicItem>?>> customGetData() =>
      DynamicsHttp.dynTopicRcmd();
}
