import 'package:bilite/http/loading_state.dart';
import 'package:bilite/http/video.dart';
import 'package:bilite/models/model_hot_video_item.dart';
import 'package:bilite/pages/common/common_list_controller.dart';
import 'package:get/get.dart';

class RelatedController
    extends CommonListController<List<HotVideoItemModel>?, HotVideoItemModel> {
  RelatedController({this.autoQuery = true});
  String bvid = Get.arguments['bvid'];
  final bool autoQuery;

  @override
  void onInit() {
    super.onInit();
    if (autoQuery) {
      queryData();
    }
  }

  @override
  Future<LoadingState<List<HotVideoItemModel>?>> customGetData() =>
      VideoHttp.relatedVideoList(bvid: bvid);
}
