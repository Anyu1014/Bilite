import 'package:bilite/grpc/bilibili/app/viewunite/v1.pb.dart'
    show ViewReq, ViewReply;
import 'package:bilite/grpc/grpc_req.dart';
import 'package:bilite/grpc/url.dart';
import 'package:bilite/http/loading_state.dart';

abstract final class ViewGrpc {
  static Future<LoadingState<ViewReply>> view({
    required String bvid,
  }) {
    return GrpcReq.request(
      GrpcUrl.view,
      ViewReq(bvid: bvid),
      ViewReply.fromBuffer,
    );
  }
}
