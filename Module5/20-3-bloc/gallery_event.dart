abstract class GalleryEvent {}

class ToggleFavorite extends GalleryEvent
{
  final int imageId;
  ToggleFavorite(this.imageId);
}
class ShowFavorites extends GalleryEvent {}
class ShowAll extends GalleryEvent {}