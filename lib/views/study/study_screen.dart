import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../../models/deck.dart';
import '../../models/card.dart';
import '../../providers/card_provider.dart';
import '../../providers/session_provider.dart';
import '../widgets/math_text.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.deck, required this.cards});
  final Deck deck;
  final List<FlashCard> cards;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late final CardSwiperController _swiperController;
  late final List<FlipCardController> _flipControllers;

  int _currentIndex = 0;
  int _hits = 0;
  int _misses = 0;
  bool _isFinished = false;
  bool _isInitializing = true;

  int _startOffset = 0;

  @override
  void initState() {
    super.initState();
    _swiperController = CardSwiperController();
    _flipControllers = List.generate(
      widget.cards.length,
      (_) => FlipCardController(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSession());
  }

  Future<void> _initSession() async {
    if (!mounted) return;
    final sp = context.read<SessionProvider>();

    await sp.startOrResumeSession(widget.deck.id!);

    if (!mounted) return;
    setState(() {
      _hits = sp.currentHits;
      _misses = sp.currentMisses;
      _startOffset = sp.currentIndex;
      _currentIndex = sp.currentIndex;
      _isInitializing = false;
    });
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  int get _remainingCount => widget.cards.length - _startOffset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _SessionCounter(hits: _hits, misses: _misses),
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _isFinished
          ? _buildFinishedView(context)
          : _buildStudyView(context),
    );
  }

  // ── Vista de estudio (swiper) ─────────────────────────

  Widget _buildStudyView(BuildContext context) {
    return Column(
      children: [
        _ProgressBar(current: _currentIndex, total: widget.cards.length),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Toca para voltear · ← Error  Acierto →',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        Expanded(
          child: CardSwiper(
            controller: _swiperController,
            cardsCount: _remainingCount,
            numberOfCardsDisplayed: _remainingCount >= 3 ? 3 : _remainingCount,
            backCardOffset: const Offset(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            allowedSwipeDirection: const AllowedSwipeDirection.only(
              left: true,
              right: true,
            ),
            onSwipe: _onSwipe,
            onEnd: _onEnd,
            cardBuilder: (context, index, _, _) =>
                _buildFlipCard(index + _startOffset),
          ),
        ),
        _ActionButtons(
          onMiss: () => _swiperController.swipe(CardSwiperDirection.left),
          onHit: () => _swiperController.swipe(CardSwiperDirection.right),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFlipCard(int realIndex) {
    final card = widget.cards[realIndex];
    final colorScheme = Theme.of(context).colorScheme;

    return FlipCard(
      key: ValueKey(card.id ?? realIndex),
      controller: _flipControllers[realIndex],
      flipOnTouch: true,
      direction: FlipDirection.HORIZONTAL,
      front: _CardFace(
        text: card.front,
        label: 'PREGUNTA',
        color: colorScheme.primaryContainer,
        textColor: colorScheme.onPrimaryContainer,
      ),
      back: _CardFace(
        text: card.back,
        label: 'RESPUESTA',
        color: colorScheme.secondaryContainer,
        textColor: colorScheme.onSecondaryContainer,
      ),
    );
  }

  // ── Vista de sesión finalizada ────────────────────────

  Widget _buildFinishedView(BuildContext context) {
    final total = widget.cards.length;
    final pct = total > 0 ? (_hits / total * 100).round() : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pct >= 70 ? Icons.emoji_events : Icons.replay,
              size: 80,
              color: pct >= 70 ? Colors.amber : Colors.blueGrey,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Sesión completada!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _ResultRow(label: 'Tarjetas', value: '$total'),
            _ResultRow(label: 'Aciertos', value: '$_hits', color: Colors.green),
            _ResultRow(label: 'Errores', value: '$_misses', color: Colors.red),
            _ResultRow(
              label: 'Precisión',
              value: '$pct%',
              color: pct >= 70 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _restartSession,
                    icon: const Icon(Icons.replay),
                    label: const Text('Repetir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Callbacks ─────────────────────────────────────────

  bool _onSwipe(
    int prevIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    final realPrev = prevIndex + _startOffset;
    final card = widget.cards[realPrev];
    final provider = context.read<CardProvider>();
    final sp = context.read<SessionProvider>();

    if (direction == CardSwiperDirection.right) {
      setState(() => _hits++);
      provider.recordHit(card);
    } else if (direction == CardSwiperDirection.left) {
      setState(() => _misses++);
      provider.recordMiss(card);
    }

    final nextRealIndex = (currentIndex != null)
        ? currentIndex + _startOffset
        : widget.cards.length;

    setState(() => _currentIndex = nextRealIndex);
    sp.updateProgress(_hits, _misses, nextRealIndex);

    return true;
  }

  Future<void> _onEnd() async {
    final sp = context.read<SessionProvider>();
    await sp.completeSession(
      deckId: widget.deck.id!,
      hits: _hits,
      misses: _misses,
      total: widget.cards.length,
    );
    setState(() => _isFinished = true);
  }

  Future<void> _restartSession() async {
    final sp = context.read<SessionProvider>();
    await sp.abandonSession();
    await sp.startOrResumeSession(widget.deck.id!);

    if (!mounted) return;
    setState(() {
      _startOffset = 0;
      _currentIndex = 0;
      _hits = 0;
      _misses = 0;
      _isFinished = false;
      for (final ctrl in _flipControllers) {
        if (ctrl.state?.isFront == false) ctrl.toggleCard();
      }
    });
  }
}

// ── Widgets auxiliares ────────────────────────────────

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.text,
    required this.label,
    required this.color,
    required this.textColor,
  });
  final String text;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final contentStyle = TextStyle(
      color: textColor,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.4,
    );

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Etiqueta superior
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Contenido: scrollable para acomodar matrices grandes
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: MathText(
                    text,
                    textStyle: contentStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$current / $total',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 6),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onMiss, required this.onHit});
  final VoidCallback onMiss;
  final VoidCallback onHit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SwipeButton(
            icon: Icons.close,
            label: 'Error',
            color: Colors.red,
            onTap: onMiss,
          ),
          _SwipeButton(
            icon: Icons.check,
            label: 'Acierto',
            color: Colors.green,
            onTap: onHit,
          ),
        ],
      ),
    );
  }
}

class _SwipeButton extends StatelessWidget {
  const _SwipeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SessionCounter extends StatelessWidget {
  const _SessionCounter({required this.hits, required this.misses});
  final int hits;
  final int misses;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check, size: 16, color: Colors.green[600]),
        Text(' $hits  ', style: TextStyle(color: Colors.green[600])),
        Icon(Icons.close, size: 16, color: Colors.red[600]),
        Text(' $misses', style: TextStyle(color: Colors.red[600])),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
