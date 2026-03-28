import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../models/media_folder.dart';
import '../widgets/video_list_item.dart';
import '../bloc/media_bloc.dart';
import '../bloc/media_event.dart';
import '../bloc/media_state.dart';
import '../services/favorites_service.dart';
import 'video_player_screen.dart';
import 'image_preview_screen.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_widget.dart';
import '../services/ads_service.dart';

class MediaListScreen extends StatefulWidget {
  final MediaFolder folder;

  const MediaListScreen({super.key, required this.folder});

  @override
  State<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends State<MediaListScreen> {
  bool _isSearching = false;
  bool _isGridView = false;
  bool _isAscending = true;
  SortType _currentSort = SortType.date;
  final TextEditingController _searchController = TextEditingController();
  final FavoritesService _favoritesService = FavoritesService();
  List<String> _favoriteIds = [];

  @override
  void initState() {
    super.initState();
    context.read<MediaBloc>().add(LoadFolderAssets(widget.folder.path));
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getFavorites();
    setState(() {
      _favoriteIds = favorites;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onAssetTap(AssetEntity asset) {
    AdsService().showInterstitialAd(
      trigger: 'media_list_to_player',
      onAdClosed: () {
        if (asset.type == AssetType.video) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(asset: asset),
            ),
          );
        } else if (asset.type == AssetType.image) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImagePreviewScreen(asset: asset),
            ),
          );
        }
      },
    );
  }

  Future<void> _toggleFavorite(AssetEntity asset) async {
    await _favoritesService.toggleFavorite(asset.id);
    _loadFavorites();
  }

  Future<void> _shareAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)], text: asset.title);
    }
  }

  Future<void> _deleteAsset(AssetEntity asset) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Delete Media',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this item?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final List<String> result = await PhotoManager.editor.deleteWithIds([
        asset.id,
      ]);
      if (result.isNotEmpty) {
        context.read<MediaBloc>().add(LoadFolderAssets(widget.folder.path));
      }
    }
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSortOption(setModalState, SortType.name, 'Name'),
                  _buildSortOption(setModalState, SortType.date, 'Date'),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    title: const Text(
                      'Ascending',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: _isAscending,
                    onChanged: (value) {
                      setModalState(() => _isAscending = value);
                      setState(() => _isAscending = value);
                      context.read<MediaBloc>().add(
                        SortAssets(_currentSort, ascending: _isAscending),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption(
    StateSetter setModalState,
    SortType type,
    String label,
  ) {
    return RadioListTile<SortType>(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: type,
      groupValue: _currentSort,
      activeColor: Colors.blue,
      onChanged: (value) {
        if (value != null) {
          setModalState(() => _currentSort = value);
          setState(() => _currentSort = value);
          context.read<MediaBloc>().add(
            SortAssets(_currentSort, ascending: _isAscending),
          );
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.read<MediaBloc>().add(LoadMediaFolders());
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search in folder...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    context.read<MediaBloc>().add(SearchAssets(value));
                  },
                )
              : Text(
                  widget.folder.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    context.read<MediaBloc>().add(const SearchAssets(''));
                  }
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_vert, color: Colors.grey),
                    onPressed: _showSortMenu,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      _isGridView ? Icons.list : Icons.grid_view,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                  ),
                ],
              ),
            ),
            const BannerAdWidget(),
            Expanded(
              child: BlocBuilder<MediaBloc, MediaState>(
                builder: (context, state) {
                  if (state is MediaLoading) {
                    return _buildShimmerLoading();
                  } else if (state is FolderAssetsLoaded) {
                    if (state.assets.isEmpty) {
                      return const Center(
                        child: Text(
                          'No media found',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return _buildAssetsWithAds(state.assets);
                  } else if (state is MediaError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsWithAds(List<AssetEntity> assets) {
    List<Widget> slivers = [];
    int itemsPerRow = _isGridView ? 2 : 1;
    int rowsPerAd = 4;
    int itemsPerAd = itemsPerRow * rowsPerAd;

    for (int i = 0; i < assets.length; i += itemsPerAd) {
      int end = (i + itemsPerAd < assets.length)
          ? i + itemsPerAd
          : assets.length;
      List<AssetEntity> chunk = assets.sublist(i, end);

      if (_isGridView) {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGridItem(chunk[index]),
                childCount: chunk.length,
              ),
            ),
          ),
        );
      } else {
        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final asset = chunk[index];
              return VideoListItem(
                asset: asset,
                onTap: () => _onAssetTap(asset),
                isFavorite: _favoriteIds.contains(asset.id),
                onToggleFavorite: _toggleFavorite,
                onShare: _shareAsset,
                onDelete: _deleteAsset,
              );
            }, childCount: chunk.length),
          ),
        );
      }

      if (end < assets.length) {
        slivers.add(
          const SliverToBoxAdapter(
            child: NativeAdWidget(factoryId: 'medium', height: 230),
          ),
        );
      }
    }

    return CustomScrollView(slivers: slivers);
  }

  Widget _buildGridItem(AssetEntity asset) {
    final isFav = _favoriteIds.contains(asset.id);
    return GestureDetector(
      onTap: () => _onAssetTap(asset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder(
                      future: asset.thumbnailDataWithSize(
                        const ThumbnailSize(400, 400),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        }
                        return Container(color: Colors.grey[900]);
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    if (asset.type == AssetType.video)
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 18,
                        ),
                        color: const Color(0xFF1E1E1E),
                        onSelected: (value) {
                          if (value == 'favorite') _toggleFavorite(asset);
                          if (value == 'share') _shareAsset(asset);
                          if (value == 'delete') _deleteAsset(asset);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'favorite',
                            child: Row(
                              children: [
                                Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isFav ? 'Remove' : 'Favorite',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share, color: Colors.blue, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Share',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (asset.type == AssetType.video)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatDuration(asset.duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'New',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
            child: Text(
              asset.title ?? 'Unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              asset.type == AssetType.video ? 'Video' : 'Image',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Widget _buildShimmerLoading() {
    return _isGridView
        ? GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: 8,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[900]!,
                highlightColor: Colors.grey[800]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(width: 100, height: 12, color: Colors.black),
                    const SizedBox(height: 4),
                    Container(width: 60, height: 10, color: Colors.black),
                  ],
                ),
              );
            },
          )
        : ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[900]!,
                highlightColor: Colors.grey[800]!,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 120,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 14,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 100,
                              height: 12,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
