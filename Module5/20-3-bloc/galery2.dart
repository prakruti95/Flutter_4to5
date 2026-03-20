import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'gallery_bloc.dart';
import 'gallery_event.dart';
import 'gallery_state.dart';


class GalleryPage2 extends StatefulWidget
{
  const GalleryPage2({super.key});

  @override
  State<GalleryPage2> createState() => _GalleryPage2State();
}

class _GalleryPage2State extends State<GalleryPage2>
{
  @override
  Widget build(BuildContext context)
  {
    final galleryBloc = context.read<GalleryBloc>();
    
      return Scaffold
        (
          backgroundColor: Colors.black,
          appBar: AppBar
            (
            title: const Text('📸 Image Gallery'),
            backgroundColor: Colors.purpleAccent,
            actions:
            [
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () => galleryBloc.add(ShowFavorites()),
              ),
              IconButton(
                icon: const Icon(Icons.photo_library),
                onPressed: () => galleryBloc.add(ShowAll()),
              ),
            ],
          ),
        body: BlocBuilder<GalleryBloc, GalleryState>(builder: (context, state)
        {
          final images = state.displayedImages;

          if (images.isEmpty) {
            return const Center(
              child: Text('No images to display 😔'),
            );
          }

          return GridView.builder
            (
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
            itemBuilder: (context, index) {
              final img = images[index];
              return GestureDetector(
                onTap: () => galleryBloc.add(ToggleFavorite(img.id)),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        img.path,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        img.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: img.isFavorite ? Colors.red : Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              );
            },
            itemCount: images.length,

            );

        }),
        );
  }
}
