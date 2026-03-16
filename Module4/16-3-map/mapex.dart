import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapEx extends StatefulWidget
{
  const GoogleMapEx({super.key});

  @override
  State<GoogleMapEx> createState() => _GoogleMapExState();
}

class _GoogleMapExState extends State<GoogleMapEx>
{
  LatLng latLng = LatLng(22.290275, 70.775234);
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(title: Text("Google Map Example"),),
        body: GoogleMap(initialCameraPosition:CameraPosition(target: latLng,zoom: 20.00)),
      );
  }
}
