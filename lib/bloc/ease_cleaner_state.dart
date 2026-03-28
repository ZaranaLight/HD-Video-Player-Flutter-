import 'package:equatable/equatable.dart';
import 'package:photo_manager/photo_manager.dart';

abstract class EaseCleanerState extends Equatable {
  const EaseCleanerState();

  @override
  List<Object?> get props => [];
}

class EaseCleanerInitial extends EaseCleanerState {}

class EaseCleanerLoading extends EaseCleanerState {}

class EaseCleanerLoaded extends EaseCleanerState {
  final List<AssetEntity> assets;
  const EaseCleanerLoaded(this.assets);

  @override
  List<Object?> get props => [assets];
}

class EaseCleanerError extends EaseCleanerState {
  final String message;
  const EaseCleanerError(this.message);

  @override
  List<Object?> get props => [message];
}
