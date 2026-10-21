import 'package:equatable/equatable.dart';

abstract class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

class SplashStarted extends SplashEvent {
  final String defaultDeviceName;

  const SplashStarted({this.defaultDeviceName = 'Thiết bị của tôi'});

  @override
  List<Object?> get props => [defaultDeviceName];
}

class SplashRetried extends SplashEvent {
  final String defaultDeviceName;

  const SplashRetried({this.defaultDeviceName = 'Thiết bị của tôi'});

  @override
  List<Object?> get props => [defaultDeviceName];
}

/// Người dùng chọn "Thiết lập thiết bị mới" ở lần mở đầu tiên (BACKLOG 1.1).
class SplashNewDeviceChosen extends SplashEvent {
  final String defaultDeviceName;

  const SplashNewDeviceChosen({this.defaultDeviceName = 'Thiết bị của tôi'});

  @override
  List<Object?> get props => [defaultDeviceName];
}
