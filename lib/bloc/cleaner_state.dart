import 'package:equatable/equatable.dart';
import 'package:photo_manager/photo_manager.dart';

abstract class CleanerState extends Equatable {
  const CleanerState();

  @override
  List<Object?> get props => [];
}

class CleanerInitial extends CleanerState {}

class CleanerLoading extends CleanerState {}

class CleanerLoaded extends CleanerState {
  final List<AssetEntity> assets;

  const CleanerLoaded(this.assets);

  @override
  List<Object?> get props => [assets];
}

class CleanerEmpty extends CleanerState {}

class CleanerError extends CleanerState {
  final String message;

  const CleanerError(this.message);

  @override
  List<Object?> get props => [message];
}
