import 'dart:collection';


void main()
{

  final tech = {"a": 'Java', "c": 'Php', "b":'Python'};
  final Map<String, String> map = HashMap();
  map.addEntries(tech.entries);
  print(map);
}