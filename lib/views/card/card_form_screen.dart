// lib/views/card_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/card.dart' as model;
import '../../providers/card_provider.dart';
import '../widgets/math_text.dart';
import '../widgets/latex_keyboard.dart';

class CardFormScreen extends StatefulWidget {
  final int deckId;

  /// `null` → crear nueva tarjeta. Non-null → editar tarjeta existente.
  final model.FlashCard? card;

  const CardFormScreen({super.key, required this.deckId, this.card});

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _ctrlFrente;
  late final TextEditingController _ctrlDorso;
  late final FocusNode _focusFrente;
  late final FocusNode _focusDorso;

  /// Controlador del campo actualmente enfocado; se pasa al teclado LaTeX.
  /// Por defecto apunta al frente hasta que el usuario enfoque otro campo.
  TextEditingController? _controladorActivo;

  bool _mostrarTeclado = false;
  bool _guardando = false;

  // ---------------------------------------------------------------------------
  // Ciclo de vida
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _ctrlFrente = TextEditingController(text: widget.card?.front ?? '');
    _ctrlDorso = TextEditingController(text: widget.card?.back ?? '');
    _focusFrente = FocusNode();
    _focusDorso = FocusNode();

    _controladorActivo = _ctrlFrente;

    // Actualizar el controlador activo cuando el usuario cambia de campo.
    _focusFrente.addListener(() {
      if (_focusFrente.hasFocus) {
        setState(() => _controladorActivo = _ctrlFrente);
      }
    });
    _focusDorso.addListener(() {
      if (_focusDorso.hasFocus) setState(() => _controladorActivo = _ctrlDorso);
    });
  }

  @override
  void dispose() {
    _ctrlFrente.dispose();
    _ctrlDorso.dispose();
    _focusFrente.dispose();
    _focusDorso.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Acción de guardado
  // ---------------------------------------------------------------------------

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      final provider = context.read<CardProvider>();
      if (widget.card == null) {
        await provider.addCard(
          model.FlashCard(
            id: 0,
            deckId: widget.deckId,
            front: _ctrlFrente.text.trim(),
            back: _ctrlDorso.text.trim(),
          ),
        );
      } else {
        await provider.updateCard(
          model.FlashCard(
            id: widget.card!.id,
            deckId: widget.deckId,
            front: _ctrlFrente.text.trim(),
            back: _ctrlDorso.text.trim(),
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error al guardar tarjeta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la tarjeta')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.card != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar tarjeta' : 'Nueva tarjeta'),
        actions: [
          // ── Toggle teclado LaTeX ─────────────────────────────────────────
          IconButton(
            tooltip: _mostrarTeclado
                ? 'Ocultar teclado LaTeX'
                : 'Teclado LaTeX',
            icon: Icon(
              Icons.functions,
              // El ícono se colorea con el color primario cuando está activo.
              color: _mostrarTeclado
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () => setState(() => _mostrarTeclado = !_mostrarTeclado),
          ),
          // ── Guardar ──────────────────────────────────────────────────────
          IconButton(
            tooltip: 'Guardar',
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _guardando ? null : _guardar,
          ),
        ],
      ),
      // resizeToAvoidBottomInset: true (valor por defecto) — el Scaffold empuja
      // el contenido hacia arriba cuando aparece el teclado del sistema.
      body: Column(
        children: [
          // ── Formulario (scrollable) ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Campo Frente ───────────────────────────────────────
                    TextFormField(
                      controller: _ctrlFrente,
                      focusNode: _focusFrente,
                      decoration: const InputDecoration(
                        labelText: 'Frente',
                        helperText:
                            r'Usa $…$ para LaTeX en línea o $$…$$ para bloque',
                        helperMaxLines: 2,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'El frente no puede estar vacío'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Campo Dorso ────────────────────────────────────────
                    TextFormField(
                      controller: _ctrlDorso,
                      focusNode: _focusDorso,
                      decoration: const InputDecoration(
                        labelText: 'Dorso',
                        helperText:
                            r'Usa $…$ para LaTeX en línea o $$…$$ para bloque',
                        helperMaxLines: 2,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'El dorso no puede estar vacío'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // ── Vista previa ───────────────────────────────────────
                    Text(
                      'Vista previa',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: Listenable.merge([_ctrlFrente, _ctrlDorso]),
                      builder: (_, _) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PreviewSide(
                              etiqueta: 'Frente',
                              texto: _ctrlFrente.text,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PreviewSide(
                              etiqueta: 'Dorso',
                              texto: _ctrlDorso.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Espacio extra para que el último elemento no quede
                    // tapado por el teclado LaTeX cuando está abierto.
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // ── Teclado LaTeX (panel inferior, fuera del scroll) ─────────────
          if (_mostrarTeclado)
            // ExcludeFocus evita que los botones del teclado roben el foco
            // del campo de texto activo al ser pulsados.
            ExcludeFocus(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: LatexKeyboard(controlador: _controladorActivo),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Vista previa de un lado de la tarjeta
// ──────────────────────────────────────────────────────────────────────────────

class _PreviewSide extends StatelessWidget {
  final String etiqueta;
  final String texto;

  const _PreviewSide({required this.etiqueta, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: texto.trim().isEmpty
                  ? Text(
                      'Sin contenido',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    )
                  : MathText(texto),
            ),
          ),
        ),
      ],
    );
  }
}
