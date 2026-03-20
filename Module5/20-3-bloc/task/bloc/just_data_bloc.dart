import 'dart:async';

class JustDataBloc
{
  var _justDataController = StreamController<String>.broadcast();

  Function(String) get feedJustData => _justDataController.sink.add;

  Stream<String> get streamJustData => _justDataController.stream;

  dispose()
  {
    _justDataController?.close();
  }


}
JustDataBloc justDataBloc = JustDataBloc();