// part of 'video_bloc.dart';
//
// abstract class VideoEvent{}
//
// class LoadVideosFromGallery extends VideoEvent {
//   bool? showLoading;
//   LoadVideosFromGallery({this.showLoading = true});
// }
//
// class PickVideos extends VideoEvent {
//   final Future<List<String>?> Function() filePicker;
//   PickVideos(this.filePicker);
// }
//
// class LoadMoreVideos extends VideoEvent {}

// part of 'video_bloc.dart';

abstract class VideoEvent{}

class LoadVideosFromGallery extends VideoEvent {
  final bool showLoading;
  final bool isRefresh;

  LoadVideosFromGallery({
    this.showLoading = true,
    this.isRefresh = false,
  });
}


class PickVideos extends VideoEvent {
  final Future<List<String>?> Function() filePicker;
  PickVideos(this.filePicker);
}

class LoadMoreVideos extends VideoEvent {}

class RefreshCounts extends VideoEvent {}