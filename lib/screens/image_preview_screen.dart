import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class ImagePreviewScreen extends StatelessWidget {
  final AssetEntity asset;

  const ImagePreviewScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: FutureBuilder(
          future: asset.originBytes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
              return InteractiveViewer(
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                ),
              );
            }
            return const CircularProgressIndicator(color: Colors.white);
          },
        ),
      ),
    );
  }
}
