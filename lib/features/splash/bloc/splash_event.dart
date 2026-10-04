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
