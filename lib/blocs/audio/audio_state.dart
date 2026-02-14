part of 'audio_bloc.dart';

abstract class AudioState {
  const AudioState();
}

class AudioInitial extends AudioState {}

class AudioLoading extends AudioState {}

class AudioLoaded extends AudioState {
  final List<AssetEntity> entities;
  final AssetPathEntity path;
  final int page;
  final int totalCount;
  final bool hasMore;
  final bool isLoadingMore;

  AudioLoaded({
    required this.entities,
    required this.path,
    required this.page,
    required this.totalCount,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  AudioLoaded copyWith({
    List<AssetEntity>? entities,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return AudioLoaded(
      entities: entities ?? this.entities,
      path: path,
      page: page ?? this.page,
      totalCount: totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}


class AudioError extends AudioState {
  final String message;
  const AudioError(this.message);
}

class LoadMoreAudios extends AudioEvent {}
