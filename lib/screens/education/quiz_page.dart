import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../services/database_service.dart';
import '../../services/points_service.dart';
import '../../services/analytics_service.dart';
import '../../navigation/app_router.dart';
import '../../constants/string_constants.dart';
import '../widgets/loading_indicator.dart';

class QuizPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const QuizPage({
    Key? key,
    required this.arguments,
  }) : super(key: key);

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late Future<QuizModel?> _quizFuture;
  int _currentQuestionIndex = 0;
  int _selectedOptionIndex = -1;
  bool _isAnswerRevealed = false;
  bool _isSubmitting = false;
  bool _isQuizComplete = false;
  List<bool> _answeredCorrectly = [];
  int _totalCorrectAnswers = 0;
  int _pointsEarned = 0;
  bool _isPassing = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();

    // Log analytics
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.logQuizStart(
      widget.arguments['contentId'],
      widget.arguments['contentId'],
    );
  }

  void _loadQuiz() {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    _quizFuture = databaseService.getContentQuiz(widget.arguments['contentId']);
  }

  void _selectOption(int optionIndex) {
    if (_isAnswerRevealed || _isSubmitting) return;

    setState(() {
      _selectedOptionIndex = optionIndex;
    });
  }

  void _revealAnswer(QuizModel quiz) {
    if (_selectedOptionIndex == -1) return;

    final currentQuestion = quiz.questions[_currentQuestionIndex];
    final isCorrect = _selectedOptionIndex == currentQuestion.correctOptionIndex;

    // Update answered correctly list
    List<bool> updatedAnswers = [..._answeredCorrectly];
    if (updatedAnswers.length <= _currentQuestionIndex) {
      updatedAnswers.add(isCorrect);
    } else {
      updatedAnswers[_currentQuestionIndex] = isCorrect;
    }

    setState(() {
      _isAnswerRevealed = true;
      _answeredCorrectly = updatedAnswers;
    });
  }

  void _nextQuestion(QuizModel quiz) {
    if (_currentQuestionIndex < quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = -1;
        _isAnswerRevealed = false;
      });
    } else {
      _completeQuiz(quiz);
    }
  }

  Future<void> _completeQuiz(QuizModel quiz) async {
    setState(() {
      _isSubmitting = true;
    });

    // Calculate score
    final score = _answeredCorrectly.where((correct) => correct).length;
    final percentage = (score / quiz.questions.length) * 100;
    final isPassing = percentage >= quiz.passingScore;

    try {
      // Award points for quiz completion
      final pointsService = Provider.of<PointsService>(context, listen: false);
      final pointsEarned = await pointsService.awardQuizPoints(
        widget.arguments['contentId'],
        score,
        quiz.questions.length,
      );

      // Log analytics
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      analyticsService.logQuizComplete(
        quiz.id,
        widget.arguments['contentId'],
        score,
        quiz.questions.length,
        isPassing,
      );

      setState(() {
        _isQuizComplete = true;
        _totalCorrectAnswers = score;
        _pointsEarned = pointsEarned;
        _isPassing = isPassing;
        _isSubmitting = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting quiz: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedOptionIndex = -1;
      _isAnswerRevealed = false;
      _isQuizComplete = false;
      _answeredCorrectly = [];
    });
  }

  void _navigateToNextLesson() {
    // Navigate back to education plan
    AppRouter.navigateToAndRemoveUntil('/education-plan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(StringConstants.quizTitle),
      ),
      body: FutureBuilder<QuizModel?>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading quiz...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final quiz = snapshot.data;
          if (quiz == null) {
            return Center(
              child: Text(
                'No quiz found for this content.\nPlease try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            );
          }

          if (_isQuizComplete) {
            return _buildQuizCompleteView(quiz);
          }

          return _buildQuizView(quiz);
        },
      ),
    );
  }

  Widget _buildQuizView(QuizModel quiz) {
    final currentQuestion = quiz.questions[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / quiz.questions.length,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 8),

          // Question counter
          Text(
            '${StringConstants.question} ${_currentQuestionIndex + 1} ${StringConstants.of} ${quiz.questions.length}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Question text
          Text(
            currentQuestion.questionText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Answer options
          Expanded(
            child: ListView.separated(
              itemCount: currentQuestion.options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                bool isSelected = _selectedOptionIndex == index;
                bool isCorrect = index == currentQuestion.correctOptionIndex;

                Color backgroundColor;
                Color borderColor;

                if (_isAnswerRevealed) {
                  if (isCorrect) {
                    backgroundColor = Colors.green.withOpacity(0.1);
                    borderColor = Colors.green;
                  } else if (isSelected && !isCorrect) {
                    backgroundColor = Colors.red.withOpacity(0.1);
                    borderColor = Colors.red;
                  } else {
                    backgroundColor = Theme.of(context).colorScheme.surface;
                    borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.5);
                  }
                } else {
                  if (isSelected) {
                    backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
                    borderColor = Theme.of(context).colorScheme.primary;
                  } else {
                    backgroundColor = Theme.of(context).colorScheme.surface;
                    borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.5);
                  }
                }

                return GestureDetector(
                  onTap: () => _selectOption(index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Option letter
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (_isAnswerRevealed
                                ? (isCorrect ? Colors.green : Colors.red)
                                : Theme.of(context).colorScheme.primary)
                                : (_isAnswerRevealed && isCorrect
                                ? Colors.green
                                : Theme.of(context).colorScheme.surface),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? (_isAnswerRevealed
                                  ? (isCorrect ? Colors.green : Colors.red)
                                  : Theme.of(context).colorScheme.primary)
                                  : (_isAnswerRevealed && isCorrect
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D...
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (_isAnswerRevealed && isCorrect
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Option text
                        Expanded(
                          child: Text(
                            currentQuestion.options[index],
                            style: TextStyle(
                              fontWeight: isSelected || (_isAnswerRevealed && isCorrect)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),

                        // Correct/Incorrect icon
                        if (_isAnswerRevealed) ...[
                          Icon(
                            isCorrect
                                ? Icons.check_circle
                                : (isSelected ? Icons.cancel : null),
                            color: isCorrect
                                ? Colors.green
                                : (isSelected ? Colors.red : null),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Explanation if answer revealed
          if (_isAnswerRevealed && currentQuestion.explanation != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explanation:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(currentQuestion.explanation!),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Action button
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : (_isAnswerRevealed
                ? () => _nextQuestion(quiz)
                : () => _revealAnswer(quiz)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
                : Text(
              _isAnswerRevealed
                  ? (_currentQuestionIndex < quiz.questions.length - 1
                  ? 'Next Question'
                  : 'Finish Quiz')
                  : StringConstants.submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCompleteView(QuizModel quiz) {
    final percentage = (_totalCorrectAnswers / quiz.questions.length) * 100;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Completion icon
          Icon(
            _isPassing ? Icons.check_circle : Icons.info,
            size: 80,
            color: _isPassing ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 24),

          // Quiz completion title
          Text(
            StringConstants.quizComplete,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Result message
          Text(
            _isPassing
                ? StringConstants.quizPassed
                : StringConstants.quizFailed,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Score card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isPassing
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPassing ? Colors.green : Colors.orange,
              ),
            ),
            child: Column(
              children: [
                // Score title
                Text(
                  StringConstants.yourScore,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Score display
                Text(
                  '$_totalCorrectAnswers/${quiz.questions.length}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _isPassing ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),

                // Percentage
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isPassing ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),

                // Passing score info
                Text(
                  'Passing score: ${quiz.passingScore}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Points earned
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.stars,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  '+$_pointsEarned points earned',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              // Try again button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _restartQuiz,
                  icon: const Icon(Icons.refresh),
                  label: const Text(StringConstants.tryAgain),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Continue button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _navigateToNextLesson,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}