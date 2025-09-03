class Assessment {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final List<String> assignedTo;
  final List<Question> questions;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;
  final AssessmentType type;
  final String? domain;
  final String? difficulty;
  final int totalMarks;
  final int duration;

  const Assessment({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.assignedTo,
    required this.questions,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.type,
    this.domain,
    this.difficulty,
    required this.totalMarks,
    required this.duration,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['createdBy'] ?? '',
      assignedTo: json['assignedTo'] != null ? List<String>.from(json['assignedTo']) : [],
      questions: json['questions'] != null 
          ? (json['questions'] as List).map((q) => Question.fromJson(q)).toList()
          : [],
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(json['endTime'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      type: AssessmentType.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['type'] ?? 'AI_GENERATED').toString().toUpperCase(),
        orElse: () => AssessmentType.AI_GENERATED,
      ),
      domain: json['domain'],
      difficulty: json['difficulty'],
      totalMarks: json['totalMarks'] ?? 0,
      duration: json['duration'] ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'questions': questions.map((q) => q.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'type': type.name.toUpperCase(),
      'domain': domain,
      'difficulty': difficulty,
      'totalMarks': totalMarks,
      'duration': duration,
    };
  }
}

class Question {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  const Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] ?? '',
      options: json['options'] != null ? List<String>.from(json['options']) : [],
      correctAnswer: json['correctAnswer'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }
}

enum AssessmentType {
  AI_GENERATED,
  CLASS_ASSESSMENT,
}

extension AssessmentTypeExtension on AssessmentType {
  String get displayName {
    switch (this) {
      case AssessmentType.AI_GENERATED:
        return 'AI Generated';
      case AssessmentType.CLASS_ASSESSMENT:
        return 'Class Assessment';
    }
  }
}