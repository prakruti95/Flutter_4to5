import 'package:db2/db/dbhelper.dart';
import 'package:db2/widgets/mydrawer.dart';
import 'package:flutter/material.dart';

import '../color.dart';

class HomePage extends StatefulWidget
{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
{
  final formGlobalKey = GlobalKey<FormState>();
  TextEditingController _categoryName = TextEditingController();
  DbHelper dbHelper = DbHelper.instance;
  @override
  Widget build(BuildContext context)
  {
    return SafeArea
      (
        child: Scaffold
          (
          appBar: AppBar
            (
            backgroundColor: MyColors.primaryColor,
            centerTitle: true,
            title: Text("create and store category"),
          ),
          body: Form
            (
            key: formGlobalKey,
            child: Column
              (
              children:
              [
                Expanded
                  (
                    child:Padding
                      (
                      padding: EdgeInsets.all(20.00),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children:
                        [
                          const SizedBox
                            (
                            height: 50,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 250,
                                child: TextFormField
                                  (
                                  decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder
                                      (
                                      borderSide: BorderSide
                                        (
                                          color: Colors.greenAccent,
                                          width: 2.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyColors.primaryColor, width: 1.0),
                                    ),
                                    hintText: 'Add Category',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                  ),
                                  controller: _categoryName,
                                  validator: (value)
                                  {
                                    if (value == null || value.isEmpty)
                                    {
                                      return 'Enter category name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 50,
                          ),
                          TextButtonTheme
                            (
                            data: TextButtonThemeData(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all<Color>(
                                    MyColors.primaryColor),
                              ),
                            ),
                            child: TextButton(
                              onPressed: ()
                              {
                                if (formGlobalKey.currentState!.validate())
                                {
                                  _insert();
                                }
                              },
                              child: const Text(
                                "Save",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                        ],
                      ),

                    )




                )
              ],
            ),

          ),
        
          drawer:MyDrawer()
          )
      );
  }

  void _insert()
  {
    Map<String, dynamic> row =  {DbHelper.columnname:_categoryName.text.toString()};
    dbHelper.insertdata(row);
    print("Inserted");
    _categoryName.clear();
  }
}
