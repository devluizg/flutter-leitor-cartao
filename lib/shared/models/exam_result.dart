import 'question.dart';

class ExamResult {
  final List<Question> questions;
  final DateTime date;
  final double score;
  final int totalQuestions;
  final int correctAnswers;
  final List<int> wrongAnswers;
  final List<bool> correctnessMap;
  final List<String> improvementSuggestions;

  ExamResult({
    required this.questions,
    required this.date,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.correctnessMap,
    required this.improvementSuggestions,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      questions:
          (json['questions'] as List).map((q) => Question.fromJson(q)).toList(),
      date: DateTime.parse(json['date']),
      score: json['score'],
      totalQuestions: json['totalQuestions'],
      correctAnswers: json['correctAnswers'],
      wrongAnswers: List<int>.from(json['wrongAnswers']),
      correctnessMap: List<bool>.from(json['correctnessMap']),
      improvementSuggestions: List<String>.from(json['improvementSuggestions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questions': questions.map((q) => q.toJson()).toList(),
      'date': date.toIso8601String(),
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'correctnessMap': correctnessMap,
      'improvementSuggestions': improvementSuggestions,
    };
  }

  String get formattedScore {
    return '${score.toStringAsFixed(2)}%';
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  int get wrongAnswersCount {
    return wrongAnswers.length;
  }

  double get percentageCorrect {
    return (correctAnswers / totalQuestions) * 100;
  }
}
