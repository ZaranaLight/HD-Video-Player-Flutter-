import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/media_folder.dart';
import 'media_event.dart';
import 'media_state.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  List<MediaFolder> _allFolders = [];
  List<AssetEntity> _allAssets = [];
  bool _isAscending = true;

  MediaBloc() : super(MediaInitial()) {
    on<LoadMediaFolders>(_onLoadMediaFolders);
    on<SearchFolders>(_onSearchFolders);
    on<LoadFolderAssets>(_onLoadFolderAssets);
    on<SearchAssets>(_onSearchAssets);
    on<SortAssets>(_onSortAssets);
  }

  Future<void> _onLoadMediaFolders(
    LoadMediaFolders event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    try {
      final PermissionState permission = await PhotoManager.requestPermissionExtend();
      if (permission.isAuth) {
        final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
          type: RequestType.common,
        );
        _allFolders = [];
        for (var path in paths) {
          final int count = await path.assetCountAsync;
          if (count > 0) {
            final List<AssetEntity> assets = await path.getAssetListRange(start: 0, end: 1);
            _allFolders.add(MediaFolder(
              path: path,
              assetCount: count,
              thumbnail: assets.isNotEmpty ? assets.first : null,
            ));
          }
        }
        emit(MediaLoaded(_allFolders));
      } else {
        emit(PermissionDenied());
      }
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }

  void _onSearchFolders(SearchFolders event, Emitter<MediaState> emit) {
    if (event.query.isEmpty) {
      emit(MediaLoaded(_allFolders));
    } else {
      final filteredFolders = _allFolders
          .where((folder) =>
              folder.name.toLowerCase().contains(event.query.toLowerCase()))
          .toList();
      emit(MediaLoaded(filteredFolders));
    }
  }

  Future<void> _onLoadFolderAssets(
    LoadFolderAssets event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    try {
      final int count = await event.path.assetCountAsync;
      _allAssets = await event.path.getAssetListRange(start: 0, end: count);
      emit(FolderAssetsLoaded(_allAssets));
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }

  void _onSearchAssets(SearchAssets event, Emitter<MediaState> emit) {
    if (event.query.isEmpty) {
      emit(FolderAssetsLoaded(_allAssets));
    } else {
      final filteredAssets = _allAssets
          .where((asset) =>
              (asset.title ?? '').toLowerCase().contains(event.query.toLowerCase()))
          .toList();
      emit(FolderAssetsLoaded(filteredAssets));
    }
  }

  void _onSortAssets(SortAssets event, Emitter<MediaState> emit) {
    _isAscending = event.ascending;
    List<AssetEntity> sortedList = List.from(_allAssets);

    switch (event.sortType) {
      case SortType.name:
        sortedList.sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
        break;
      case SortType.date:
        sortedList.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
        break;
      case SortType.size:
        // Size sorting is complex as it requires file access, 
        // using title as fallback or skipping for this demo.
        break;
    }

    if (!_isAscending) {
      sortedList = sortedList.reversed.toList();
    }

    emit(FolderAssetsLoaded(sortedList));
  }
}
