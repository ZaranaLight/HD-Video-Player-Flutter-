import 'package:equatable/equatable.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/media_folder.dart';

abstract class MediaState extends Equatable {
  const MediaState();

  @override
  List<Object?> get props => [];
}

class MediaInitial extends MediaState {}

class MediaLoading extends MediaState {}

class MediaLoaded extends MediaState {
  final List<MediaFolder> folders;

  const MediaLoaded(this.folders);

  @override
  List<Object?> get props => [folders];
}

class FolderAssetsLoaded extends MediaState {
  final List<AssetEntity> assets;

  const FolderAssetsLoaded(this.assets);

  @override
  List<Object?> get props => [assets];
}

class MediaError extends MediaState {
  final String message;

  const MediaError(this.message);

  @override
  List<Object?> get props => [message];
}

class PermissionDenied extends MediaState {}
