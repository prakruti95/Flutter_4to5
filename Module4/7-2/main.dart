import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main()
{
  runApp(MaterialApp(home:UploadImage()));
}
class UploadImage extends StatefulWidget
{
  const UploadImage({super.key});

  @override
  State<UploadImage> createState() => _UploadImageState();
}

class _UploadImageState extends State<UploadImage>
{
  TextEditingController cname = TextEditingController();
  File _imageFile = File("");

  @override
  Widget build(BuildContext context)
  {


    return Scaffold
      (
        appBar: AppBar(title: Text("Upload Image"),),
        body: Center
          (
              child: Column
                (
                  children:
                  [

                    TextField
                      (
                      controller: cname,
                      decoration: InputDecoration(
                        labelText: 'Enter Category Name',
                      ),),
                    SizedBox(height: 10,),
                    ElevatedButton(onPressed: ()
                    {
                      _pickImage();

                    }, child: Text("Choose Image")),
                    SizedBox(height: 10,),
                    ElevatedButton(onPressed: ()
                    {
                      uploadimage();
                    }, child: Text("Upload Image")),



                  ],
                ),
          ),
      );
  }

  void _pickImage() async
  {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if(pickedFile!=null)
    {
      setState(()
      {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void uploadimage()async
  {
    try
    {
      var url = Uri.parse('https://prakrutitech.xyz/API/upload.php');

      var resp = http.MultipartRequest('POST', url)
        ..fields['category_name'] = cname.text.toString()
        ..files.add(await http.MultipartFile.fromPath('category_img', _imageFile.path));

  var response = await resp.send();
  if(response.statusCode==200)
    {
    print('Data uploaded successfully');
    }
    else
    {
    print('Failed to upload data. Error: ${response.statusCode}');
    }
    }
    catch(e)
    {
    print(e);
    }
  }
}

