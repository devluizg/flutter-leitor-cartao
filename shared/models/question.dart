class Question {
  final int number;
  final String correctAnswer;
  String? userAnswer;

  Question({
    required this.number,
    required this.correctAnswer,
    this.userAnswer,
  });

  bool get isCorrect => userAnswer == correctAnswer;

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      number: json['number'],
      correctAnswer: json['correctAnswer'],
      userAnswer: json['userAnswer'],
    );
  }
}
