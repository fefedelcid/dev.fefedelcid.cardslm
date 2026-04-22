// lib/views/widgets/latex_keyboard.dart

import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Modelo interno
// ──────────────────────────────────────────────────────────────────────────────

class _Simbolo {
  /// Texto visible en el botón.
  final String etiqueta;

  /// LaTeX que se inserta en el campo.
  final String latex;

  /// Cuántos caracteres desde el final retrocede el cursor tras insertar.
  /// 0 = el cursor queda al final del texto insertado.
  final int offsetDesdeFin;

  const _Simbolo(this.etiqueta, this.latex, [this.offsetDesdeFin = 0]);
}

class _Categoria {
  final String nombre;
  final List<_Simbolo> simbolos;
  const _Categoria(this.nombre, this.simbolos);
}

// ──────────────────────────────────────────────────────────────────────────────
// Catálogos de símbolos
// ──────────────────────────────────────────────────────────────────────────────

// Básico -----------------------------------------------------------------------
// offsetDesdeFin calculado para que el cursor quede dentro del primer {…}
// o [ ] cuando el símbolo tiene argumentos.
//
// Ejemplos:
//   \frac{}{}  → 9 chars; cursor tras \frac{ (pos 6) → desde fin: 3
//   \sqrt{}    → 7 chars; cursor tras \sqrt{ (pos 6) → desde fin: 1
//   \sqrt[]{}  → 9 chars; cursor dentro [] (pos 7)  → desde fin: 2
//   ^{}        → 3 chars; cursor en pos 2           → desde fin: 1
//   {}         → 2 chars; cursor en pos 1           → desde fin: 1
//   $$         → 2 chars; cursor en pos 1           → desde fin: 1
//   $$$$       → 4 chars; cursor en pos 2           → desde fin: 2
//   \left(\right) → 13 chars; cursor en pos 6       → desde fin: 7

const _kBasico = <_Simbolo>[
  _Simbolo(r'$·$', r'$$', 1), // delimitador inline
  _Simbolo(r'$$·$$', r'$$$$', 2), // delimitador display
  _Simbolo('a/b', r'\frac{}{}', 3),
  _Simbolo('√x', r'\sqrt{}', 1),
  _Simbolo('ⁿ√x', r'\sqrt[]{}', 2), // cursor dentro de []
  _Simbolo('xⁿ', r'^{}', 1),
  _Simbolo('xₙ', r'_{}', 1),
  _Simbolo('{·}', r'{}', 1),
  _Simbolo('·', r'\cdot '),
  _Simbolo('×', r'\times '),
  _Simbolo('÷', r'\div '),
  _Simbolo('±', r'\pm '),
  _Simbolo('∓', r'\mp '),
  _Simbolo('∞', r'\infty '),
  _Simbolo('( )', r'\left(\right)', 7),
  _Simbolo('[ ]', r'\left[\right]', 7),
  _Simbolo('| |', r'\left|\right|', 7),
  _Simbolo('‖ ‖', r'\left\|\right\|', 8),
  _Simbolo('⌊ ⌋', r'\lfloor\rfloor', 7),
  _Simbolo('⌈ ⌉', r'\lceil\rceil', 6),
];

// Griegos ----------------------------------------------------------------------
const _kGriegos = <_Simbolo>[
  _Simbolo('α', r'\alpha '),
  _Simbolo('β', r'\beta '),
  _Simbolo('γ', r'\gamma '),
  _Simbolo('δ', r'\delta '),
  _Simbolo('ε', r'\epsilon '),
  _Simbolo('ζ', r'\zeta '),
  _Simbolo('η', r'\eta '),
  _Simbolo('θ', r'\theta '),
  _Simbolo('ι', r'\iota '),
  _Simbolo('κ', r'\kappa '),
  _Simbolo('λ', r'\lambda '),
  _Simbolo('μ', r'\mu '),
  _Simbolo('ν', r'\nu '),
  _Simbolo('ξ', r'\xi '),
  _Simbolo('π', r'\pi '),
  _Simbolo('ρ', r'\rho '),
  _Simbolo('σ', r'\sigma '),
  _Simbolo('τ', r'\tau '),
  _Simbolo('υ', r'\upsilon '),
  _Simbolo('φ', r'\phi '),
  _Simbolo('χ', r'\chi '),
  _Simbolo('ψ', r'\psi '),
  _Simbolo('ω', r'\omega '),
  _Simbolo('Γ', r'\Gamma '),
  _Simbolo('Δ', r'\Delta '),
  _Simbolo('Θ', r'\Theta '),
  _Simbolo('Λ', r'\Lambda '),
  _Simbolo('Ξ', r'\Xi '),
  _Simbolo('Π', r'\Pi '),
  _Simbolo('Σ', r'\Sigma '),
  _Simbolo('Υ', r'\Upsilon '),
  _Simbolo('Φ', r'\Phi '),
  _Simbolo('Ψ', r'\Psi '),
  _Simbolo('Ω', r'\Omega '),
];

