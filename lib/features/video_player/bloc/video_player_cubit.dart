import 'package:chewie/chewie.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import 'video_player_state.dart';

class VideoPlayerCubit extends Cubit<VideoPlayerState> {
  VideoPlayerCubit() : super(const VideoPlayerInitial());

    Future<void> initialize(String videoUrl) async {
    emit(const VideoPlayerLoading());
    VideoPlayerController? videoController;
    ChewieController? chewieController;
    
    try {
      videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );
      await videoController.initialize();
      chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
      );
      emit(VideoPlayerReady(
        videoPlayerController: videoController,
        chewieController: chewieController,
      ));
    } catch (_) {
      // Clean up to prevent memory leak
      videoController?.dispose();
      chewieController?.dispose();
      emit(const VideoPlayerError(
        message: 'Could not load the video. Please check your connection and try again.',
      ));
    }
  }

  Future<void> retry(String videoUrl) async {
    if (state is VideoPlayerReady) {
      final ready = state as VideoPlayerReady;
      ready.chewieController.dispose();
      ready.videoPlayerController.dispose();
    }
    await initialize(videoUrl);
  }

  @override
  Future<void> close() {
    if (state is VideoPlayerReady) {
      final ready = state as VideoPlayerReady;
      ready.chewieController.dispose();
      ready.videoPlayerController.dispose();
    }
    return super.close();
  }
}
