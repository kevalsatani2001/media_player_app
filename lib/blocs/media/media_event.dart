import 'package:equatable/equatable.dart';

abstract class MediaEvent extends Equatable {
  const MediaEvent();

  @override
  List<Object?> get props => [];
}

class LoadMedia extends MediaEvent {
  final String type;

  const LoadMedia(this.type);
}
