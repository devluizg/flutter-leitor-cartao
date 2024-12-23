class Question {
  final int number;
  final String correctAnswer;
  final String userAnswer;
  final bool isCorrect;

  Question({
    required this.number,
    required this.correctAnswer,
    required this.userAnswer,
    required this.isCorrect,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      number: json['number'],
      correctAnswer: json['correctAnswer'],
      userAnswer: json['userAnswer'],
      isCorrect: json['isCorrect'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
    };
  }

  String get formattedNumber {
    return 'Question $number';
  }

  String get resultText {
    return isCorrect ? 'Correct' : 'Incorrect';
  }

  String get explanationText {
    if (isCorrect) {
      return 'You answered correctly with $userAnswer.';
    } else {
      return 'Your answer $userAnswer is incorrect. The correct answer is $correctAnswer.';
    }
  }
}
