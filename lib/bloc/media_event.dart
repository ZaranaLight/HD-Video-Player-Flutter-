import 'package:equatable/equatable.dart';
import 'package:photo_manager/photo_manager.dart';

abstract class MediaEvent extends Equatable {
  const MediaEvent();

  @override
  List<Object?> get props => [];
}

class LoadMediaFolders extends MediaEvent {}

class SearchFolders extends MediaEvent {
  final String query;

  const SearchFolders(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadFolderAssets extends MediaEvent {
  final AssetPathEntity path;

  const LoadFolderAssets(this.path);

  @override
  List<Object?> get props => [path];
}

class SearchAssets extends MediaEvent {
  final String query;

  const SearchAssets(this.query);

  @override
  List<Object?> get props => [query];
}

enum SortType { name, date, size }

class SortAssets extends MediaEvent {
  final SortType sortType;
  final bool ascending;

  const SortAssets(this.sortType, {this.ascending = true});

  @override
  List<Object?> get props => [sortType, ascending];
}
