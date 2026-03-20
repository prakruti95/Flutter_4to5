import 'package:flutter_bloc/flutter_bloc.dart';

import 'gallery_event.dart';
import 'gallery_state.dart';
import 'imagemodel.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState>
{
  GalleryBloc(): super(GalleryState(allImages:
  [
  GalleryModel(id: 1, path: 'assets/images/alphabets.png'),
  GalleryModel(id: 1, path: 'assets/images/apple.png'),
  GalleryModel(id: 3, path: 'assets/images/ball.png'),

  ]))

  {

    on<ToggleFavorite>((event, emit) {
      final updated = state.allImages.map((img) {
        if (img.id == event.imageId) {
          return img.copyWith(isFavorite: !img.isFavorite);
        }
        return img;
      }).toList();
      emit(GalleryState(
        allImages: updated,
        showFavoritesOnly: state.showFavoritesOnly,
      ));
    });
    on<ShowFavorites>((event, emit)
    {
      emit(GalleryState(allImages: state.allImages, showFavoritesOnly: true));
    });
    on<ShowAll>((event, emit) {
      emit(GalleryState(allImages: state.allImages, showFavoritesOnly: false));
    });
  }


}