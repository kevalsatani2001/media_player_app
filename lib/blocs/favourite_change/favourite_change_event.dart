import 'package:photo_manager/photo_manager.dart';

abstract class FavouriteChangeState {}

class FavouriteChangeInitial extends FavouriteChangeState {}

class FavouriteChanged extends FavouriteChangeState {
  final AssetEntity entity;

  FavouriteChanged({required this.entity});
}