import 'package:bilite/http/loading_state.dart';
import 'package:bilite/http/member.dart';
import 'package:bilite/models_new/space/space_article/data.dart';
import 'package:bilite/models_new/space/space_article/item.dart';
import 'package:bilite/pages/common/common_list_controller.dart';

class MemberArticleCtr
    extends CommonListController<SpaceArticleData, SpaceArticleItem> {
  MemberArticleCtr({
    required this.mid,
  });

  final int mid;

  int count = -1;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<SpaceArticleItem>? getDataList(SpaceArticleData response) {
    count = response.count ?? -1;
    return response.item;
  }

  @override
  void checkIsEnd(int length) {
    if (length >= count) {
      isEnd = true;
    }
  }

  @override
  Future<LoadingState<SpaceArticleData>> customGetData() =>
      MemberHttp.spaceArticle(mid: mid, page: page);
}
