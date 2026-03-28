import 'package:photo_manager/photo_manager.dart';

class MediaFolder {
  final AssetPathEntity path;
  final int assetCount;
  final AssetEntity? thumbnail;

  MediaFolder({
    required this.path,
    required this.assetCount,
    this.thumbnail,
  });

  String get name => path.name;
  String get id => path.id;
}
