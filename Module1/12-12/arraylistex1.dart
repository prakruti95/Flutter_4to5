void main()
{
  List list = [1,2,3,"a","b","c"];
  List list2 = [4,7,6];

  list.add(5);
  list.addAll(list2);
  list.remove(4);
  list.removeAt(4);
  list.elementAt(4);
  //print(list);
  //print(list[3]);

  for(int i=0;i<list.length;i++)
  {
      print(list[i]);
  }

  // for(int i=0;i<list2.length;i++)
  // {
  //   print(list2[i]);
  // }
}