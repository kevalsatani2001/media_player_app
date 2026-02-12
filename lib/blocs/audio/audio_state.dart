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

  AudioLoaded({
    required this.entities,
    required this.path,
    required this.page,
    required this.totalCount,
    required this.hasMore,
  });

  AudioLoaded copyWith({
    List<AssetEntity>? entities,
    AssetPathEntity? path,
    int? page,
    int? totalCount,
    bool? hasMore,
  }) {
    return AudioLoaded(
      entities: entities ?? this.entities,
      path: path ?? this.path,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}


class AudioError extends AudioState {
  final String message;
  const AudioError(this.message);
}