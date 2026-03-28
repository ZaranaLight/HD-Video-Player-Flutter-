import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'ease_cleaner_event.dart';
import 'ease_cleaner_state.dart';

class EaseCleanerBloc extends Bloc<EaseCleanerEvent, EaseCleanerState> {
  EaseCleanerBloc() : super(EaseCleanerInitial()) {
    on<LoadAllMedia>(_onLoadAllMedia);
    on<DeleteMediaFromSwiper>(_onDeleteMedia);
  }

  Future<void> _onLoadAllMedia(
    LoadAllMedia event,
    Emitter<EaseCleanerState> emit,
  ) async {
    emit(EaseCleanerLoading());
    try {
      final PermissionState permission = await PhotoManager.requestPermissionExtend();
      if (permission.isAuth) {
        // Fetch all media (images and videos) from all paths
        final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
          type: RequestType.common,
        );
        
        List<AssetEntity> allAssets = [];
        for (var path in paths) {
          final int count = await path.assetCountAsync;
          final List<AssetEntity> assets = await path.getAssetListRange(start: 0, end: count);
          allAssets.addAll(assets);
        }
        
        // Shuffle to make it interesting for "cleaning"
        allAssets.shuffle();
        
        emit(EaseCleanerLoaded(allAssets));
      } else {
        emit(const EaseCleanerError("Permission denied"));
      }
    } catch (e) {
      emit(EaseCleanerError(e.toString()));
    }
  }

  Future<void> _onDeleteMedia(
    DeleteMediaFromSwiper event,
    Emitter<EaseCleanerState> emit,
  ) async {
    if (state is EaseCleanerLoaded) {
      final currentState = state as EaseCleanerLoaded;
      try {
        final List<String> result = await PhotoManager.editor.deleteWithIds([event.assetId]);
        if (result.isNotEmpty) {
          final updatedAssets = currentState.assets.where((a) => a.id != event.assetId).toList();
          emit(EaseCleanerLoaded(updatedAssets));
        }
      } catch (e) {
        // Optionally handle delete error
      }
    }
  }
}
