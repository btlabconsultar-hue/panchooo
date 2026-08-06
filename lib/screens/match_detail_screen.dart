import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sport_models.dart';

class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.match});

  final SportMatch match;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del partido')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _MatchHeader(match: match),
                  const SizedBox(height: 18),
                  _InfoTile(
                    icon: Icons.calendar_today,
                    label: 'Fecha y hora',
                    value: formatter.format(match.startTime.toLocal()),
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.stadium,
                    label: 'Estadio',
                    value: match.venue,
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.flag,
                    label: 'Liga',
                    value: match.leagueName,
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.insights,
                    label: 'Estado',
                    value: match.minute.isEmpty
                        ? match.status
                        : '${match.status} · ${match.minute}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen del partido',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    match.homeScore == null || match.awayScore == null
                        ? 'Partido por disputarse.'
                        : '${match.homeTeamName} ${match.scoreLabel} ${match.awayTeamName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID del evento: ${match.id}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estadísticas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Estos datos provienen de la API de partidos en vivo y pueden incluir resultados, horario e información del estadio.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatPill(label: 'Goles', value: match.scoreLabel),
                      const SizedBox(width: 10),
                      _StatPill(
                        label: 'Live',
                        value: match.isLive ? 'Sí' : 'No',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({required this.match});

  final SportMatch match;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TeamInfo(name: match.homeTeamName, logo: match.homeLogoUrl),
        ),
        Column(
          children: [
            Text(
              match.scoreLabel,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Chip(
              backgroundColor: match.isLive
                  ? Colors.red.shade100
                  : Colors.blue.shade50,
              label: Text(
                match.isLive ? 'EN VIVO' : match.status.toUpperCase(),
              ),
            ),
          ],
        ),
        Expanded(
          child: _TeamInfo(
            name: match.awayTeamName,
            logo: match.awayLogoUrl,
            isAway: true,
          ),
        ),
      ],
    );
  }
}

class _TeamInfo extends StatelessWidget {
  const _TeamInfo({
    required this.name,
    required this.logo,
    this.isAway = false,
  });

  final String name;
  final String logo;
  final bool isAway;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isAway
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.grey.shade100,
          child: logo.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    logo,
                    width: 46,
                    height: 46,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.sports_soccer),
                  ),
                )
              : const Icon(Icons.sports_soccer, size: 32),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: isAway ? TextAlign.right : TextAlign.left,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
