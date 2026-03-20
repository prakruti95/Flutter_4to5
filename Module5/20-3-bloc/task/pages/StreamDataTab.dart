import 'package:flutter/material.dart';
import '../bloc/just_data_bloc.dart';
import '../ui_component/imageCard.dart';


class StramDataTab extends StatefulWidget
{
  const StramDataTab({super.key});

  @override
  State<StramDataTab> createState() => _StramDataTabState();
}

class _StramDataTabState extends State<StramDataTab>
{
  @override
  Widget build(BuildContext context)
  {
    return Container
      (
      padding: EdgeInsets.symmetric(horizontal: 45),
      child: Column
        (
        children:
        [
          SizedBox(height: 10),
          Expanded(child: Stack
            (
            alignment: Alignment.center,
            children:
            [
              imageCard('assets/a.png'),
              Column
                (
                children:
                [
                  Text(
                    'Hi!\nMy Name is..\nWhat?\nMy Name is..\nWho?\nMy Name is..',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15),
                  StreamBuilder(
                    initialData: '...',
                    stream: justDataBloc.streamJustData,
                    builder: (BuildContext context, AsyncSnapshot snapshot)
                    {
                      return Text(
                        snapshot.data,//get data here
                        style: TextStyle
                          (
                          fontWeight: FontWeight.bold,
                          fontSize: 38,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          ),
          SizedBox(height: 30),
          Row(
            //Row of Buttons
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  //Feeds data into JustDataBloc
                  onPressed: ()
                  {
                    justDataBloc.feedJustData('Slim Shady');
                  },
                  child: Text(
                    'Tell Them',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  // elevation: 0,
                ),
              ),
              SizedBox(width: 15),
              InkWell(
                //Reset Button
                //Feeds data into JustDataBloc
                onTap: () {
                  setState(() {
                    justDataBloc.feedJustData('...');
                    justDataBloc.feedJustData('...');
                  });
                },
                child: Container(
                  child: Icon(
                    Icons.loop,
                    size: 25,
                    color: Colors.white,
                  ),
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}