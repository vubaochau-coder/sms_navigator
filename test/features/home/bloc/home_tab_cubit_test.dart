import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/home/bloc/home_tab_cubit.dart';

void main() {
  test('starts on SMS and switches tabs', () async {
    final cubit = HomeTabCubit();
    expect(cubit.state, HomeTab.sms);

    cubit.select(HomeTab.device);
    expect(cubit.state, HomeTab.device);
    await cubit.close();
  });

  test('selecting the current tab emits nothing', () async {
    final cubit = HomeTabCubit(HomeTab.channels);
    final emitted = <HomeTab>[];
    final sub = cubit.stream.listen(emitted.add);

    cubit.select(HomeTab.channels);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isEmpty);
    await sub.cancel();
    await cubit.close();
  });
}
