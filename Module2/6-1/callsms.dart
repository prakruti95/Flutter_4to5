import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallSms extends StatefulWidget
{
  const CallSms({super.key});

  @override
  State<CallSms> createState() => _CallSmsState();
}

class _CallSmsState extends State<CallSms>
{
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(),
        body: Center
          (
            child: Column
              (
                children:
                [


                    ElevatedButton(onPressed: ()
                    {
                        callme("8734031718");
                    }, child: Text("CALL")),
                    ElevatedButton(onPressed: ()
                    {
                      smsme("8734031718","Hii From Flutter Batch");
                    }, child: Text("SMS")),
                ],
            ),
          ),
      );
  }

  void callme(String num) async
  {
    final Uri myuri = Uri(
      scheme: 'tel',
      path: num,
    );

    await launchUrl(myuri);
  }

  void smsme(String phoneNumber, String messageBody)async
  {
    final Uri myuri = Uri(
      scheme: 'sms',
      path: phoneNumber,
        queryParameters: {
          'body': messageBody,
        }
    );

    await launchUrl(myuri);
  }
}
