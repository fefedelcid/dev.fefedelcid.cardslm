import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/card.dart';
import '../../providers/card_provider.dart';
import '../widgets/math_text.dart';

class CardFormScreen extends StatefulWidget {
  const CardFormScreen({super.key, required this.deckId, this.card});
  final int deckId;
  final FlashCard? card;

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _frontCtrl;
  late final TextEditingController _backCtrl;
  bool _isSaving = false;

  bool get _isEditing => widget.card != null;

  @override
  void initState() {
    super.initState();
    _frontCtrl = TextEditingController(text: widget.card?.front ?? '');
    _backCtrl = TextEditingController(text: widget.card?.back ?? '');
  }

  @override
  void dispose() {
    _frontCtrl.dispose();
    _backCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar tarjeta' : 'Nueva tarjeta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardPreview(front: _frontCtrl.text, back: _backCtrl.text),
              const SizedBox(height: 24),
              TextFormField(
                controller: _frontCtrl,
                decoration: const InputDecoration(
                  labelText: 'Frente *',
                  hintText: 'Texto o LaTeX: \$\\frac{a}{b}\$ o \$\$...\$\$',
                  helperText:
                      'Usa \$...\$ para fórmulas inline y \$\$...\$\$ para display.',
                  helperMaxLines: 2,
                  prefixIcon: Icon(Icons.flip_to_front),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El frente es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _backCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dorso *',
                  hintText: 'Texto o LaTeX: \$\\frac{a}{b}\$ o \$\$...\$\$',
                  helperText:
                      'Usa \$...\$ para fórmulas inline y \$\$...\$\$ para display.',
                  helperMaxLines: 2,
                  prefixIcon: Icon(Icons.flip_to_back),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El dorso es obligatorio'
                    : null,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isEditing ? 'Guardar cambios' : 'Crear tarjeta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<CardProvider>();

    if (_isEditing) {
      await provider.updateCard(
        widget.card!.copyWith(
          front: _frontCtrl.text.trim(),
          back: _backCtrl.text.trim(),
        ),
      );
    } else {
      await provider.addCard(
        FlashCard(
          deckId: widget.deckId,
          front: _frontCtrl.text.trim(),
          back: _backCtrl.text.trim(),
        ),
      );
    }

    if (!mounted) return;

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
      provider.clearError();
    } else {
      Navigator.pop(context);
    }

    setState(() => _isSaving = false);
  }
}

// ── Vista previa de la tarjeta ─────────────────────────

class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.front, required this.back});
  final String front;
  final String back;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _PreviewSide(
              label: 'PREGUNTA',
              text: front.isEmpty ? '...' : front,
              color: colorScheme.primaryContainer,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Icon(Icons.arrow_forward, size: 20),
          ),
          Expanded(
            child: _PreviewSide(
              label: 'RESPUESTA',
              text: back.isEmpty ? '...' : back,
              color: colorScheme.secondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSide extends StatelessWidget {
  const _PreviewSide({
    required this.label,
    required this.text,
    required this.color,
  });
  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          // La altura máxima acota el preview; el contenido se recorta si es
          // muy grande (matrices extensas se verán completas en study_screen).
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: MathText(
                text,
                textStyle: const TextStyle(fontSize: 12),
                textAlign: TextAlign.start,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
