import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renderiza texto con soporte LaTeX usando los delimitadores estándar:
///
///   - `$$...$$`  → modo display (centrado, tamaño grande; ideal para matrices)
///   - `$...$`    → modo inline (en línea con el texto)
///
/// El contenido fuera de delimitadores se renderiza como [Text] normal.
/// Si el parser falla para un segmento, muestra el LaTeX crudo en rojo.
///
/// Ejemplo:
/// ```dart
/// MathText(
///   r'La fórmula $\frac{a}{b}$ es importante.',
///   textStyle: TextStyle(fontSize: 18),
/// )
/// ```
class MathText extends StatelessWidget {
  const MathText(
    this.data, {
    super.key,
    this.textStyle,
    this.textAlign = TextAlign.center,
  });

  final String data;
  final TextStyle? textStyle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = textStyle ?? DefaultTextStyle.of(context).style;
    final segments = _parse(data);

    // Caso simple: un único segmento
    if (segments.length == 1) {
      final seg = segments.first;
      return seg.isMath
          ? _mathWidget(seg, effectiveStyle)
          : Text(seg.content, style: effectiveStyle, textAlign: textAlign);
    }

    // Caso mixto: combina Text y Math en un Wrap
    return Wrap(
      alignment: _wrapAlignment(textAlign),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: segments.map((seg) {
        return seg.isMath
            ? _mathWidget(seg, effectiveStyle)
            : Text(seg.content, style: effectiveStyle);
      }).toList(),
    );
  }

  Widget _mathWidget(_Segment seg, TextStyle style) {
    return Math.tex(
      seg.content,
      mathStyle: seg.isDisplay ? MathStyle.display : MathStyle.text,
      textStyle: style,
      onErrorFallback: (err) {
        debugPrint('MathText parse error: ${err.message}');
        return Text(
          seg.content,
          style: style.copyWith(
            color: Colors.red[400],
            fontStyle: FontStyle.italic,
          ),
        );
      },
    );
  }

  WrapAlignment _wrapAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return WrapAlignment.center;
      case TextAlign.end:
      case TextAlign.right:
        return WrapAlignment.end;
      default:
        return WrapAlignment.start;
    }
  }

  /// Divide [data] en segmentos de texto plano y LaTeX.
  /// El patrón reconoce primero `$$...$$` y luego `$...$` (orden importante).
  static List<_Segment> _parse(String data) {
    final segments = <_Segment>[];
    // dotAll: true → el punto también captura saltos de línea (necesario para matrices)
    final pattern = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$', dotAll: true);
    int lastEnd = 0;

    for (final match in pattern.allMatches(data)) {
      if (match.start > lastEnd) {
        segments.add(_Segment(data.substring(lastEnd, match.start)));
      }
      final isDisplay = match.group(1) != null;
      final content = isDisplay ? match.group(1)! : match.group(2)!;
      segments.add(_Segment(content, isMath: true, isDisplay: isDisplay));
      lastEnd = match.end;
    }

    if (lastEnd < data.length) {
      segments.add(_Segment(data.substring(lastEnd)));
    }

    return segments.isEmpty ? [_Segment(data)] : segments;
  }
}

class _Segment {
  const _Segment(this.content, {this.isMath = false, this.isDisplay = false});
  final String content;
  final bool isMath;
  final bool isDisplay;
}
