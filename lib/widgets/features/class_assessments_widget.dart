import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../models/assessment.dart';

class ClassAssessmentsWidget extends StatefulWidget {
  const ClassAssessmentsWidget({super.key});

  @override
  State<ClassAssessmentsWidget> createState() => _ClassAssessmentsWidgetState();
}

class _ClassAssessmentsWidgetState extends State<ClassAssessmentsWidget> {
  List<Assessment> _assessments = [];
  bool _isLoading = true;
  Assessment? _activeAssessment;
  int _currentQuestion = 0;
  List<int> _answers = [];
  int _timeLeft = 0;
  bool _isActive = false;
  DateTime? _startedAt;
  bool _showResults = false;
  Map<String, dynamic>? _results;
  bool _isSubmitting = false;
  Set<String> _submittedAssessments = {};

  @override
  void initState() {
    super.initState();
    _loadAssessments();
    _loadSubmissionStatus();
  }

  Future<void> _loadAssessments() async {
    try {
      final response = await ApiService.getStudentAssessments();
      setState(() {
        _assessments = response.map((json) => Assessment.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Failed to load assessments', ToastType.error);
    }
  }

  void _loadSubmissionStatus() {
    // Load from local storage or shared preferences
    // For now, using a simple set
    setState(() {
      _submittedAssessments = {};
    });
  }

  void _saveSubmissionStatus(String assessmentId) {
    setState(() {
      _submittedAssessments.add(assessmentId);
    });
  }

  void _startAssessment(Assessment assessment) {
    final now = DateTime.now();
    
    if (now.isBefore(assessment.startTime)) {
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Assessment has not started yet', ToastType.warning);
      return;
    }

    if (now.isAfter(assessment.endTime)) {
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Assessment has ended', ToastType.error);
      return;
    }

    if (_submittedAssessments.contains(assessment.id)) {
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('You have already submitted this assessment', ToastType.warning);
      return;
    }

    setState(() {
      _activeAssessment = assessment;
      _answers = List.filled(assessment.questions.length, -1);
      _currentQuestion = 0;
      _timeLeft = assessment.duration * 60;
      _isActive = true;
      _startedAt = now;
      _showResults = false;
      _results = null;
    });

    _startTimer();

    final toastProvider = Provider.of<ToastProvider>(context, listen: false);
    toastProvider.showToast('Assessment started! Good luck!', ToastType.info);
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
    if (_activeAssessment == null || _isSubmitting) return;

    setState(() {
      _isActive = false;
      _isSubmitting = true;
    });

    try {
      // Check for unanswered questions
      final unansweredCount = _answers.where((answer) => answer == -1).length;
      if (unansweredCount > 0) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unanswered Questions'),
            content: Text('You have $unansweredCount unanswered question(s). Do you want to submit anyway?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Submit'),
              ),
            ],
          ),
        );

        if (proceed != true) {
          setState(() {
            _isActive = true;
            _isSubmitting = false;
          });
          return;
        }
      }

      final submission = {
        'answers': _answers.asMap().entries.map((entry) => {
          'questionIndex': entry.key,
          'selectedAnswer': entry.value,
        }).toList(),
        'startedAt': _startedAt!.toIso8601String(),
      };

      final result = await ApiService.submitAssessment(_activeAssessment!.id, submission);
      
      setState(() {
        _results = result;
        _showResults = true;
      });

      _saveSubmissionStatus(_activeAssessment!.id);

      // Log activity
      await ApiService.logActivity('ASSESSMENT_COMPLETED', 'Completed assessment: ${_activeAssessment!.title}');

      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Assessment submitted successfully!', ToastType.success);

