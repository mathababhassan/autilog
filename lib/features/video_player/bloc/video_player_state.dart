import 'package:chewie/chewie.dart';
import 'package:equatable/equatable.dart';
import 'package:video_player/video_player.dart';

abstract class VideoPlayerState extends Equatable {
  const VideoPlayerState();

  @override
  List<Object?> get props => [];
}

class VideoPlayerInitial extends VideoPlayerState {
  const VideoPlayerInitial();
}

class VideoPlayerLoading extends VideoPlayerState {
  const VideoPlayerLoading();
}

// Controllers are mutable — excluded from props intentionally.
class VideoPlayerReady extends VideoPlayerState {
  const VideoPlayerReady({
    required this.videoPlayerController,
    required this.chewieController,
  });

  final VideoPlayerController videoPlayerController;
  final ChewieController chewieController;
}

class VideoPlayerError extends VideoPlayerState {
  const VideoPlayerError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
