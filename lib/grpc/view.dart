import 'package:PiliPure/grpc/bilibili/app/viewunite/v1.pb.dart'
    show ViewReq, ViewReply;
import 'package:PiliPure/grpc/grpc_req.dart';
import 'package:PiliPure/grpc/url.dart';
import 'package:PiliPure/http/loading_state.dart';

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
