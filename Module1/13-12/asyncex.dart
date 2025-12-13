Future delayprint(int sec,String msg)
{
  final duration = Duration(seconds: sec);
  return Future.delayed(duration).then((value) => msg);
}

main()async
{
  print("Hello");
  await delayprint(10, "From").then((a){

    print(a);
  });
  print("Tops");

}