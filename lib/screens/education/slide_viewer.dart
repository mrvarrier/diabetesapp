import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/content_model.dart';
import '../../services/database_service.dart';
import '../../services/points_service.dart';
import '../../services/analytics_service.dart';
import '../../navigation/app_router.dart';
import '../widgets/loading_indicator.dart';
import 'quiz_button.dart';

class SlideViewer extends StatefulWidget {
  final ContentModel content;

  const SlideViewer({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  _SlideViewerState createState() => _SlideViewerState();
}

class _SlideViewerState extends State<SlideViewer> {
  final PageController _pageController = PageController();
  late Future<bool> _hasQuizFuture;
  bool _hasQuiz = false;
  bool _isContentCompleted = false;
  int _currentPageIndex = 0;
  bool _isLoading = true;
  String _progressId = '';

  @override
  void initState() {
    super.initState();
    _initializeContent();
    _checkQuizAvailability();

    // Log analytics
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.logLessonStart(widget.content.id, widget.content.title);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeContent() async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final userId = Provider.of<AuthService>(context, listen: false).uid;

      if (userId != null) {
        // Start content progress
        _progressId = await databaseService.startContentProgress(userId, widget.content.id);

        // Check if content is already completed
        final progress = await databaseService.getUserContentProgress(userId, widget.content.id);
        if (progress != null) {
          setState(() {
            _isContentCompleted = progress.isCompleted;
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing content: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkQuizAvailability() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    _hasQuizFuture = databaseService.getContentQuiz(widget.content.id).then((quiz) => quiz != null);
  }

  Future<void> _completeContent() async {
    if (_isContentCompleted) return;

    try {
      final userId = Provider.of<AuthService>(context, listen: false).uid;

      if (userId != null) {
        // Award points
        final pointsService = Provider.of<PointsService>(context, listen: false);
        await pointsService.awardVideoPoints(widget.content.id);

        // Log analytics
        final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
        analyticsService.logLessonComplete(
          widget.content.id,
          widget.content.title,
          widget.content.pointsValue,
          widget.content.estimatedDuration * 60,
        );

        setState(() {
          _isContentCompleted = true;
        });
      }
    } catch (e) {
      print('Error completing content: $e');
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });

    // Mark content as completed if we've reached the last slide
    if (index == widget.content.slideContents.length - 1) {
      _completeContent();
    }
  }

  void _navigateToQuiz() {
    AppRouter.navigateTo('/quiz', arguments: {
      'contentId': widget.content.id,
    });

    // Log analytics
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.logFeatureUse('navigate_to_quiz');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.content.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Slide number indicator
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_currentPageIndex + 1}/${widget.content.slideContents.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading content...')
          : Column(
        children: [
          // Slides
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.content.slideContents.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _buildSlide(widget.content.slideContents[index]);
              },
            ),
          ),

          // Bottom navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildSlide(String slideContent) {
    // For MVP, we'll render a simple markdown-like format
    // In a real app, this would use a proper markdown renderer
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        slideContent,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPageIndex + 1) / widget.content.slideContents.length,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 16),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              _currentPageIndex > 0
                  ? ElevatedButton.icon(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                ),
              )
                  : const SizedBox(width: 100),

              // Current page indicator
              Text(
                '${_currentPageIndex + 1}/${widget.content.slideContents.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              // Next button
              _currentPageIndex < widget.content.slideContents.length - 1
                  ? ElevatedButton.icon(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              )
                  : const SizedBox(width: 100),
            ],
          ),

          // Quiz button (if available and on last slide)
          if (_currentPageIndex == widget.content.slideContents.length - 1)
            FutureBuilder<bool>(
              future: _hasQuizFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 16);
                }

                final hasQuiz = snapshot.data ?? false;

                if (hasQuiz) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: QuizButton(
                      isCompleted: _isContentCompleted,
                      onTap: _navigateToQuiz,
                    ),
                  );
                }

                // If no quiz, but we're on last slide, show completion message
                if (_isContentCompleted) {
                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lesson completed! ${widget.content.pointsValue} points earned.',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox(height: 16);
              },
            ),
        ],
      ),
    );
  }
}