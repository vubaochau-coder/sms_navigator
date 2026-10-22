import 'package:flutter_bloc/flutter_bloc.dart';

/// Các tab của màn chính, theo thứ tự hiển thị trên thanh điều hướng.
enum HomeTab { sms, channels, activity, device }

/// Tab đang chọn của màn chính — để widget con (vd banner) chuyển tab được.
class HomeTabCubit extends Cubit<HomeTab> {
  HomeTabCubit([super.initialState = HomeTab.sms]);

  void select(HomeTab tab) {
    if (tab != state) emit(tab);
  }
}
