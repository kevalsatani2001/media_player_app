abstract class HomeTabEvent {}

class SelectTab extends HomeTabEvent {
  final int index; // 0 = Video, 1 = Folder

  SelectTab(this.index);
}
