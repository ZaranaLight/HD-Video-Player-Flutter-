import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cleaner_state.dart';

class CleanerCubit extends Cubit<CleanerState> {
  CleanerCubit() : super(CleanerInitial());

  List<AssetEntity> _allAssets = [];
  bool _skipDeleteConfirmation = false;

  bool get skipDeleteConfirmation => _skipDeleteConfirmation;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _skipDeleteConfirmation = prefs.getBool('skip_delete_confirmation') ?? false;
  }

  Future<void> toggleSkipDeleteConfirmation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skip_delete_confirmation', value);
    _skipDeleteConfirmation = value;
  }

  Future<void> loadAssets() async {
    emit(CleanerLoading());
    await loadPreferences();
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth) {
        final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
          type: RequestType.common,
        );
        
        _allAssets = [];
        for (var path in paths) {
          final int count = await path.assetCountAsync;
          if (count > 0) {
            final List<AssetEntity> assets = await path.getAssetListRange(
              start: 0, 
              end: count.clamp(0, 50),
            );
            _allAssets.addAll(assets);
          }
        }

        _allAssets.shuffle();

        if (_allAssets.isEmpty) {
          emit(CleanerEmpty());
        } else {
          emit(CleanerLoaded(List.from(_allAssets)));
        }
      } else {
        emit(const CleanerError('Permission denied to access media.'));
      }
    } catch (e) {
      emit(CleanerError('Error loading media: $e'));
    }
  }

  void keepAsset(AssetEntity asset) {
    if (state is CleanerLoaded) {
      final currentAssets = List<AssetEntity>.from((state as CleanerLoaded).assets);
      currentAssets.remove(asset);
      _updateState(currentAssets);
    }
  }

  Future<void> deleteAsset(AssetEntity asset) async {
    if (state is CleanerLoaded) {
      try {
        // We always use photo_manager's editor as it's safer for OS compliance.
        final List<String> result = await PhotoManager.editor.deleteWithIds([asset.id]);
        if (result.isNotEmpty) {
          final currentAssets = List<AssetEntity>.from((state as CleanerLoaded).assets);
          currentAssets.remove(asset);
          _updateState(currentAssets);
        }
      } catch (e) {
        // Fallback for UI responsiveness
        final currentAssets = List<AssetEntity>.from((state as CleanerLoaded).assets);
        currentAssets.remove(asset);
        _updateState(currentAssets);
      }
    }
  }

  void _updateState(List<AssetEntity> assets) {
    if (assets.isEmpty) {
      emit(CleanerEmpty());
    } else {
      emit(CleanerLoaded(assets));
    }
  }
}
