// File: lib/presentation/screens/education/quiz_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/constants.dart';
import '../../../core/utils/app_colors.dart';
import '../../../data/models/quiz_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/quiz_provider.dart';
import '../../../domain/providers/progress_provider.dart';
import '../../../domain/providers/achievements_provider.dart';

class QuizPage extends StatefulWidget {
  final String quizId;
  final String lessonId;

  const QuizPage({
    Key? key,
    required this.quizId,
    required this.lessonId,
  }) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  Quiz? _quiz;
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  List<List<String>> _selectedOptions = [];
  bool _isQuizCompleted = false;
  int _score = 0;
  bool _isPassed = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get quiz provider
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);

      // Load quiz
      final quiz = await quizProvider.getQuizById(widget.quizId);

      if (quiz != null) {
        // Initialize selected options
        final selectedOptions = List<List<String>>.filled(
          quiz.questions.length,
          [],
          growable: true,
        );

        setState(() {
          _quiz = quiz;
          _selectedOptions = selectedOptions;
          _isLoading = false;
        });
      } else {
        // Quiz not found
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quiz not found.'),
              backgroundColor: AppColors.error,
            ),
          );

          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load quiz: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );

        Navigator.of(context).pop();
      }
    }
  }

  void _selectOption(String optionId) {
    if (_isQuizCompleted) return;

    final currentQuestion = _quiz!.questions[_currentQuestionIndex];

    setState(() {
      if (currentQuestion.questionType == AppConstants.questionTypeMultipleChoice &&
          currentQuestion.correctAnswers.length > 1) {
        // Multiple correct answers allowed
        final selectedOptions = List<String>.from(_selectedOptions[_currentQuestionIndex]);

        if (selectedOptions.contains(optionId)) {
          // Deselect option
          selectedOptions.remove(optionId);
        } else {
          // Select option
          selectedOptions.add(optionId);
        }

        _selectedOptions[_currentQuestionIndex] = selectedOptions;
      } else {
        // Single correct answer
        _selectedOptions[_currentQuestionIndex] = [optionId];
      }
    });
  }

  bool _isOptionSelected(String optionId) {
    return _selectedOptions[_currentQuestionIndex].contains(optionId);
  }

  bool _canProceed() {
    return _selectedOptions[_currentQuestionIndex].isNotEmpty;
  }

  bool _isLastQuestion() {
    return _currentQuestionIndex == _quiz!.questions.length - 1;
  }

  void _nextQuestion() {
    if (!_canProceed()) return;

    if (_isLastQuestion()) {
      _completeQuiz();
    } else {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _completeQuiz() {
    if (_quiz == null) return;

    // Calculate score
    int correctCount = 0;

    for (int i = 0; i < _quiz!.questions.length; i++) {
      final question = _quiz!.questions[i];
      final selectedOptions = _selectedOptions[i];

      if (question.isCorrect(selectedOptions)) {
        correctCount++;
      }
    }

    final score = correctCount;
    final totalPossible = _quiz!.questions.length;
    final scorePercentage = (score / totalPossible) * 100;
    final isPassed = scorePercentage >= _quiz!.passingScore;

    setState(() {
      _isQuizCompleted = true;
      _score = score;
      _isPassed = isPassed;
    });

    _updateProgress(score, totalPossible, isPassed);
  }

  Future<void> _updateProgress(int score, int totalPossible, bool isPassed) async {
    try {
      // Get providers
      final progressProvider = Provider.of<ProgressProvider>(context, listen: false);

      // Update progress
      await progressProvider.updateQuizResults(
        contentId: widget.lessonId,
        score: score,
        totalPossible: totalPossible,
        isPassed: isPassed,
        pointsPerQuestion: _quiz!.pointsPerQuestion,
      );

      // Check for perfect score achievement
      if (score == totalPossible) {
        await _checkPerfectQuizAchievement();
      }

      // Award points
      if (isPassed) {
        await _awardPoints(score * _quiz!.pointsPerQuestion);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update progress: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _checkPerfectQuizAchievement() async {
    // Get providers
    final achievementsProvider = Provider.of<AchievementsProvider>(context, listen: false);

    // Check achievement
    await achievementsProvider.checkAndAwardAchievements(
      isPerfectQuiz: true,
    );
  }

  Future<void> _awardPoints(int points) async {
    // Get auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Refresh user data (will update points)
    await authProvider.refreshUserData();
  }

  void _showQuizResults() {
    if (_quiz == null) return;

    final totalPossible = _quiz!.questions.length;
    final scorePercentage = (_score / totalPossible) * 100;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _isPassed ? Icons.check_circle : Icons.cancel,
              color: _isPassed ? AppColors.success : AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(_isPassed ? 'Quiz Passed!' : 'Quiz Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isPassed
                  ? 'Congratulations! You have successfully completed the quiz.'
                  : 'You did not pass the quiz. Keep learning and try again.',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Score
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isPassed ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPassed ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${scorePercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _isPassed ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_score of $totalPossible correct',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Points
            if (_isPassed)
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${_score * _quiz!.pointsPerQuestion} points earned',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentColor,
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          if (!_isPassed)
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetQuiz();
              },
              child: const Text('Try Again'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToHome();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _resetQuiz() {
    if (_quiz == null) return;

    // Reset quiz state
    setState(() {
      _currentQuestionIndex = 0;
      _selectedOptions = List<List<String>>.filled(
        _quiz!.questions.length,
        [],
        growable: true,
      );
      _isQuizCompleted = false;
      _score = 0;
      _isPassed = false;
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.homeRoute,
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          if (_isQuizCompleted)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetQuiz,
              tooltip: 'Restart Quiz',
            ),
        ],
      ),
      body: _isLoading || _quiz == null
          ? const Center(child: CircularProgressIndicator())
          : _isQuizCompleted
          ? _buildResultsView()
          : _buildQuizView(),
    );
  }

  Widget _buildQuizView() {
    final currentQuestion = _quiz!.questions[_currentQuestionIndex];

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _quiz!.questions.length,
          backgroundColor: AppColors.progressBarBackground,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          minHeight: 6,
        ),

        // Question counter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_quiz!.questions.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Question type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getQuestionTypeLabel(currentQuestion.questionType),
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Question text
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Text(
                  currentQuestion.questionText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Options
                ...currentQuestion.options.map((option) => _buildOptionItem(option)),
              ],
            ),
          ),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousQuestion,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canProceed() ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(_isLastQuestion() ? 'Submit' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem(QuizOption option) {
    final isSelected = _isOptionSelected(option.id);

    return GestureDetector(
      onTap: () => _selectOption(option.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryColor : Colors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primaryColor : AppColors.divider,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
                  : null,
            ),
            const SizedBox(width: 12),
            // Option text
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? AppColors.primaryColor : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    if (_quiz == null) return const SizedBox.shrink();

    // Show results dialog when view is first built
    Future.microtask(() => _showQuizResults());

    final totalPossible = _quiz!.questions.length;
    final scorePercentage = (_score / totalPossible) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quiz title
          Text(
            _quiz!.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _quiz!.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Results card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Result icon
                  Icon(
                    _isPassed ? Icons.check_circle : Icons.cancel,
                    color: _isPassed ? AppColors.success : AppColors.error,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  // Result text
                  Text(
                    _isPassed ? 'Quiz Passed!' : 'Quiz Failed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isPassed ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPassed
                        ? 'Congratulations! You have successfully completed the quiz.'
                        : 'You did not pass the quiz. Required score: ${_quiz!.passingScore}%',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Score
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isPassed ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isPassed ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${scorePercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _isPassed ? AppColors.success : AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_score of $totalPossible correct',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Points
                  if (_isPassed)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${_score * _quiz!.pointsPerQuestion} points earned',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Question review heading
          const Text(
            'Question Review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Questions and answers
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quiz!.questions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildQuestionReviewItem(index),
          ),
          const SizedBox(height: 24),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetQuiz,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToHome,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewItem(int questionIndex) {
    final question = _quiz!.questions[questionIndex];
    final selectedOptions = _selectedOptions[questionIndex];
    final isCorrect = question.isCorrect(selectedOptions);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number and result
            Row(
              children: [
                Text(
                  'Question ${questionIndex + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Result indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrect ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCorrect ? 'Correct' : 'Incorrect',
                    style: TextStyle(
                      color: isCorrect ? AppColors.success : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Question text
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Selected options
            const Text(
              'Your answer:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            ...selectedOptions.map((optionId) {
              final option = question.options.firstWhere(
                    (o) => o.id == optionId,
                orElse: () => QuizOption(id: '', text: 'Unknown option'),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      question.correctAnswers.contains(optionId)
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: question.correctAnswers.contains(optionId)
                          ? AppColors.success
                          : AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Correct answer if incorrect
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              const Text(
                'Correct answer:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              ...question.correctAnswers.map((optionId) {
                final option = question.options.firstWhere(
                      (o) => o.id == optionId,
                  orElse: () => QuizOption(id: '', text: 'Unknown option'),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option.text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Explanation if available
            if (question.explanation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: AppColors.info,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Explanation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question.explanation!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getQuestionTypeLabel(String questionType) {
    switch (questionType) {
      case AppConstants.questionTypeMultipleChoice:
        return 'MULTIPLE CHOICE';
      case AppConstants.questionTypeTrueFalse:
        return 'TRUE/FALSE';
      case AppConstants.questionTypeMatching:
        return 'MATCHING';
      default:
        return 'QUESTION';
    }
  }
}