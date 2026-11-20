import 'package:bilite/grpc/bilibili/main/community/reply/v1.pb.dart'
    show SearchItemReply, SearchItem, SearchItemType;
import 'package:bilite/grpc/reply.dart';
import 'package:bilite/http/loading_state.dart';
import 'package:bilite/models/common/reply/reply_search_type.dart';
import 'package:bilite/pages/common/common_list_controller.dart';
import 'package:bilite/pages/video/reply_search_item/controller.dart';

class ReplySearchChildController
    extends CommonListController<SearchItemReply, SearchItem> {
  ReplySearchChildController(this.controller, this.searchType);

  final ReplySearchController controller;
  final ReplySearchType searchType;

  @override
  List<SearchItem>? getDataList(SearchItemReply response) {
    if (!response.cursor.hasNext) {
      isEnd = true;
    }
    return response.items;
  }

  @override
  Future<LoadingState<SearchItemReply>> customGetData() {
    return ReplyGrpc.searchItem(
      page: page,
      itemType: searchType == ReplySearchType.video
          ? SearchItemType.VIDEO
          : SearchItemType.ARTICLE,
      oid: controller.oid,
      type: controller.type,
      keyword: controller.editingController.text,
    );
  }
}
