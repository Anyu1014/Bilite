import 'package:PiliPure/models_new/history/data.dart';
import 'package:PiliPure/models_new/history/list.dart';
import 'package:PiliPure/pages/common/search/common_search_page.dart';
import 'package:PiliPure/pages/history/widgets/item.dart';
import 'package:PiliPure/pages/history_search/controller.dart';
import 'package:PiliPure/utils/grid.dart';
import 'package:PiliPure/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HistorySearchPage extends StatefulWidget {
  const HistorySearchPage({super.key});

  @override
  State<HistorySearchPage> createState() => _HistorySearchPageState();
}

class _HistorySearchPageState
    extends
        CommonSearchPageState<HistorySearchPage, HistoryData, HistoryItemModel>
    with GridMixin {
  @override
  final HistorySearchController controller = Get.put(
    HistorySearchController(),
    tag: Utils.generateRandomString(8),
  );

  @override
  Widget buildList(List<HistoryItemModel> list) {
    return SliverGrid.builder(
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        final item = list[index];
        return HistoryItem(
          item: item,
          ctr: controller,
          onDelete: (kid, business) =>
              controller.onDelHistory(index, kid, business),
        );
      },
      itemCount: list.length,
    );
  }
}
