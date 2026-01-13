import 'package:flutter/material.dart';
import 'package:quiz1/answer.dart';
import 'package:quiz1/questions.dart';
import 'package:quiz1/quiz.dart';
import 'package:quiz1/result.dart';

void main()
{
  runApp(MyApp());
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
{

  final _questions = const [
    {
      'questionText': 'Q1. Who created Flutter?',
      'answers': [
        {'text': 'Facebook', 'score': -2},
        {'text': 'Adobe', 'score': -2},
        {'text': 'Google', 'score': 10},
        {'text': 'Microsoft', 'score': -2},
      ],
    },
    {
      'questionText': 'Q2. What is Flutter?',
      'answers': [
        {'text': 'Android Development Kit', 'score': -2},
        {'text': 'IOS Development Kit', 'score': -2},
        {'text': 'Web Development Kit', 'score': -2},
        {
          'text':'SDK to build beautiful IOS, Android, Web & Desktop Native Apps',
          'score': 10
        },
      ],
    },
    {
      'questionText': ' Q3. Which programming language is used by Flutter',
      'answers': [
        {'text': 'Ruby', 'score': -2},
        {'text': 'Dart', 'score': 10},
        {'text': 'C++', 'score': -2},
        {'text': 'Kotlin', 'score': -2},
      ],
    },
    {
      'questionText': 'Q4. Who created Dart programming language?',
      'answers': [
        {'text': 'Lars Bak and Kasper Lund', 'score': 10},
        {'text': 'Brendan Eich', 'score': -2},
        {'text': 'Bjarne Stroustrup', 'score': -2},
        {'text': 'Jeremy Ashkenas', 'score': -2},
      ],
    },
    {
      'questionText':
      'Q5. Is Flutter for Web and Desktop available in stable version?',
      'answers': [
        {'text': 'Yes','score': -2,},
        {'text': 'No', 'score': 10},
      ],
    },
  ];
  var _questionIndex = 0;
  var _totalScore = 0;

  void _resetQuiz()
  {
    setState(() {
      _questionIndex = 0;
      _totalScore = 0;
    });
  }

  void _answerQuestion(int score) {

    if (_questionIndex < _questions.length)
    {
      setState(() {
        _totalScore += score;//0+10+10-2+10
        _questionIndex = _questionIndex + 1;
      });

      // ignore: avoid_print
      print(_questionIndex);
      if (_questionIndex < _questions.length) {

        // ignore: avoid_print
        print('We have more questions!');
      } else {

        // ignore: avoid_print
        print('No more questions!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp
      (
        debugShowCheckedModeBanner: false,
        home: Scaffold
          (
            appBar: AppBar(title: Text("Quiz App"),backgroundColor: Colors.blue,foregroundColor: Colors.white,),
            body: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Center(child: Column(children:
              [
                _questionIndex < _questions.length
                    ? Quiz(
                  answerQuestion: _answerQuestion,
                  questionIndex: _questionIndex,
                  questions: _questions,
                ) //Quiz
                    : Result(_totalScore, _resetQuiz),

              ],),),
            ),
          ),
      );
  }
}


