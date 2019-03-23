import 'package:gsy_github_app_flutter/bloc/base/base_bloc.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';

/**
 * Created by guoshuyu
 * on 2019/3/23.
 */
class TrendBloc extends BlocListBase {
  requestRefresh(selectTime, selectType) async {
    pageReset();
    var res = await ReposDao.getTrendDao(since: selectTime.value, languageType: selectType.value);
    changeLoadMoreStatus(getLoadMoreStatus(res));
    return res;
  }
}
