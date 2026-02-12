part of 'favourite_bloc.dart';

abstract class FavouriteEvent {}

class LoadFavourite extends FavouriteEvent {}
class LoadMoreFavourites extends FavouriteEvent {}
class ToggleFavourite extends FavouriteEvent {
  final AssetEntity entity;
  final int index;

  ToggleFavourite(this.entity, this.index);
}
