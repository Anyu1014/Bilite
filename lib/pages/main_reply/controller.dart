import 'package:bilite/grpc/bilibili/main/community/reply/v1.pb.dart'
    show MainListReply;
import 'package:bilite/grpc/reply.dart';
import 'package:bilite/http/loading_state.dart';
import 'package:bilite/pages/common/reply/fold/reply_fold_mixin.dart';
import 'package:bilite/pages/common/reply/reply_controller.dart';
import 'package:get/get.dart';

class MainReplyController extends ReplyController<MainListReply>
    with BaseReplyFoldMixin<MainListReply>, ReplyFoldMixin {
  @override
  late final int oid;
  @override
  late final int replyType;

  @override
  int get sourceId => oid;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    oid = args['oid'];
    replyType = args['replyType'];

    queryData();
  }

  @override
  Future<LoadingState<MainListReply>> customGetData() => ReplyGrpc.mainList(
    type: replyType,
    oid: oid,
    mode: mode,
    cursorNext: cursorNext,
    offset: paginationReply?.nextOffset,
  );
}