// Operadores y funciones -------------------------------------------------------
// \begin{pmatrix}  \end{pmatrix}  → 31 chars; cursor en pos 16 → desde fin: 15
// \begin{bmatrix}  \end{bmatrix}  → igual
// \begin{vmatrix}  \end{vmatrix}  → igual
// \begin{cases}  \end{cases}      → 27 chars; cursor en pos 14 → desde fin: 13
// \langle\rangle                  → 14 chars; cursor en pos 7  → desde fin: 7
const _kOperadores = <_Simbolo>[
  _Simbolo('∑', r'\sum'),
  _Simbolo('∫', r'\int'),
  _Simbolo('∬', r'\iint'),
  _Simbolo('∭', r'\iiint'),
  _Simbolo('∮', r'\oint'),
  _Simbolo('∏', r'\prod'),
  _Simbolo('lim', r'\lim'),
  _Simbolo('∂', r'\partial '),
  _Simbolo('∇', r'\nabla '),
  _Simbolo('∀', r'\forall '),
  _Simbolo('∃', r'\exists '),
  _Simbolo('∄', r'\nexists '),
  _Simbolo('∅', r'\emptyset '),
  _Simbolo('log', r'\log'),
  _Simbolo('ln', r'\ln'),
  _Simbolo('sin', r'\sin'),
  _Simbolo('cos', r'\cos'),
  _Simbolo('tan', r'\tan'),
  _Simbolo('max', r'\max'),
  _Simbolo('min', r'\min'),
  _Simbolo('det', r'\det'),
  _Simbolo('⟨·⟩', r'\langle\rangle', 7),
  _Simbolo('mat()', r'\begin{pmatrix}  \end{pmatrix}', 15),
  _Simbolo('mat[]', r'\begin{bmatrix}  \end{bmatrix}', 15),
  _Simbolo('mat|)', r'\begin{vmatrix}  \end{vmatrix}', 15),
  _Simbolo('cases', r'\begin{cases}  \end{cases}', 13),
  _Simbolo('align', r'\begin{aligned}  \end{aligned}', 15),
];

// Relaciones -------------------------------------------------------------------
const _kRelaciones = <_Simbolo>[
  _Simbolo('≠', r'\neq '),
  _Simbolo('≤', r'\leq '),
  _Simbolo('≥', r'\geq '),
  _Simbolo('≪', r'\ll '),
  _Simbolo('≫', r'\gg '),
  _Simbolo('≈', r'\approx '),
  _Simbolo('≡', r'\equiv '),
  _Simbolo('~', r'\sim '),
  _Simbolo('∝', r'\propto '),
  _Simbolo('∈', r'\in '),
  _Simbolo('∉', r'\notin '),
  _Simbolo('⊂', r'\subset '),
  _Simbolo('⊃', r'\supset '),
  _Simbolo('⊆', r'\subseteq '),
  _Simbolo('⊇', r'\supseteq '),
  _Simbolo('∪', r'\cup '),
  _Simbolo('∩', r'\cap '),
  _Simbolo('∧', r'\land '),
  _Simbolo('∨', r'\lor '),
  _Simbolo('¬', r'\lnot '),
  _Simbolo('⊕', r'\oplus '),
  _Simbolo('⊗', r'\otimes '),
];

