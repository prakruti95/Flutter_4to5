class GalleryModel
{
  final int id;
  final String path;
  final bool isFavorite;

  GalleryModel({required this.id,required this.path,this.isFavorite=false});

  GalleryModel copyWith({int? id, String? path, bool? isFavorite})
  {
    return GalleryModel
      (
        id : id ?? this.id,
        path : path ?? this.path,
       isFavorite : isFavorite ?? this.isFavorite,

      );
  }

}