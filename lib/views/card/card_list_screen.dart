import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/card.dart';
import '../../providers/card_provider.dart';
import '../../providers/session_provider.dart';
import 'card_form_screen.dart';
import '../study/study_screen.dart';
import '../study/leaderboard_screen.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key, required this.deck});
  final Deck deck;

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<SessionProvider>();
      sp.checkHasSessions(widget.deck.id!);
      // Consulta DB por progreso pausado para mostrar el banner (Bug #4).
      sp.checkSavedProgress(widget.deck.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardProvider = context.watch<CardProvider>();
    final sessionProvider = context.watch<SessionProvider>();
    // Usa hasSavedProgress: true si hay sesión activa en memoria O progreso en DB.
    final hasProgress = sessionProvider.hasSavedProgress(widget.deck.id!);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          // Leaderboard (solo si hay sesiones finalizadas)
          if (sessionProvider.hasAnySessions)
            IconButton(
              icon: const Icon(Icons.leaderboard),
              tooltip: 'Leaderboard',
              onPressed: () => _openLeaderboard(context),
            ),
          // Importar CSV (bloqueado si hay sesión activa o pausada)
          if (!hasProgress)
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Importar CSV',
              onPressed: () => _importCsv(context),
            ),
          // Estudiar / Abandonar sesión
          if (cardProvider.cards.isNotEmpty)
            hasProgress
                ? IconButton(
                    icon: const Icon(Icons.stop_circle_outlined),
                    tooltip: 'Abandonar sesión',
                    color: Colors.red,
                    onPressed: () => _confirmAbandon(context),
                  )
                : IconButton(
                    icon: const Icon(Icons.school),
                    tooltip: 'Estudiar',
                    onPressed: () => _startStudy(context),
                  ),
        ],
      ),
      body: _buildBody(context, cardProvider, hasProgress),
      floatingActionButton: hasProgress
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Nueva tarjeta'),
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CardProvider provider,
    bool hasProgress,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(provider.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                context.read<CardProvider>()
                  ..clearError()
                  ..loadCards(widget.deck.id!);
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (provider.cards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay tarjetas en este mazo.\nCrea una o importa un CSV.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final sp = context.watch<SessionProvider>();
    final deckId = widget.deck.id!;

    return Column(
      children: [
        if (hasProgress)
          _ActiveSessionBanner(
            hits: sp.hitsFor(deckId),
            misses: sp.missesFor(deckId),
            total: provider.cards.length,
            onResume: () => _startStudy(context),
            onAbandon: () => _confirmAbandon(context),
          )
        else
          _StudyBanner(
            count: provider.cards.length,
            onTap: () => _startStudy(context),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: provider.cards.length,
            itemBuilder: (context, index) =>
                _CardTile(card: provider.cards[index], isLocked: hasProgress),
          ),
        ),
      ],
    );
  }

  void _openForm(BuildContext context, {FlashCard? card}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardFormScreen(deckId: widget.deck.id!, card: card),
      ),
    );
  }

  /// Navega a StudyScreen. El initState de StudyScreen llama a
  /// startOrResumeSession(), que se encarga de guardar/cargar el progreso.
  void _startStudy(BuildContext context) {
    final cards = context.read<CardProvider>().cards;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(deck: widget.deck, cards: cards),
      ),
    );
  }

  void _confirmAbandon(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandonar sesión'),
        content: const Text(
          'El progreso de esta sesión se perderá. ¿Deseas abandonar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // abandonSession es async pero no necesitamos aguardar: el
              // notifyListeners() interno actualiza el banner inmediatamente.
              context.read<SessionProvider>().abandonSession();
              Navigator.pop(ctx);
            },
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
  }

  void _openLeaderboard(BuildContext context) {
    context.read<SessionProvider>().loadSessions(widget.deck.id!);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LeaderboardScreen(deck: widget.deck)),
    );
  }

  Future<void> _importCsv(BuildContext context) async {
    final provider = context.read<CardProvider>();
    final count = await provider.importFromCsv(widget.deck.id!);

    if (!context.mounted) return;

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
      provider.clearError();
    } else if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $count tarjetas importadas correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// ── Banner sesión activa/pausada ──────────────────────

class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner({
    required this.hits,
    required this.misses,
    required this.total,
    required this.onResume,
    required this.onAbandon,
  });
  final int hits;
  final int misses;
  final int total;
  final VoidCallback onResume;
  final VoidCallback onAbandon;

  @override
  Widget build(BuildContext context) {
    final reviewed = hits + misses;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.orange[100],
      child: Row(
        children: [
          const Icon(Icons.play_circle, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sesión en curso',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  '$reviewed / $total revisadas · ✅ $hits  ❌ $misses',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onResume, child: const Text('Continuar')),
        ],
      ),
    );
  }
}

// ── Banner sin sesión activa ──────────────────────────

class _StudyBanner extends StatelessWidget {
  const _StudyBanner({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: colorScheme.primaryContainer,
        child: Row(
          children: [
            Icon(Icons.school, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count tarjetas · Toca para estudiar',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onPrimaryContainer),
          ],
        ),
      ),
    );
  }
}

// ── Tile individual ───────────────────────────────────

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.isLocked});
  final FlashCard card;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          card.front,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(card.back, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatChip(icon: Icons.check, count: card.hits, color: Colors.green),
            const SizedBox(width: 6),
            _StatChip(icon: Icons.close, count: card.misses, color: Colors.red),
            if (!isLocked) _CardMenu(card: card),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.count,
    required this.color,
  });
  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text('$count', style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _CardMenu extends StatelessWidget {
  const _CardMenu({required this.card});
  final FlashCard card;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _onSelected(context, value),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Editar')),
        PopupMenuItem(
          value: 'delete',
          child: Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  void _onSelected(BuildContext context, String value) {
    if (value == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CardFormScreen(deckId: card.deckId, card: card),
        ),
      );
    } else {
      _confirmDelete(context);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: Text('¿Eliminar la tarjeta "${card.front}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CardProvider>().deleteCard(card.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