// Flechas ----------------------------------------------------------------------
const _kFlechas = <_Simbolo>[
  _Simbolo('→', r'\to '),
  _Simbolo('←', r'\leftarrow '),
  _Simbolo('↔', r'\leftrightarrow '),
  _Simbolo('⇒', r'\Rightarrow '),
  _Simbolo('⇐', r'\Leftarrow '),
  _Simbolo('⇔', r'\Leftrightarrow '),
  _Simbolo('↑', r'\uparrow '),
  _Simbolo('↓', r'\downarrow '),
  _Simbolo('↕', r'\updownarrow '),
  _Simbolo('⟶', r'\longrightarrow '),
  _Simbolo('⟵', r'\longleftarrow '),
  _Simbolo('⟺', r'\Longleftrightarrow '),
  _Simbolo('↦', r'\mapsto '),
  _Simbolo('↗', r'\nearrow '),
  _Simbolo('↘', r'\searrow '),
  _Simbolo('↙', r'\swarrow '),
  _Simbolo('↖', r'\nwarrow '),
];

// Catálogo completo ------------------------------------------------------------
const _kCategorias = <_Categoria>[
  _Categoria('Básico', _kBasico),
  _Categoria('Griegos', _kGriegos),
  _Categoria('Operadores', _kOperadores),
  _Categoria('Relaciones', _kRelaciones),
  _Categoria('Flechas', _kFlechas),
];

// ──────────────────────────────────────────────────────────────────────────────
// Widget principal
// ──────────────────────────────────────────────────────────────────────────────

/// Panel de teclado LaTeX que inserta símbolos en [controlador] en la posición
/// actual del cursor (o reemplaza la selección activa).
///
/// Envuelto en [ExcludeFocus] desde [CardFormScreen] para que los botones
/// no roben el foco del campo de texto activo.
class LatexKeyboard extends StatelessWidget {
  /// Controlador del campo que está actualmente enfocado.
  final TextEditingController? controlador;

  const LatexKeyboard({super.key, this.controlador});

  // ---------------------------------------------------------------------------
  // Lógica de inserción
  // ---------------------------------------------------------------------------

  void _insertar(_Simbolo simbolo) {
    final ctrl = controlador;
    if (ctrl == null) return;

    final texto = ctrl.text;
    final sel = ctrl.selection;

    // Si la selección no es válida, insertar al final del texto.
    final inicio = sel.isValid ? sel.start : texto.length;
    final fin = sel.isValid ? sel.end : texto.length;

    final nuevoTexto = texto.replaceRange(inicio, fin, simbolo.latex);
    final posCursor = inicio + simbolo.latex.length - simbolo.offsetDesdeFin;

    ctrl.value = TextEditingValue(
      text: nuevoTexto,
      selection: TextSelection.collapsed(
        offset: posCursor.clamp(0, nuevoTexto.length),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: _kCategorias.length,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Barra de tabs ──────────────────────────────────────────────────
          Container(
            color: colorScheme.surfaceContainerHighest,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: [for (final cat in _kCategorias) Tab(text: cat.nombre)],
            ),
          ),
          // ── Contenido de cada categoría ────────────────────────────────────
          SizedBox(
            height: 164,
            child: TabBarView(
              children: [
                for (final cat in _kCategorias)
                  _GridSimbolos(simbolos: cat.simbolos, onTap: _insertar),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Grid de botones
// ──────────────────────────────────────────────────────────────────────────────

class _GridSimbolos extends StatelessWidget {
  final List<_Simbolo> simbolos;
  final void Function(_Simbolo) onTap;

  const _GridSimbolos({required this.simbolos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 68,
        mainAxisExtent: 40,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: simbolos.length,
      itemBuilder: (_, i) => _BotonSimbolo(simbolo: simbolos[i], onTap: onTap),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Botón individual
// ──────────────────────────────────────────────────────────────────────────────

class _BotonSimbolo extends StatelessWidget {
  final _Simbolo simbolo;
  final void Function(_Simbolo) onTap;

  const _BotonSimbolo({required this.simbolo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 1,
      shadowColor: colorScheme.shadow.withOpacity(0.4),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => onTap(simbolo),
        child: Center(
          child: Text(
            simbolo.etiqueta,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
