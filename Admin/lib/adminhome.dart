
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../../../constants.dart';
import 'adminfront.dart';



class AdminHome extends StatefulWidget
{
  @override
  State<StatefulWidget> createState() {
    return AdminHomePage();
  }
}

class AdminHomePage extends State<AdminHome>
{
  Future<List> viewCategoryData() async
  {
    final responce = await http.get(Uri.parse("https://prakrutitech.xyz/FlutterProject/category_view.php"));
    return jsonDecode(responce.body);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async
      {
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (a, b, c) => AdminFront(),transitionDuration: Duration(seconds: 3)));

      },
      child: Scaffold(
        backgroundColor: kLightGold,
        body: FutureBuilder<List>(
          future: viewCategoryData(),
          builder: (ctx,ss) {
            if(ss.hasData){
              return Items(list:ss.data!!);
            }
            else{
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}

class Items extends StatefulWidget {
  List list;
  Items({required this.list});

  @override
  State<StatefulWidget> createState() {
    return _Items(list_: list);
  }
}

class _Items extends State<Items>{
  _Items({required this.list_});

  List list_;


  var size;

  var update_category = TextEditingController();

  //PickedFile _imageFile;
  //final String uploadUrl = "https://amisha1299.000webhostapp.com/Ewishes/upload_category_main_image_update.php";
  //final ImagePicker _picker = ImagePicker();


  void deleteCategory(var id)
  {
    var url = "https://prakrutitech.xyz/FlutterProject/category_delete.php";
    http.post(Uri.parse(url),body: {
      'data': id,
    });
  }

  void deleteCategoryImages(var id)
  {
    var url = "https://prakrutitech.xyz/Project_API/category_images_delete.php";
    http.post(Uri.parse(url),body: {
      'data': id,
    });
  }
  //
  void updateCategoryName(var id)
  {
    var url = "https://prakrutitech.xyz/Project_API/category_update.php";
    http.post(Uri.parse(url),body: {
      'id': id,
      'category_name': update_category.text.toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    return ListView.builder(
      itemCount: list_.length,
      itemBuilder: (BuildContext context,int index){
        return Card(
          color: kGold,
          shadowColor: kBrown,
          elevation: 3,
          child: ListTile(
            onTap: ()
            {
              //Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context)=>AdminCategory(index: list_[index]['id'],category_name: list_[index]['category_name'])));
            },
            leading: Icon(Icons.list,color: kBrown,),
            trailing: InkWell(
              onTap: (){
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: kWhite,
                    title: Row(children: [Icon(Icons.delete, color: kBrown,),Text("\tDelete", style: TextStyle(color: kBrown),)],),
                    content: Text("This items will be permanently deleted.",style: TextStyle(color: kTerracotta ,fontStyle: FontStyle.italic)),
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        child: Text("Cancel",style: TextStyle(color: kBrown)),
                      ),
                      ElevatedButton(
                        onPressed: ()
                        {
                          deleteCategoryImages(list_[index]['id']);
                          deleteCategory(list_[index]['id']);
                          //Navigator.pop(context);
                          //Navigator.of(ctx).pop();
                         // Navigator.of(context).pop();

                          Fluttertoast.showToast(msg: "Category Deleted Successfully",toastLength: Toast.LENGTH_LONG,timeInSecForIosWeb: 1);
                          Navigator.push(context,MaterialPageRoute(builder: (context) => AdminHome()));

                        },
                        child: Text("Delete",style: TextStyle(color: kBrown)),
                      ),
                    ],
                  ),
                );
              },
              child: Icon(Icons.delete,size: 25, color: kBrown,),
            ),
            title: Row(
              children: [
                SizedBox(
                  width: size.width*55/100,
                  child: Text("${list_[index]['category_name']}".toUpperCase(),style: TextStyle(color: kDarkBrown ,fontStyle: FontStyle.italic,fontSize: 15)),
                ),
                InkWell(
                  onTap: (){
                    update_category.text = list_[index]['category_name'];
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: kWhite,
                        title: Row(children: [Icon(Icons.update, color: kBrown,),Text("\tUpdate Category",style: TextStyle(color: kBrown))],),
                        content: Container(
                          height: size.height*14/100,
                          child: Column(
                            children: [
                              TextField(
                                controller: update_category,
                                decoration: InputDecoration(
                                  hintText: "Input Category Name",
                                ),
                              ),
                              SizedBox(height: size.height*1/100),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: double.infinity,
                                ),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: kBrown,
                                    padding: const EdgeInsets.all(kPaddingM),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                  ),
                                  onPressed: () {
                                    //_pickImage(list_[index]['id']);
                                  },
                                  child: Text("Update Image".toUpperCase(),
                                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: kLightGold,fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                            child: Text("Cancel",style: TextStyle(color: kBrown)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if(!update_category.text.isEmpty){
                                updateCategoryName(list_[index]['id']);
                                Fluttertoast.showToast(msg: "Category Updated Successfully",toastLength: Toast.LENGTH_LONG,timeInSecForIosWeb: 1);
                                Navigator.of(ctx).pop();
                                //Navigator.of(context).pop();
                              }
                              else{
                                if(update_category.text.isEmpty){
                                  Fluttertoast.showToast(msg: "Please Input Category Name",toastLength: Toast.LENGTH_LONG,timeInSecForIosWeb: 1);
                                }
                              }
                            },
                            child: Text("Update",style: TextStyle(color: kBrown)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Icon(Icons.edit,size: 25,color: kBrown),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}