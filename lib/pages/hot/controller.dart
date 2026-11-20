import 'package:bilite/http/loading_state.dart';
import 'package:bilite/http/video.dart';
import 'package:bilite/models/model_hot_video_item.dart';
import 'package:bilite/pages/common/common_list_controller.dart';

class HotController
    extends CommonListController<List<HotVideoItemModel>, HotVideoItemModel> {
  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<LoadingState<List<HotVideoItemModel>>> customGetData() =>
      VideoHttp.hotVideoList(
        pn: page,
        ps: 20,
      );
}
