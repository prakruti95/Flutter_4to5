
import 'dart:io';

void main()
{
    try
    {
      File f = File("D://xyz.txt");
      f.writeAsString("Hello From Tops");
     // f.wr
    }
    catch(e)
    {
      print(e);
    }
    finally
    {
      print("Executed");
    }





}