void main()
{
  Set set = Set();
  Set set2 = Set();

  set.add(1);
  set.add("a");
  set.add(2);
  set.add("b");
  set.add(1);
  set2.add(10);
  set2.add("a");
  //set.addAll(set2);
  //set.remove(10);
  //set.removeAll(set2);

  set.retainAll(set2);

  print(set);


  // for(int i=0;i<set.length;i++)
  // {
  //   print(]);
  // }

  // for(int i=0;i<list2.length;i++)
  // {
  //   print(list2[i]);
  // }
}