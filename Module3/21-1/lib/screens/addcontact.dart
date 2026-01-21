import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../color.dart';
import '../db/dbhelper.dart';
import '../widgets/mydrawer.dart';

class AddContact extends StatefulWidget
{
  const AddContact({super.key});

  @override
  State<AddContact> createState() => _AddContactState();
}

class _AddContactState extends State<AddContact>
{
  TextEditingController _firstName = TextEditingController();
  TextEditingController _lastName = TextEditingController();
  TextEditingController _mobile = TextEditingController();
  TextEditingController _email = TextEditingController();
  DbHelper dbHelper = DbHelper.instance;
  final formGlobalKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? imageFile;
  late Future<Uint8List> imageBytes;
  String currentCategory = "";
  List<String> allCategoryData = [];

  @override
  void initState() {
    // TODO: implement initState
    _query();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(

      drawer: MyDrawer(),
      resizeToAvoidBottomInset: true,
      body: ListView
        (
          children:
          [
          SizedBox
          (
              child: Padding
              (
              padding: EdgeInsets.all(20.0),
              child: Form
                (
                  key:formGlobalKey,
                  child: Column
                    (
                      children: [

                        SizedBox
                          (
                          height: 20,
                          ),
                          InkWell
                            (
                                    onTap:()async
                                    {
                                      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                                      if(pickedFile!=null)
                                      {
                                        imageBytes = pickedFile.readAsBytes();
                                        setState(()
                                        {
                                          imageFile = File(pickedFile.path);
                                        });
                                      }
                                      },
                              child: imageFile == null ?
                              CircleAvatar(
                                backgroundColor: MyColors.primaryColor,
                                minRadius: 50,
                                child: Icon(
                                  Icons.image,
                                  color: Colors.white,
                                ),
                              ):
                              CircleAvatar(
                                backgroundImage: Image.file(
                                  imageFile!,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                ).image,
                                minRadius: 100,
                              ),),
                        SizedBox
                          (
                          height: 20,
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.greenAccent, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: MyColors.primaryColor, width: 1.0),
                            ),
                            hintText: 'First Name',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                          ),
                          controller: _firstName,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter First Name';
                            }
                            return null;
                          },
                        ),

                        SizedBox
                          (
                          height: 20,
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.greenAccent, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: MyColors.primaryColor, width: 1.0),
                            ),
                            hintText: 'Last Name',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                          ),
                          controller: _lastName,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter Last Name';
                            }
                            return null;
                          },
                        ),


                        SizedBox
                          (
                          height: 20,
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.greenAccent, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: MyColors.primaryColor, width: 1.0),
                            ),
                            hintText: 'Enter Mobile Number',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                          ),
                          controller: _mobile,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter Mobile Number';
                            }
                            return null;
                          },
                        ),


                        SizedBox
                          (
                          height: 20,
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.greenAccent, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: MyColors.primaryColor, width: 1.0),
                            ),
                            hintText: 'Enter Email',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                          ),
                          controller: _email,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter Email';
                            }
                            return null;
                          },
                        ),
                        SizedBox
                          (
                          height: 20,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MyColors.primaryColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              items: allCategoryData
                                  .map((String value)
                              {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (selectedItem) => setState(()
                              {
                                currentCategory = selectedItem!;
                              }),
                              hint: Text("Select Category "),
                              value: currentCategory.isEmpty ? null : currentCategory,
                            ),
                          ),
                        ),

                        TextButtonTheme(
                          data: TextButtonThemeData(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  MyColors.primaryColor),
                            ),
                          ),
                          child: TextButton(
                            onPressed: () {
                              if (formGlobalKey.currentState!.validate())
                              {
                                print("aaa");
                                _insert();
                              }
                            },
                            child: const Text(
                              "Save",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )






                      ],
                    )

                ),

              ),




          )

          ],
        ),

    ));
  }
  void _query() async
  {
    final allRows = await dbHelper.queryAllRows();
    if (kDebugMode)
    {
      print('query all rows:');
    }
    for (var element in allRows)
    {
      allCategoryData.add(element["category_name"]);

    }
    setState(() {});
  }

  void _insert() async
  {
    var base64image;

    if(imageFile!.exists()!=null)
    {
      base64image = base64Encode(imageFile!.readAsBytesSync().toList());
    }

    Map<String,dynamic> row =
    {
      DbHelper.columnName : _firstName.text.toString(),
      DbHelper.columnLName : _lastName.text.toString(),
      DbHelper.columnMobile : _mobile.text.toString(),
      DbHelper.columnEmail : _email.text.toString(),
      DbHelper.columnCategory : currentCategory,
      DbHelper.columnProfile :  base64image,

    };
    print('insert stRT');
    currentCategory="";

    final id = await dbHelper.insertcontact(row);
    if (kDebugMode)
    {
      print('inserted row id: $id');
    }
    _query();

  }
}