      setState(() {
        _activeAssessment = null;
        _isActive = false;
      });
    } catch (e) {
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Failed to submit assessment', ToastType.error);
      
      setState(() => _isActive = true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getAssessmentStatus(Assessment assessment) {
    if (_submittedAssessments.contains(assessment.id)) {
      return 'completed';
    }

    final now = DateTime.now();
    if (now.isBefore(assessment.startTime)) return 'upcoming';
    if (now.isAfter(assessment.endTime)) return 'missed';
    return 'active';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'missed':
        return AppTheme.errorColor;
      case 'upcoming':
        return AppTheme.warningColor;
      case 'active':
        return AppTheme.successColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Assessment Submitted';
      case 'missed':
        return 'Assessment Missed';
      case 'upcoming':
        return 'Upcoming';
      case 'active':
        return 'Active Now';
      default:
        return status;
    }
  }

  Widget _buildAssessmentCard(Assessment assessment) {
    final status = _getAssessmentStatus(assessment);
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final isActiveNow = status == 'active';
    final isSubmitted = _submittedAssessments.contains(assessment.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    assessment.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              assessment.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Assessment Info
            Row(
              children: [
                _buildInfoChip(
                  LucideIcons.calendar,
                  DateFormat('MMM dd, yyyy').format(assessment.startTime),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  LucideIcons.clock,
                  '${assessment.duration} min',
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  LucideIcons.fileText,
                  '${assessment.questions.length} questions',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Button
            if (isActiveNow && !isSubmitted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startAssessment(assessment),
                  icon: const Icon(LucideIcons.play),
                  label: const Text('Start Assessment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                ),
              )
            else if (isSubmitted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.checkCircle, color: AppTheme.successColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Assessment Submitted Successfully',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else if (status == 'upcoming')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Assessment will be available at the scheduled time',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.warningColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (status == 'missed')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Assessment Deadline Passed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textTertiary),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults && _results != null) {
      return _buildResultsView();
    }

    if (_isActive && _activeAssessment != null) {
      return _buildActiveAssessmentView();
    }

    return Column(
      children: [
        // Header
        Row(
          children: [
            const Icon(LucideIcons.fileText, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Class Assessments',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Assessments List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _assessments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.fileText,
                            size: 64,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Assessments Available',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Your professor hasn't assigned any assessments yet.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _assessments.length,
                      itemBuilder: (context, index) => _buildAssessmentCard(_assessments[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildActiveAssessmentView() {
    if (_activeAssessment == null) return const SizedBox.shrink();

    final currentQuestion = _activeAssessment!.questions[_currentQuestion];

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
                      'Question ${_currentQuestion + 1} of ${_activeAssessment!.questions.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_currentQuestion + 1) / _activeAssessment!.questions.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Question
        Expanded(
          child: Card(
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
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentQuestion.options.length,
                      itemBuilder: (context, index) {
                        final option = currentQuestion.options[index];
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
                      },
                    ),
                  ),
                  
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
                        onPressed: _isSubmitting ? null : () {
                          if (_currentQuestion == _activeAssessment!.questions.length - 1) {
                            _submitAssessment();
                          } else {
                            setState(() => _currentQuestion++);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentQuestion == _activeAssessment!.questions.length - 1
                              ? AppTheme.successColor
                              : AppTheme.primaryColor,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _currentQuestion == _activeAssessment!.questions.length - 1
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
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    if (_results == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Results Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.checkCircle,
                      color: AppTheme.successColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Assessment Completed!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    "Here's your performance summary",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Results Summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildResultCard(
                          '${_results!['score']}',
                          'Correct',
                          AppTheme.successColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildResultCard(
                          '${_results!['totalMarks'] - _results!['score']}',
                          'Wrong',
                          AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildResultCard(
                          '${_results!['totalMarks']}',
                          'Total',
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildResultCard(
                          '${_results!['percentage'].toStringAsFixed(1)}%',
                          'Percentage',
                          AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showResults = false;
                          _results = null;
                          _activeAssessment = null;
                        });
                        _loadAssessments();
                      },
                      child: const Text('Return to Dashboard'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
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
          ),
        ],
      ),
    );
  }
}