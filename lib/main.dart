import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'bloc/media_bloc.dart';
import 'bloc/media_event.dart';
import 'bloc/media_state.dart';
import 'bloc/nav_bloc.dart';
import 'models/media_folder.dart';
import 'screens/media_list_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/ease_cleaner_screen.dart';
import 'bloc/cleaner_cubit.dart';
import 'services/ads_service.dart';
import 'services/remote_config_service.dart';
import 'services/session_service.dart';
import 'widgets/banner_ad_widget.dart';
import 'widgets/native_ad_widget.dart';
import 'widgets/folder_grid_item.dart';
import 'widgets/folder_list_item.dart';
import 'widgets/custom_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Session
  await SessionService().incrementSession();

  // Initialize Remote Config
  await RemoteConfigService().initialize();

  // Initialize Ads
  await AdsService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial launch ad trigger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdsService().showAppOpenAdIfAvailable();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_pausedTime != null) {
        final difference = now.difference(_pausedTime!);
        if (difference.inSeconds > 5) {
          AdsService().showAppOpenAdIfAvailable();
        }
      } else {
        AdsService().showAppOpenAdIfAvailable();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => MediaBloc()),
        BlocProvider(create: (context) => NavBloc()),
        BlocProvider(create: (context) => CleanerCubit()),
      ],
      child: MaterialApp(
        title: 'MX Player Clone',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
        ),
        home: const PermissionGate(),
      ),
    );
  }
}

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _isChecking = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final state = await pm.PhotoManager.requestPermissionExtend();
    if (state.isAuth) {
      _grantAccess();
    } else {
      setState(() {
        _isChecking = false;
        _hasPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final state = await pm.PhotoManager.requestPermissionExtend();
    
    // For Android 11+ (API 30+), manageExternalStorage might be needed for some deletions
    if (Platform.isAndroid) {
      await Permission.manageExternalStorage.request();
    }

    if (state.isAuth) {
      _grantAccess();
    } else {
      // Still denied, maybe show a toast or stay on this screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission required to show media")),
      );
    }
  }

  void _grantAccess() {
    context.read<MediaBloc>().add(LoadMediaFolders());
    context.read<CleanerCubit>().loadAssets();
    setState(() {
      _isChecking = false;
      _hasPermission = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  "Media Access Required",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                  Text(
                  "This app needs your permission to scan and show photos and videos from your device.",
                  textAlign:TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _requestPermission,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Allow Access"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const AppContainer();
  }
}

class AppContainer extends StatelessWidget {
  const AppContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavBloc, NavItem>(
      builder: (context, activeItem) {
        return Scaffold(
          body: Stack(
            children: [
              IndexedStack(
                index: activeItem.index,
                children: const [
                  FolderListScreen(),
                  WishlistScreen(),
                  EaseCleanerScreen(),
                ],
              ),
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomBottomNav(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavBloc, NavItem>(
      listener: (context, navItem) {
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
          context.read<MediaBloc>().add(const SearchFolders(''));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: const Icon(Icons.grid_view_rounded, color: Colors.white),
          title: const Text(
            'Folders',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isGridView ? Icons.list : Icons.grid_view_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                context.read<MediaBloc>().add(LoadMediaFolders());
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  context.read<MediaBloc>().add(SearchFolders(value));
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search folders...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  fillColor: const Color(0xFF1E1E1E),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const BannerAdWidget(),
            Expanded(
              child: BlocBuilder<MediaBloc, MediaState>(
                builder: (context, state) {
                  if (state is MediaInitial || state is MediaLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is MediaLoaded) {
                    if (state.folders.isEmpty) {
                      return const Center(child: Text('No folders found'));
                    }
                    return _buildFoldersWithAds(state.folders);
                  } else if (state is MediaError) {
                    return Center(child: Text(state.message));
                  }
                  return const Center(child: Text('Error loading media'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersWithAds(List<MediaFolder> folders) {
    List<Widget> slivers = [];
    int itemsPerRow = _isGridView ? 2 : 1;
    int rowsPerAd = 4;
    int itemsPerAd = itemsPerRow * rowsPerAd;

    for (int i = 0; i < folders.length; i += itemsPerAd) {
      int end =
          (i + itemsPerAd < folders.length) ? i + itemsPerAd : folders.length;
      List<MediaFolder> chunk = folders.sublist(i, end);

      if (_isGridView) {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final folder = chunk[index];
                return FolderGridItem(
                  folder: folder,
                  onTap: () => _onFolderTap(folder),
                );
              }, childCount: chunk.length),
            ),
          ),
        );
      } else {
        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final asset = chunk[index];
              return FolderListItem(
                folder: asset,
                onTap: () => _onFolderTap(asset),
              );
            }, childCount: chunk.length),
          ),
        );
      }

      if (end < folders.length) {
        slivers.add(
          const SliverToBoxAdapter(
            child: NativeAdWidget(factoryId: 'medium', height: 230),
          ),
        );
      }
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 100)));

    return CustomScrollView(slivers: slivers);
  }

  void _onFolderTap(MediaFolder folder) {
    AdsService().showInterstitialAd(
      trigger: 'folder_to_media_list',
      onAdClosed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaListScreen(folder: folder),
          ),
        );
      },
    );
  }
}
