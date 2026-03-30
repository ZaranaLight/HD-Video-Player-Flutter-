import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../bloc/cleaner_cubit.dart';
import '../bloc/cleaner_state.dart';

class EaseCleanerScreen extends StatefulWidget {
  const EaseCleanerScreen({super.key});

  @override
  State<EaseCleanerScreen> createState() => _EaseCleanerScreenState();
}

class _EaseCleanerScreenState extends State<EaseCleanerScreen> {
  final CardSwiperController _controller = CardSwiperController();


  @override
  void initState() {
    super.initState();
    _getPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getPermission() async {
    PermissionStatus status = await Permission.manageExternalStorage.status;
    if (status.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }

  Future<bool> _showDeleteDialog() async {
    bool dontAskAgain = false;

    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (innerContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Delete this media?", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Are you sure you want to delete this file?",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: dontAskAgain,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setStateDialog(() {
                            dontAskAgain = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text("Don't ask me again",
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(innerContext, false),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    if (dontAskAgain) {
                      final cubit = innerContext.read<CleanerCubit>();
                      await cubit.toggleSkipDeleteConfirmation(true);
                    }
                    if (innerContext.mounted) Navigator.pop(innerContext, true);
                  },
                  child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Ease Cleaner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<CleanerCubit>().loadAssets(),
          ),
        ],
      ),
      body: BlocBuilder<CleanerCubit, CleanerState>(
        builder: (context, state) {
          if (state is CleanerLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          } else if (state is CleanerError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          } else if (state is CleanerEmpty) {
            return _buildEmptyState();
          } else if (state is CleanerLoaded) {
            return Column(
              children: [
                Expanded(
                  child: CardSwiper(
                    key: ValueKey(state.assets.isNotEmpty ? state.assets.first.id : 'empty'),
                    controller: _controller,
                    cardsCount: state.assets.length,
                    initialIndex: 0,
                    numberOfCardsDisplayed: min(state.assets.length, 3),
                    onSwipe: (previousIndex, currentIndex, direction) async {
                      final asset = state.assets[previousIndex];
                      
                      // Allow swipe animation to finish before rebuilding the swiper
                      await Future.delayed(const Duration(milliseconds: 300));
                      
                      if (direction == CardSwiperDirection.left) {
                        final cubit = context.read<CleanerCubit>();
                        final skip = cubit.skipDeleteConfirmation;
                        if (!skip) {
                          final confirm = await _showDeleteDialog();
                          if (!confirm || !mounted) return false;
                        }
                        // Don't await here so the UI remains fluid while the system dialog pops up
                        cubit.deleteAsset(asset);
                      } else if (direction == CardSwiperDirection.right) {
                        context.read<CleanerCubit>().keepAsset(asset);
                      }
                      
                      return true;
                    },
                    cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
                      return Stack(
                        children: [
                          CleanerCard(
                            asset: state.assets[index],
                            horizontalThreshold: horizontalThresholdPercentage,
                          ),
                          Positioned(
                            top: 20,
                            right: 20,
                            child: IconButton(
                              icon: const Icon(Icons.info_outline, color: Colors.white70, size: 28),
                              onPressed: () => _showInfoDialog(state.assets[index]),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                _buildSwipeActions(),
                const SizedBox(height: 110),
              ],
            );
          }
          return Container();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text('Storage is already clean!',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.read<CleanerCubit>().loadAssets(),
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RoundButton(
            onPressed: () => _controller.swipe(CardSwiperDirection.left),
            icon: Icons.close,
            color: const Color(0xFFFF3B30), // Tinder-style red
          ),
          _RoundButton(
            onPressed: () => _controller.swipe(CardSwiperDirection.right),
            icon: Icons.check,
            color: const Color(0xFF4CD964), // Tinder-style green
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(AssetEntity asset) {
    showDialog(
      context: context,
      builder: (context) => FileInfoDialog(asset: asset),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  const _RoundButton({required this.onPressed, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(18),
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        child: Icon(icon, size: 30),
      ),
    );
  }
}

class CleanerCard extends StatelessWidget {
  final AssetEntity asset;
  final int horizontalThreshold;

  const CleanerCard({super.key, required this.asset, required this.horizontalThreshold});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBlurredBackground(asset),
            Center(
              child: AssetThumbnail(asset: asset),
            ),
            if (asset.type == AssetType.video)
              const Center(
                child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 80),
              ),
            if (horizontalThreshold != 0) _buildSwipeIndicator(),
            _buildInfoOverlay(asset),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeIndicator() {
    final bool isLeft = horizontalThreshold < 0;
    final int absThreshold = horizontalThreshold.abs();
    if (absThreshold < 5) return const SizedBox.shrink();

    final double opacity = (absThreshold / 40).clamp(0.0, 1.0);

    return Positioned(
      top: 40,
      left: !isLeft ? 20 : null,
      right: isLeft ? 20 : null,
      child: Transform.rotate(
        angle: isLeft ? -0.2 : 0.2,
        child: Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: isLeft ? Colors.red : Colors.green, width: 4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isLeft ? "DELETE" : "KEEP",
              style: TextStyle(
                color: isLeft ? Colors.red : Colors.green,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlurredBackground(AssetEntity asset) {
    return FutureBuilder<dynamic>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(100, 100)),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(snapshot.data, fit: BoxFit.cover),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ],
          );
        }
        return Container(color: Colors.black54);
      },
    );
  }

  Widget _buildInfoOverlay(AssetEntity asset) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              asset.title ?? 'Unknown',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  asset.type == AssetType.video ? Icons.videocam : Icons.image,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${asset.width} x ${asset.height}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                if (asset.type == AssetType.video)
                  Text(
                    _formatDuration(asset.duration),
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final dur = Duration(seconds: seconds);
    final minutes = dur.inMinutes;
    final remainingSeconds = dur.inSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class AssetThumbnail extends StatelessWidget {
  final AssetEntity asset;

  const AssetThumbnail({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(800, 1200)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return Image.memory(
            snapshot.data,
            fit: BoxFit.contain,
            errorBuilder: (context, _, __) => const Center(child: Icon(Icons.error)),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class FileInfoDialog extends StatelessWidget {
  final AssetEntity asset;

  const FileInfoDialog({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("File Information", style: TextStyle(color: Colors.white)),
      content: FutureBuilder(
        future: asset.file,
        builder: (context, snapshot) {
          final file = snapshot.data;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoTile("Name", asset.title ?? 'Unknown'),
              _infoTile("Path", file?.path ?? 'Unknown'),
              _infoTile("Size", file != null ? _formatBytes(file.lengthSync()) : 'Calculating...'),
              _infoTile("Resolution", '${asset.width} x ${asset.height}'),
              _infoTile("Created", DateFormat('dd MMM yyyy, HH:mm').format(asset.createDateTime)),
              if (asset.type == AssetType.video)
                _infoTile("Duration", '${asset.duration} seconds'),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close", style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return (bytes / pow(1024, i)).toStringAsFixed(2) + ' ' + suffixes[i];
  }
}
