import 'package:PiliPure/http/api.dart';
import 'package:PiliPure/http/init.dart';
import 'package:PiliPure/http/loading_state.dart';
import 'package:PiliPure/models_new/blacklist/data.dart';
import 'package:PiliPure/utils/accounts.dart';

abstract final class BlackHttp {
  static Future<LoadingState<BlackListData>> blackList({
    required int pn,
    int ps = 50,
  }) async {
    final res = await Request().get(
      Api.blackList,
      queryParameters: {
        'pn': pn,
        'ps': ps,
        're_version': 0,
        'jsonp': 'jsonp',
        'csrf': Accounts.main.csrf,
      },
    );
    if (res.data['code'] == 0) {
      return Success(BlackListData.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }
}
