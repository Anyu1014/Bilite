import 'package:bilite/http/loading_state.dart';
import 'package:bilite/http/search.dart';
import 'package:bilite/models_new/search/search_trending/data.dart';
import 'package:bilite/models_new/search/search_trending/list.dart';
import 'package:bilite/pages/common/common_list_controller.dart';

class SearchTrendingController
    extends CommonListController<SearchTrendingData, SearchTrendingItemModel> {
  int topCount = 0;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<SearchTrendingItemModel>? getDataList(SearchTrendingData response) {
    topCount = response.topCount;
    return response.list;
  }

  @override
  Future<LoadingState<SearchTrendingData>> customGetData() =>
      SearchHttp.searchTrending(needsTop: true);
}
