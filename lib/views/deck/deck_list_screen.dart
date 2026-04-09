import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/deck_provider.dart';
import '../../providers/card_provider.dart';
import '../../models/deck.dart';
import 'deck_form_screen.dart';
import '../card/card_list_screen.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deckProvider = context.watch<DeckProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Mazos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo mazo',
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: _buildBody(context, deckProvider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo mazo'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DeckProvider provider) {
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
              onPressed: () => context.read<DeckProvider>().loadDecks(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (provider.decks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay mazos todavía.\nCrea uno para empezar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: provider.decks.length,
      itemBuilder: (context, index) => _DeckTile(deck: provider.decks[index]),
    );
  }

  void _openForm(BuildContext context, {Deck? deck}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeckFormScreen(deck: deck)),
    );
  }
}

// ── Tile individual de Deck ─────────────────────────────

class _DeckTile extends StatelessWidget {
  const _DeckTile({required this.deck});
  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.style, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(
          deck.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: deck.description != null && deck.description!.isNotEmpty
            ? Text(
                deck.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: _DeckMenu(deck: deck),
        onTap: () => _openCards(context),
      ),
    );
  }

  void _openCards(BuildContext context) {
    // Carga las cards del deck seleccionado antes de navegar
    context.read<CardProvider>().loadCards(deck.id!);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CardListScreen(deck: deck)),
    );
  }
}

// ── Menú contextual (editar / eliminar) ────────────────

class _DeckMenu extends StatelessWidget {
  const _DeckMenu({required this.deck});
  final Deck deck;

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
        MaterialPageRoute(builder: (_) => DeckFormScreen(deck: deck)),
      );
    } else if (value == 'delete') {
      _confirmDelete(context);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar mazo'),
        content: Text(
          '¿Eliminar "${deck.name}"? Se borrarán todas sus tarjetas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<DeckProvider>().deleteDeck(deck.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
