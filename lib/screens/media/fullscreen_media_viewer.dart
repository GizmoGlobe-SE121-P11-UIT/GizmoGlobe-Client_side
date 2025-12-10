import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullscreenMediaViewer extends StatefulWidget {
  final String? imageUrl;
  final String? videoUrl;

  const FullscreenMediaViewer({Key? key, this.imageUrl, this.videoUrl}) : super(key: key);

  @override
  State<FullscreenMediaViewer> createState() => _FullscreenMediaViewerState();
}

class _FullscreenMediaViewerState extends State<FullscreenMediaViewer> {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _videoController = VideoPlayerController.network(widget.videoUrl!)
        ..initialize().then((_) {
          setState(() {
            _videoInitialized = true;
            _videoController?.play();
          });
        });
      _videoController?.setLooping(true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? InteractiveViewer(
                      child: Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stack) => const Center(child: Icon(Icons.broken_image, color: Colors.white)),
                      ),
                    )
                  : (widget.videoUrl != null && widget.videoUrl!.isNotEmpty)
                      ? _videoInitialized
                          ? Center(
                              child: AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator())
                      : const Center(child: Icon(Icons.broken_image, color: Colors.white)),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            if (_videoController != null && _videoInitialized)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_videoController!.value.isPlaying) {
                            _videoController!.pause();
                          } else {
                            _videoController!.play();
                          }
                        });
                      },
                      icon: Icon(
                        _videoController!.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

