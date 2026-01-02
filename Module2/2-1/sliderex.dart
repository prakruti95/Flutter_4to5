import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class Sliderex extends StatefulWidget {
  const Sliderex({super.key});

  @override
  State<Sliderex> createState() => _SliderexState();
}

class _SliderexState extends State<Sliderex> {
  final List<String> imgList = [
    'https://images.unsplash.com/photo-1520342868574-5fa3804e551c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=6ff92caffcdd63681a35134a6770ed3b&auto=format&fit=crop&w=1951&q=80',
    'https://images.unsplash.com/photo-1522205408450-add114ad53fe?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=368f45b0888aeb0b7b08e3a1084d3ede&auto=format&fit=crop&w=1950&q=80',
    'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=94a1e718d89ca60a6337a6008341ca50&auto=format&fit=crop&w=1950&q=80',
    'https://images.unsplash.com/photo-1523205771623-e0faa4d2813d?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=89719a0d55dd05e2deae4120227e6efc&auto=format&fit=crop&w=1953&q=80',
    'https://images.unsplash.com/photo-1508704019882-f9cf40e475b4?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=8c6e5e3aba713b17aa1fe71ab4f0ae5b&auto=format&fit=crop&w=1352&q=80',
    'https://images.unsplash.com/photo-1519985176271-adb1088fa94c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=a0c8d632e977f94e5d312d9893258f59&auto=format&fit=crop&w=1355&q=80',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: 
      [
          IconButton(onPressed: (){}, icon: Icon(Icons.logout)),
        IconButton(onPressed: (){}, icon: Icon(Icons.logout))
      ],),
      body: Container(
        child: CarouselSlider(
          items:
              imgList
                  .map(
                    (item) => Container(
                      child: Center(
                        child: Image.network(
                          item,
                          fit: BoxFit.cover,
                          width: 1250,
                          height: 300,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          options: CarouselOptions
            (
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 2),




            ),
        ),
      ),
      drawer: Drawer
        (
          child: Container
            (
              child: ListView
                (
                    children: 
                    [
                        UserAccountsDrawerHeader(accountName:Text("Tops Tech"), accountEmail: Text("tops@gmail.com")),
                        ListTile(title: Text("Product1"),),
                      ListTile(title: Text("Product1"),),
                      ListTile(title: Text("Product1"),),
                      ListTile(title: Text("Product1"),),
                      ListTile(title: Text("Product1"),),
                      ListTile(title: Text("Logout"),),
                    ],
                ),
            ),
        ),
    );
  }
}
