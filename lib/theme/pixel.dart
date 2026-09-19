import 'package:flutter/material.dart';

/// Paleta e estilos do tema pixel-art 8-bit.
class Px {
  Px._();

  static const bg = Color(0xFF0A0F1F);
  static const header = Color(0xFF0D1430);
  static const panel = Color(0xFF121A33);
  static const panelDark = Color(0xFF0A1226);
  static const line = Color(0xFF33437A);
  static const line2 = Color(0xFF1E2850);

  static const cyan = Color(0xFF00F0FF);
  static const purple = Color(0xFFA855F7);
  static const violet = Color(0xFFC084FC);
  static const amber = Color(0xFFFFB020);
  static const green = Color(0xFF3DDC84);
  static const red = Color(0xFFFF4D5E);
  static const orange = Color(0xFFFF8A3D);
  static const yellow = Color(0xFFFFE14D);
  static const blue = Color(0xFF38BDF8);

  static const text = Color(0xFFE6EAFF);
  static const muted = Color(0xFF9FB0E0);
  static const dim = Color(0xFF6A76A8);

  // Cores por gravidade (mesmas do protótipo).
  static const critico = red;
  static const bloqueado = orange;
  static const medio = yellow;
  static const baixo = blue;
  static const melhoria = purple;

  /// Fonte de destaque (títulos, botões, rótulos).
  static TextStyle p(double size, {Color color = text, double height = 1.5}) =>
      TextStyle(fontFamily: 'PressStart', fontSize: size, color: color, height: height);

  /// Fonte de leitura e números (tempos, textos corridos).
  static TextStyle v(double size, {Color color = text, double height = 1.0}) =>
      TextStyle(fontFamily: 'VT323', fontSize: size, color: color, height: height);

  static List<BoxShadow> ring(Color c, {double w = 4}) => [
        BoxShadow(color: c, offset: Offset(0, -w)),
        BoxShadow(color: c, offset: Offset(0, w)),
        BoxShadow(color: c, offset: Offset(-w, 0)),
        BoxShadow(color: c, offset: Offset(w, 0)),
      ];

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
    ).copyWith(surface: bg, primary: cyan, secondary: purple, error: red);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'VT323',
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      splashFactory: NoSplash.splashFactory,
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'VT323', bodyColor: text, displayColor: text),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panel,
        contentTextStyle: v(20),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}

enum PxVariant { green, purple, red, cyan, dark, amber }

class _VariantColors {
  const _VariantColors(this.fill, this.shade, this.high, this.fg);
  final Color fill, shade, high, fg;
}

const _variants = {
  PxVariant.green: _VariantColors(Color(0xFF3DDC84), Color(0xFF1E9B59), Color(0xFF8FF0B8), Colors.black),
  PxVariant.purple: _VariantColors(Color(0xFFA855F7), Color(0xFF6D2FB0), Color(0xFFD3A4FB), Colors.white),
  PxVariant.red: _VariantColors(Color(0xFFFF4D5E), Color(0xFFB02334), Color(0xFFFF9AA4), Colors.white),
  PxVariant.cyan: _VariantColors(Color(0xFF00F0FF), Color(0xFF0899A5), Color(0xFFA4FBFF), Colors.black),
  PxVariant.dark: _VariantColors(Color(0xFF1C2547), Color(0xFF0D1330), Color(0xFF2E3A6B), Color(0xFFE6EAFF)),
  PxVariant.amber: _VariantColors(Color(0xFFFFB020), Color(0xFFB37400), Color(0xFFFFD98A), Colors.black),
};

const _disabledColors = _VariantColors(Color(0xFF161D38), Color(0xFF0D1226), Color(0xFF1F2848), Color(0xFF6A76A8));

/// Painel com borda de pixel (cantos recortados, estilo NES).
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.border = Px.line,
    this.fill = Px.panel,
    this.padding = const EdgeInsets.all(12),
    this.margin = const EdgeInsets.all(4),
  });

  final Widget child;
  final Color border;
  final Color fill;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(color: fill, boxShadow: Px.ring(border)),
      child: child,
    );
  }
}

/// Botão 3D de pixel, com ou sem texto. Sem [onPressed], fica apagado.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.variant = PxVariant.dark,
    this.height = 44,
    this.width,
    this.fontSize = 9,
    this.iconSize = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.tooltip,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PxVariant variant;
  final double height;
  final double? width;
  final double fontSize;
  final double iconSize;
  final EdgeInsets padding;
  final String? tooltip;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final c = enabled ? _variants[widget.variant]! : _disabledColors;
    final content = <Widget>[
      if (widget.icon != null) Icon(widget.icon, size: widget.iconSize, color: c.fg),
      if (widget.icon != null && widget.label != null) const SizedBox(width: 6),
      if (widget.label != null)
        Flexible(
          child: Text(
            widget.label!,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Px.p(widget.fontSize, color: c.fg, height: 1),
          ),
        ),
    ];

    final button = Transform.translate(
      offset: Offset(0, _down && enabled ? 2 : 0),
      child: Container(
        height: widget.height,
        width: widget.width,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: c.fill,
          border: Border(
            top: BorderSide(color: c.high, width: 3),
            left: BorderSide(color: c.high, width: 3),
            bottom: BorderSide(color: c.shade, width: 3),
            right: BorderSide(color: c.shade, width: 3),
          ),
          boxShadow: Px.ring(Colors.black, w: 3),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: content),
      ),
    );

    final core = Semantics(
      button: true,
      enabled: enabled,
      label: widget.tooltip == null ? widget.label : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTap: widget.onPressed,
          child: Padding(padding: const EdgeInsets.all(3), child: button),
        ),
      ),
    );
    return widget.tooltip == null ? core : Tooltip(message: widget.tooltip!, child: core);
  }
}

