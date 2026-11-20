import 'package:bilite/http/loading_state.dart';
import 'package:bilite/http/member.dart';
import 'package:bilite/models/common/member/contribute_type.dart';
import 'package:bilite/models_new/space/space_archive/data.dart';
import 'package:bilite/models_new/space/space_archive/item.dart';
import 'package:bilite/pages/common/common_list_controller.dart';

class MemberComicController
    extends CommonListController<SpaceArchiveData, SpaceArchiveItem> {
  MemberComicController(this.mid);

  final int mid;

  int? count;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  void checkIsEnd(int length) {
    if (count != null && length >= count!) {
      isEnd = true;
    }
  }

  @override
  List<SpaceArchiveItem>? getDataList(SpaceArchiveData response) {
    count = response.count;
    return response.item;
  }

  @override
  Future<LoadingState<SpaceArchiveData>> customGetData() =>
      MemberHttp.spaceArchive(
        type: ContributeType.comic,
        mid: mid,
      );
}
