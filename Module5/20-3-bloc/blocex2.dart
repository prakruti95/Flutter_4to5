import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'galery2.dart';
import 'gallery_bloc.dart';

class GalleryPage extends StatefulWidget
{
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
{
  @override
  Widget build(BuildContext context)
  {
    return MaterialApp(home: BlocProvider(create:  (_) => GalleryBloc(), child: GalleryPage2(),),debugShowCheckedModeBanner: false,);
  }
}
