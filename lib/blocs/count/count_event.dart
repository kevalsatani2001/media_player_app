abstract class HomeCountEvent {}

class LoadCounts extends HomeCountEvent {}

class RefreshCounts extends HomeCountEvent {}
class RefreshCountsWithData extends HomeCountEvent {
  final int vCount;
  final int aCount;

  RefreshCountsWithData(this.vCount, this.aCount);
}