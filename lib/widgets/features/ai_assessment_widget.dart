import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../models/assessment.dart';

class AIAssessmentWidget extends StatefulWidget {
  const AIAssessmentWidget({super.key});

  @override
  State<AIAssessmentWidget> createState() => _AIAssessmentWidgetState();
}

class _AIAssessmentWidgetState extends State<AIAssessmentWidget> {
  Assessment? _assessment;
  bool _isLoading = false;
  bool _isActive = false;
  int _currentQuestion = 0;
  List<int> _answers = [];
  int _timeLeft = 0;
  bool _showResults = false;
  Map<String, dynamic>? _results;
  DateTime? _startedAt;

  String _selectedDomain = '';
  String _selectedDifficulty = '';
  int _numberOfQuestions = 5;

  final List<String> _domains = [
    'Computer Science',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History',
    'Geography',
  ];

  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  Future<void> _generateAssessment() async {
    if (_selectedDomain.isEmpty || _selectedDifficulty.isEmpty) {
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Please select domain and difficulty', ToastType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.generateAIAssessment({
        'domain': _selectedDomain,
        'difficulty': _selectedDifficulty,
        'numberOfQuestions': _numberOfQuestions,
      });

      final assessment = Assessment.fromJson(response);
      setState(() {
        _assessment = assessment;
        _answers = List.filled(assessment.questions.length, -1);
        _currentQuestion = 0;
        _showResults = false;
        _results = null;
      });

      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Assessment generated successfully!', ToastType.success);
    } catch (e) {
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Failed to generate assessment', ToastType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startAssessment() {
    if (_assessment == null) return;

    setState(() {
      _isActive = true;
      _timeLeft = _assessment!.duration * 60;
      _startedAt = DateTime.now();
    });

    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isActive && _timeLeft > 0) {
        setState(() => _timeLeft--);
        _startTimer();
      } else if (_timeLeft <= 0) {
        _submitAssessment();
      }
    });
  }

  Future<void> _submitAssessment() async {
    if (_assessment == null) return;

    setState(() => _isActive = false);

    // Calculate results locally
    int score = 0;
    final feedback = <Map<String, dynamic>>[];

    for (int i = 0; i < _answers.length; i++) {
      final question = _assessment!.questions[i];
      final isCorrect = _answers[i] == question.correctAnswer;
      if (isCorrect) score++;

      feedback.add({
        'questionIndex': i,
        'question': question.question,
        'selectedOption': _answers[i] >= 0 ? question.options[_answers[i]] : 'Not answered',
        'correctOption': question.options[question.correctAnswer],
        'explanation': question.explanation,
        'isCorrect': isCorrect,
      });
    }

    final percentage = (score / _assessment!.questions.length) * 100;

    setState(() {
      _results = {
        'score': score,
        'totalMarks': _assessment!.questions.length,
        'percentage': percentage,
        'feedback': feedback,
      };
      _showResults = true;
    });

    // Log activity
    await ApiService.logActivity('AI_ASSESSMENT', 'Completed AI assessment - Score: $score/${_assessment!.questions.length}');

    final toastProvider = Provider.of<ToastProvider>(context, listen: false);
    toastProvider.showToast('Assessment completed! Score: $score/${_assessment!.questions.length}', ToastType.success);
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.brain, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'AI Assessment Generator',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Domain Selection
            DropdownButtonFormField<String>(
              value: _selectedDomain.isEmpty ? null : _selectedDomain,
              decoration: const InputDecoration(
                labelText: 'Domain',
                prefixIcon: Icon(LucideIcons.bookOpen),
              ),
              items: _domains.map((domain) => 
                DropdownMenuItem(value: domain, child: Text(domain))
              ).toList(),
              onChanged: (value) => setState(() => _selectedDomain = value ?? ''),
            ),
            const SizedBox(height: 16),
            
            // Difficulty Selection
            DropdownButtonFormField<String>(
              value: _selectedDifficulty.isEmpty ? null : _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                prefixIcon: Icon(LucideIcons.target),
              ),
              items: _difficulties.map((difficulty) => 
                DropdownMenuItem(value: difficulty, child: Text(difficulty))
              ).toList(),
              onChanged: (value) => setState(() => _selectedDifficulty = value ?? ''),
            ),
            const SizedBox(height: 16),
            
            // Number of Questions
            DropdownButtonFormField<int>(
              value: _numberOfQuestions,
              decoration: const InputDecoration(
                labelText: 'Number of Questions',
                prefixIcon: Icon(LucideIcons.hash),
              ),
              items: [5, 10, 15, 20].map((num) => 
                DropdownMenuItem(value: num, child: Text('$num Questions'))
              ).toList(),
              onChanged: (value) => setState(() => _numberOfQuestions = value ?? 5),
            ),
            const SizedBox(height: 24),
            
            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateAssessment,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Icon(LucideIcons.brain),
                label: Text(_isLoading ? 'Generating...' : 'Generate Assessment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentPreview() {
    if (_assessment == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _assessment!.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _assessment!.difficulty ?? 'Medium',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Text(
              _assessment!.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '${_assessment!.questions.length}',
                    'Questions',
                    LucideIcons.helpCircle,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '${_assessment!.duration} min',
                    'Duration',
                    LucideIcons.clock,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '${_assessment!.totalMarks}',
                    'Total Marks',
                    LucideIcons.award,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startAssessment,
                icon: const Icon(LucideIcons.play),
                label: const Text('Start Assessment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAssessment() {
    if (_assessment == null || !_isActive) return const SizedBox.shrink();

    final currentQuestion = _assessment!.questions[_currentQuestion];

    return Column(
      children: [
        // Timer and Progress
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.clock, color: AppTheme.errorColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Time Left: ${_formatTime(_timeLeft)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Question ${_currentQuestion + 1} of ${_assessment!.questions.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_currentQuestion + 1) / _assessment!.questions.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Question Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentQuestion.question,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Options
                ...currentQuestion.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = _answers[_currentQuestion] == index;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _answers[_currentQuestion] = index;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: isSelected
                                  ? const Icon(LucideIcons.check, color: Colors.white, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${String.fromCharCode(65 + index)}.',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 24),
                
                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: _currentQuestion > 0 
                          ? () => setState(() => _currentQuestion--)
                          : null,
                      child: const Text('Previous'),
                    ),
                    
                    ElevatedButton(
                      onPressed: () {
                        if (_currentQuestion == _assessment!.questions.length - 1) {
                          _submitAssessment();
                        } else {
                          setState(() => _currentQuestion++);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentQuestion == _assessment!.questions.length - 1
                            ? AppTheme.successColor
                            : AppTheme.primaryColor,
                      ),
                      child: Text(
                        _currentQuestion == _assessment!.questions.length - 1
                            ? 'Submit Assessment'
                            : 'Next',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (!_showResults || _results == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assessment Results',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Results Summary
            Row(
              children: [
                Expanded(
                  child: _buildResultCard(
                    '${_results!['score']}',
                    'Correct Answers',
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResultCard(
                    '${_results!['totalMarks']}',
                    'Total Questions',
                    AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResultCard(
                    '${_results!['percentage'].toStringAsFixed(1)}%',
                    'Percentage',
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Detailed Feedback
            Text(
              'Detailed Feedback',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            ...(_results!['feedback'] as List).asMap().entries.map((entry) {
              final index = entry.key;
              final feedback = entry.value;
              final isCorrect = feedback['isCorrect'];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? LucideIcons.checkCircle : LucideIcons.xCircle,
                            color: isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Question ${index + 1}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        feedback['question'],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Answer:',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.errorColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  feedback['selectedOption'],
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Correct Answer:',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  feedback['correctOption'],
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explanation:',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              feedback['explanation'],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // Take Another Assessment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _assessment = null;
                    _showResults = false;
                    _results = null;
                    _isActive = false;
                  });
                },
                child: const Text('Take Another Assessment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return SingleChildScrollView(child: _buildResults());
    }

    if (_isActive) {
      return SingleChildScrollView(child: _buildActiveAssessment());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildConfigurationCard(),
          if (_assessment != null) ...[
            const SizedBox(height: 16),
            _buildAssessmentPreview(),
          ],
        ],
      ),
    );
  }
}