import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../providers/deck_provider.dart';

class DeckFormScreen extends StatefulWidget {
  const DeckFormScreen({super.key, this.deck});

  // Si deck es null → modo creación. Si tiene valor → modo edición.
  final Deck? deck;

  @override
  State<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends State<DeckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _isSaving = false;

  bool get _isEditing => widget.deck != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.deck?.name ?? '');
    _descCtrl = TextEditingController(text: widget.deck?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar mazo' : 'Nuevo mazo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Vocabulario inglés',
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej: Nivel B2 - Sustantivos',
                  prefixIcon: Icon(Icons.notes),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
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
                label: Text(_isEditing ? 'Guardar cambios' : 'Crear mazo'),
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

    final provider = context.read<DeckProvider>();

    if (_isEditing) {
      await provider.updateDeck(
        widget.deck!.copyWith(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
        ),
      );
    } else {
      await provider.addDeck(
        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );
    }

    if (!mounted) return;

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
    } else {
      Navigator.pop(context);
    }

    setState(() => _isSaving = false);
  }
}
