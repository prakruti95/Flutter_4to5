import 'package:flutter/material.dart';
import 'package:quiz1/questions.dart';
import 'package:quiz1/answer.dart';



class Quiz extends StatelessWidget {
  final List<Map<String, Object>> questions;
  final int questionIndex;
  final Function answerQuestion;

  const Quiz({
    Key? key,
    required this.questions,
    required this.answerQuestion,
    required this.questionIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Question(
          questions[questionIndex]['questionText'].toString(),
        ), //Question
        ...(questions[questionIndex]['answers'] as List<Map<String, Object>>)
            .map((answer) {
          return Answer(selectHandler: () => answerQuestion(answer['score']), answerText: answer['text'].toString());
        }).toList()
      ],
    ); //Column
  }
}