import 'package:equatable/equatable.dart';

abstract class EaseCleanerEvent extends Equatable {
  const EaseCleanerEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllMedia extends EaseCleanerEvent {}

class DeleteMediaFromSwiper extends EaseCleanerEvent {
  final String assetId;
  const DeleteMediaFromSwiper(this.assetId);

  @override
  List<Object?> get props => [assetId];
}
