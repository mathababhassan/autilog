import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../bloc/video_player_cubit.dart';
import '../../bloc/video_player_state.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = VideoPlayerCubit();
    _cubit.initialize(widget.videoUrl);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
                builder: (context, state) {
                  if (state is VideoPlayerLoading || state is VideoPlayerInitial) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.textWhite,
                        strokeWidth: 2,
                      ),
                    );
                  }
                  if (state is VideoPlayerReady) {
                    return Chewie(controller: state.chewieController);
                  }
                  if (state is VideoPlayerError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => _cubit.retry(widget.videoUrl),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Positioned(
                top: AppSpacing.lg,
                right: AppSpacing.lg,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textWhite,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.videocam_off_outlined,
            color: AppColors.textWhite,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textWhite),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl2),
          AppPrimaryButton(label: 'Try again', onPressed: onRetry),
        ],
      ),
    );
  }
}
