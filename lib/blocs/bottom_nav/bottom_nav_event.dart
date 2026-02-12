abstract class BottomNavEvent{}
class SelectBottomTab extends BottomNavEvent{
  final int index;
  SelectBottomTab(this.index);
}