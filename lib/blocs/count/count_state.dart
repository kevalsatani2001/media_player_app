class HomeCountState {
  final int videoCount;
  final int audioCount;
  final int favouriteCount;
  final int playlistCount;
  final int recentCount;

  HomeCountState({
    required this.videoCount,
    required this.audioCount,
    required this.favouriteCount,
    required this.playlistCount,
    required this.recentCount,
  });

  factory HomeCountState.initial() {
    return HomeCountState(
        videoCount: 0,
        audioCount: 0,
        favouriteCount: 0,
        playlistCount: 0,
        recentCount: 0
    );
  }
}