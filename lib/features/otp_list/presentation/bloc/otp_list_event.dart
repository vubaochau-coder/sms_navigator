import 'package:equatable/equatable.dart';

abstract class OtpListEvent extends Equatable {
  const OtpListEvent();

  @override
  List<Object?> get props => [];
}

class OtpListLoadEvent extends OtpListEvent {
  final DateTime date;
  final String? pairId;

  const OtpListLoadEvent({required this.date, this.pairId});

  @override
  List<Object?> get props => [date, pairId];
}

class OtpListToggleGroupEvent extends OtpListEvent {
  const OtpListToggleGroupEvent();
}

class OtpListChangeDateEvent extends OtpListEvent {
  final DateTime selectedDate;

  const OtpListChangeDateEvent(this.selectedDate);

  @override
  List<Object?> get props => [selectedDate];
}
