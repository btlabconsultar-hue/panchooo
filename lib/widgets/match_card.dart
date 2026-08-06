import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sport_models.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    required this.onFavoritePressed,
    required this.isFavorite,
  });

  final SportMatch match;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd MMM HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.leagueName,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onFavoritePressed,
                    icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                    color: isFavorite
                        ? Colors.amber
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TeamColumn(
                      teamName: match.homeTeamName,
                      logoUrl: match.homeLogoUrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ScoreSection(match: match),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TeamColumn(
                      teamName: match.awayTeamName,
                      logoUrl: match.awayLogoUrl,
                      isAway: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Chip(
                    backgroundColor: match.isLive
                        ? Colors.red.shade100
                        : Colors.blue.shade50,
                    label: Text(
                      match.isLive ? 'En vivo' : match.status,
                      style: TextStyle(
                        color: match.isLive
                            ? Colors.red.shade800
                            : Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14),
                      const SizedBox(width: 6),
                      Text(formatter.format(match.startTime.toLocal())),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.stadium_outlined, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      match.venue,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreSection extends StatelessWidget {
  const _ScoreSection({required this.match});

  final SportMatch match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          match.scoreLabel,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          match.minute.isEmpty ? 'Horario' : '${match.minute}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.teamName,
    required this.logoUrl,
    this.isAway = false,
  });

  final String teamName;
  final String logoUrl;
  final bool isAway;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isAway
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey.shade100,
          child: logoUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    logoUrl,
                    width: 42,
                    height: 42,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.sports_soccer),
                  ),
                )
              : const Icon(Icons.sports_soccer, size: 30),
        ),
        const SizedBox(height: 10),
        Text(
          teamName,
          textAlign: isAway ? TextAlign.right : TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