/// Selo pequeno (status, categoria, gravidade).
class PixelBadge extends StatelessWidget {
  const PixelBadge(this.text, {super.key, this.bg = Px.line2, this.fg = Px.text, this.ring, this.onTap, this.fontSize = 8, this.trailing});

  final String text;
  final Color bg;
  final Color fg;
  final Color? ring;
  final VoidCallback? onTap;
  final double fontSize;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [BoxShadow(color: ring ?? Colors.black, spreadRadius: 2)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: Px.p(fontSize, color: fg, height: 1)),
          if (trailing != null) ...[const SizedBox(width: 4), Icon(trailing, size: 12, color: fg)],
        ],
      ),
    );
    if (onTap == null) return box;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: box);
  }
}

/// Chip selecionável (filtros, atalhos de minutos, projetos).
class PixelChip extends StatelessWidget {
  const PixelChip(this.label, {super.key, this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = selected ? Px.cyan : Px.line;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Opacity(
            opacity: enabled ? 1 : .5,
            child: Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF062A33) : Px.panelDark,
                boxShadow: [BoxShadow(color: color, spreadRadius: 2)],
              ),
              child: Text(label, style: Px.p(8, color: selected ? Px.cyan : const Color(0xFFC8D2FF), height: 1)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Checkbox quadrado de pixel.
class PixelCheckbox extends StatelessWidget {
  const PixelCheckbox({super.key, required this.value, this.onChanged, this.label});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      checked: value,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onChanged!(!value) : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: value ? Px.green : Px.panelDark,
                boxShadow: [BoxShadow(color: enabled ? Px.cyan : Px.line, spreadRadius: 2)],
              ),
              child: value ? const Icon(Icons.check, size: 20, color: Colors.black) : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra de progresso quadrada.
class PixelProgressBar extends StatelessWidget {
  const PixelProgressBar({super.key, required this.value, this.color = Px.cyan, this.height = 12});

  final double value; // 0..1
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.all(2),
      decoration: const BoxDecoration(color: Px.panelDark, boxShadow: [BoxShadow(color: Px.line2, spreadRadius: 2)]),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(color: color),
      ),
    );
  }
}

/// Campo de texto de pixel.
class PixelTextField extends StatelessWidget {
  const PixelTextField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.icon,
    this.enabled = true,
    this.autofocus = false,
    this.ringColor = Px.line,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final IconData? icon;
  final bool enabled;
  final bool autofocus;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Px.panelDark, boxShadow: Px.ring(ringColor)),
      child: Row(
        children: [
          if (icon != null)
            Padding(padding: const EdgeInsets.only(left: 12), child: Icon(icon, size: 18, color: Px.cyan)),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              keyboardType: keyboardType,
              enabled: enabled,
              autofocus: autofocus,
              cursorColor: Px.cyan,
              cursorWidth: 3,
              style: Px.p(9, color: Px.cyan, height: 1.2),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: Px.p(9, color: Px.dim, height: 1.2),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Janela de pixel (substitui o AlertDialog padrão).
Future<T?> showPixelDialog<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: const Color(0xCC02040C),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: const RoundedRectangleBorder(),
      child: PixelPanel(
        border: Px.cyan,
        padding: const EdgeInsets.all(16),
        child: builder(ctx),
      ),
    ),
  );
}

/// Confirmação padrão (excluir etc.).
Future<bool> pixelConfirm(BuildContext context, String message, {String confirmLabel = 'EXCLUIR'}) async {
  final ok = await showPixelDialog<bool>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: Px.v(22, height: 1.1)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: PixelButton(label: 'CANCELAR', fontSize: 8, onPressed: () => Navigator.pop(ctx, false))),
            const SizedBox(width: 6),
            Expanded(
              child: PixelButton(
                label: confirmLabel,
                variant: PxVariant.red,
                fontSize: 8,
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Pede um texto (nome de projeto, etc.).
Future<String?> pixelPrompt(
  BuildContext context, {
  required String title,
  required String hint,
  String initial = '',
  String confirmLabel = 'CRIAR',
}) {
  final controller = TextEditingController(text: initial);
  return showPixelDialog<String>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Px.p(11, color: Px.cyan, height: 1.6)),
        const SizedBox(height: 12),
        PixelTextField(controller: controller, hint: hint, autofocus: true, ringColor: Px.cyan),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: PixelButton(label: 'CANCELAR', fontSize: 8, onPressed: () => Navigator.pop(ctx))),
            const SizedBox(width: 6),
            Expanded(
              child: PixelButton(
                label: confirmLabel,
                variant: PxVariant.green,
                fontSize: 8,
                onPressed: () => Navigator.pop(ctx, controller.text),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
