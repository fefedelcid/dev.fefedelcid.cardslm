import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/study_session.dart';
import '../../providers/session_provider.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key, required this.deck});
  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionProvider>().sessions;

    return Scaffold(
      appBar: AppBar(title: Text('Historial · ${deck.name}')),
      body: sessions.isEmpty
          ? const Center(
              child: Text(
                'Aún no hay sesiones completadas.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(sessions: sessions),
                const SizedBox(height: 16),
                const Text(
                  'Sesiones',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...sessions.asMap().entries.map(
                  (e) => _SessionTile(session: e.value, rank: e.key + 1),
                ),
              ],
            ),
    );
  }
}

// ── Tarjeta de resumen global ─────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.sessions});
  final List<StudySession> sessions;

  @override
  Widget build(BuildContext context) {
    final totalSessions = sessions.length;
    final avgAccuracy = sessions.isEmpty
        ? 0
        : (sessions.map((s) => s.accuracy).reduce((a, b) => a + b) /
                totalSessions)
            .round();
    final best = sessions.reduce((a, b) => a.accuracy >= b.accuracy ? a : b);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryStat(
            label: 'Sesiones',
            value: '$totalSessions',
            icon: Icons.history,
          ),
          _SummaryStat(
            label: 'Precisión media',
            value: '$avgAccuracy%',
            icon: Icons.analytics,
          ),
          _SummaryStat(
            label: 'Mejor sesión',
            value: '${best.accuracy}%',
            icon: Icons.emoji_events,
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? Colors.amber[700]! : Colors.black87;
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}

// ── Fila de sesión individual ─────────────────────────

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.rank});
  final StudySession session;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final accuracy = session.accuracy;
    final color = accuracy >= 80
        ? Colors.green
        : accuracy >= 50
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            '#$rank',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          '$accuracy% de precisión',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '✅ ${session.hits}  ❌ ${session.misses}  · ${session.total} tarjetas',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          _formatDate(session.completedAt),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}
