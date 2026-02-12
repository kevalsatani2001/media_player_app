import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../models/media_item.dart';
import 'media_event.dart';
import 'media_state.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  MediaBloc() : super(const MediaState([])) {
    on<LoadMedia>(_onLoadMedia);
  }

  void _onLoadMedia(LoadMedia event, Emitter<MediaState> emit) async {
    final box = Hive.box(
      event.type == 'video' ? 'videos' : 'audios',
    );

    final items = box.values
        .map(
          (e) => MediaItem.fromMap(
        Map<String, dynamic>.from(e),
      ),
    )
        .toList();

    emit(MediaState(items));
  }
}
