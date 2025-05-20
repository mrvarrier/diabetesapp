import 'package:flutter/material.dart';

class PointsCard extends StatelessWidget {
  final int pointsCount;
  final VoidCallback onTap;

  const PointsCard({
    Key? key,
    required this.pointsCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.stars,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Points',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$pointsCount',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Total earned',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            _buildNextRewardProgress(context, pointsCount),
          ],
        ),
      ),
    );
  }

  Widget _buildNextRewardProgress(BuildContext context, int points) {
    // Calculate progress to next tier (example tiers: 100, 250, 500, 1000, 2500)
    int nextTier = 100;

    if (points >= 2500) {
      nextTier = (points ~/ 1000 + 1) * 1000;
    } else if (points >= 1000) {
      nextTier = 2500;
    } else if (points >= 500) {
      nextTier = 1000;
    } else if (points >= 250) {
      nextTier = 500;
    } else if (points >= 100) {
      nextTier = 250;
    }

    double progress = (points % nextTier) / nextTier;
    if (points >= nextTier) {
      progress = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.2),
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          borderRadius: BorderRadius.circular(2),
        ),
        const SizedBox(height: 4),
        Text(
          'Next reward: $nextTier pts',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}