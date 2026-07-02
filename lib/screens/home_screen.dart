import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sport_models.dart';
import '../providers/app_state.dart';
import '../widgets/match_card.dart';
import '../widgets/standing_card.dart';
import 'match_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _viewIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final now = DateTime.now();
    final upcoming = appState.matches
        .where((m) => m.startTime.isAfter(now))
        .toList();
    final finished = appState.matches
        .where(
          (m) =>
              m.startTime.isBefore(now) ||
              (m.homeScore != null && m.awayScore != null),
        )
        .toList();
    final liveMatches = appState.matches.where((m) => m.isLive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central Deportiva'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
            icon: const Icon(Icons.favorite_outline),
            tooltip: 'Favoritos',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: appState.loadMatches,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _HeroHeader(),
            const SizedBox(height: 16),
            _ActionBanner(isConfigured: appState.aiService.hasAnyKey),
            const SizedBox(height: 18),
            _SportAndLeagueSelector(appState: appState),
            const SizedBox(height: 18),
            _StatsRow(
              upcomingCount: upcoming.length,
              liveCount: liveMatches.length,
              favoritesCount: appState.favorites.length,
            ),
            const SizedBox(height: 18),
            if (appState.lastError != null)
              _ErrorBanner(message: appState.lastError!),
            if (appState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (liveMatches.isNotEmpty) ...[
                const SectionHeader(title: 'En vivo ahora'),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: liveMatches.length,
                    itemBuilder: (context, index) {
                      final match = liveMatches[index];
                      return SizedBox(
                        width: 320,
                        child: MatchCard(
                          match: match,
                          isFavorite: appState.favorites.any(
                            (item) => item.id == match.id,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MatchDetailScreen(match: match),
                            ),
                          ),
                          onFavoritePressed: () =>
                              appState.toggleFavorite(match),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const SectionHeader(title: 'Partidos'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: [
                        ButtonSegment(
                          value: 0,
                          label: Text('Próximos (${upcoming.length})'),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Anteriores (${finished.length})'),
                        ),
                      ],
                      selected: <int>{_viewIndex},
                      onSelectionChanged: (sel) =>
                          setState(() => _viewIndex = sel.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final list = _viewIndex == 0 ? upcoming : finished;
                  if (list.isEmpty) {
                    return const _EmptyState(
                      message: 'No hay partidos disponibles en este momento.',
                    );
                  }
                  return Column(
                    children: list.map((match) {
                      return MatchCard(
                        match: match,
                        isFavorite: appState.favorites.any(
                          (item) => item.id == match.id,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MatchDetailScreen(match: match),
                          ),
                        ),
                        onFavoritePressed: () => appState.toggleFavorite(match),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Tabla de posiciones'),
              const SizedBox(height: 12),
              if (appState.standings.isEmpty)
                const _EmptyState(message: 'La tabla aún no está disponible.')
              else
                ...appState.standings.map(
                  (entry) => StandingCard(entry: entry),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF093C8F), Color(0xFF0E70E1)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Central Deportiva',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '''Recorré la fecha, guardá tus partidos favoritos y pregunta al asistente deportivo.
Todo en tiempo real y con datos de tus ligas preferidas.''',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/checkout'),
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Abrir tienda y checkout'),
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF093C8F)),
          ),
        ],
      ),
    );
  }
}

class _ActionBanner extends StatelessWidget {
  const _ActionBanner({required this.isConfigured});

  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 28,
              color: Color(0xFF1866E0),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                isConfigured
                    ? 'La IA está lista. Tap en Asistente y consultá partidos, estadísticas y clásicos.'
                    : 'Sin clave de IA activa. Configura Gemini u OpenAI en Ajustes para respuestas avanzadas.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.upcomingCount,
    required this.liveCount,
    required this.favoritesCount,
  });

  final int upcomingCount;
  final int liveCount;
  final int favoritesCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Próximos',
            value: upcomingCount.toString(),
            icon: Icons.schedule,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'En vivo',
            value: liveCount.toString(),
            icon: Icons.sports_soccer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Favoritos',
            value: favoritesCount.toString(),
            icon: Icons.star,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SportAndLeagueSelector extends StatelessWidget {
  const _SportAndLeagueSelector({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<Sport>(
          segments: const [
            ButtonSegment(value: Sport.football, label: Text('Fútbol')),
            ButtonSegment(value: Sport.basketball, label: Text('Básquet')),
          ],
          selected: <Sport>{appState.selectedSport},
          onSelectionChanged: (selection) =>
              appState.setSelectedSport(selection.first),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<LeagueOption>(
                value: appState.selectedLeague,
                items:
                    (appState.selectedSport == Sport.football
                            ? appState.footballLeagues
                            : appState.basketballLeagues)
                        .map(
                          (league) => DropdownMenuItem(
                            value: league,
                            child: Text(league.displayName),
                          ),
                        )
                        .toList(),
                onChanged: (league) {
                  if (league != null) {
                    appState.setSelectedLeague(league);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
