import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lottie/lottie.dart';
import '../services/favorites_service.dart';
import '../widgets/video_list_item.dart';
import 'video_player_screen.dart';
import 'image_preview_screen.dart';
import '../services/ads_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  List<AssetEntity> _favoriteAssets = [];
  List<AssetEntity> _filteredAssets = [];
  bool _isLoading = true;
  bool _isGridView = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final favoriteIds = await _favoritesService.getFavorites();
    final List<AssetEntity> assets = [];

    for (var id in favoriteIds) {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        assets.add(asset);
      }
    }

    setState(() {
      _favoriteAssets = assets;
      _filteredAssets = assets;
      _isLoading = false;
    });
  }

  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAssets = _favoriteAssets;
      } else {
        _filteredAssets = _favoriteAssets
            .where(
              (asset) => (asset.title ?? '').toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
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
        _loadFavorites();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search in wishlist...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onChanged: _filterSearch,
              )
            : const Text(
                'Wishlist',
                style: TextStyle(
                  color: Colors.white,
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
                  _filteredAssets = _favoriteAssets;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredAssets.isEmpty
          ? _buildEmptyState()
          : _isGridView
          ? GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _filteredAssets.length,
              itemBuilder: (context, index) {
                return _buildGridItem(_filteredAssets[index]);
              },
            )
          : ListView.builder(
              itemCount: _filteredAssets.length,
              itemBuilder: (context, index) {
                final asset = _filteredAssets[index];
                return VideoListItem(
                  asset: asset,
                  onTap: () => _onAssetTap(asset),
                  isFavorite: true,
                  onToggleFavorite: _toggleFavorite,
                  onShare: _shareAsset,
                  onDelete: _deleteAsset,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            'https://assets2.lottiefiles.com/packages/lf20_dmw3t0vg.json',
            // A more reliable empty wishlist animation URL
            width: 250,
            height: 250,
            repeat: true,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.favorite_border,
                size: 100,
                color: Colors.grey,
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            _isSearching ? 'No results found' : 'Your wishlist is empty',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(AssetEntity asset) {
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
                          const PopupMenuItem(
                            value: 'favorite',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.white),
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
}
