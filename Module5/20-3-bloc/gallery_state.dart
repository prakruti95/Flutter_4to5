import 'imagemodel.dart';

class GalleryState
{
  final List<GalleryModel> allImages;
  final bool showFavoritesOnly;

  GalleryState({
    required this.allImages,
    this.showFavoritesOnly = false,
  });

  List<GalleryModel> get displayedImages => showFavoritesOnly
      ? allImages.where((img) => img.isFavorite).toList()
      : allImages;
}