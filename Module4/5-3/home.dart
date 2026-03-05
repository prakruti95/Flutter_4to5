import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:setupex1/add.dart';

class MyHomePage extends StatefulWidget
{
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final Stream<QuerySnapshot> studentRecords = FirebaseFirestore.instance.collection('Students').snapshots();
  CollectionReference delUser = FirebaseFirestore.instance.collection('Students');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder
      (
        stream: studentRecords,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasError) {
            print('Something Wrong in HomePage2');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center
              (
              child: CircularProgressIndicator(),
            );
          }
          else
            {
              final List firebaseData = [];
              snapshot.data?.docs.map((DocumentSnapshot documentSnapshot) {
                Map store = documentSnapshot.data() as Map<String, dynamic>;
                firebaseData.add(store);
                store['id'] = documentSnapshot.id;
              }).toList();

              return Scaffold
                (
                appBar: AppBar(actions:
                [
                  // ElevatedButton(onPressed: ()
                  // {
                  //   Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => Adddata()));
                  // }, child: Text("Add"))
                ],),
                body: Container
                  (
                  margin: const EdgeInsets.all(8),
                  child: SingleChildScrollView
                    (
                      child: Table
                        (
                        border: TableBorder.all(),
                        columnWidths: const <int, TableColumnWidth>
                        {
                          1: FixedColumnWidth(150),

                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children:
                        [
                          TableRow
                            (
                              children:
                              [
                                TableCell(
                                  child: Container(
                                    color: Colors.greenAccent,
                                    child: Center(
                                      child: Text(
                                        'Name',
                                        // style: txt,
                                      ),
                                    ),
                                  ),
                                ),

                                TableCell(
                                  child: Container(
                                    color: Colors.greenAccent,
                                    child: Center(
                                      child: Text(
                                        'Email',
                                        // style: txt,
                                      ),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Container(
                                    color: Colors.greenAccent,
                                    child: Center(
                                      child: Text(
                                        'Actions',
                                        // style: txt,
                                      ),
                                    ),
                                  ),
                                ),

                              ]),

                          for (var i = 0; i < firebaseData.length; i++) ...
                          [
                            TableRow
                              (
                                children: [


                                  TableCell(
                                    child: SizedBox(
                                      child: Center(
                                        child: Text(
                                          firebaseData[i]['Name'],
                                          // style: txt2,
                                        ),
                                      ),
                                    ),
                                  ),

                                  TableCell(
                                    child: SizedBox(
                                      child: Center(
                                        child: Text(
                                          firebaseData[i]['Email'],
                                          // style: txt2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: SizedBox(
                                      child: Center(
                                        child: Row(
                                          children:
                                          [
                                            IconButton(onPressed: ()
                                            {
                                              //Navigator.push(context,MaterialPageRoute(builder: (context) => EditPage(docID:firebaseData[i]['id'])));
                                            }, icon: Icon(Icons.edit)),
                                            IconButton(onPressed: ()
                                            {
                                              deletedata(firebaseData[i]['id']);
                                            }, icon:Icon(Icons.delete)),
                                          ],
                                          // style: txt2,
                                        ),
                                      ),
                                    ),
                                  ),

                                ]
                            )

                          ]

                        ],
                      )
                  ),
                ),
                floatingActionButton: FloatingActionButton(onPressed: ()
                {
                  Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => Adddata()));
                },child:Icon(Icons.add),),
              );



            }

        }
    );
  }

  Future<void> deletedata(id)
  {
    return delUser.doc(id).delete().
    then((value) => print("deleted"))
        .catchError((_) => print('Something Error In Deleted User'));
  }
}