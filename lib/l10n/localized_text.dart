import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';

import 'app_copy.dart';

export 'app_copy.dart';

class LocalizedText extends material.StatelessWidget {
  final String? data;
  final InlineSpan? textSpan;
  final material.TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final material.Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final material.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final material.Color? selectionColor;
  final bool translate;

  const LocalizedText(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    @Deprecated('Use textScaler instead.') double? textScaleFactor,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.translate = true,
  }) : textSpan = null;

  const LocalizedText.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    @Deprecated('Use textScaler instead.') double? textScaleFactor,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.translate = true,
  }) : data = null;

  @override
  material.Widget build(material.BuildContext context) {
    final activeLocale = material.Localizations.localeOf(context);
    final localizedSemantics = semanticsLabel == null
        ? null
        : translate
        ? localizeAppCopy(semanticsLabel!, activeLocale)
        : semanticsLabel;

    if (textSpan != null) {
      return material.Text.rich(
        translate ? _localizedSpan(textSpan!, activeLocale) : textSpan!,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: localizedSemantics,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }

    return material.Text(
      translate ? localizeAppCopy(data ?? '', activeLocale) : data ?? '',
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: localizedSemantics,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

InlineSpan _localizedSpan(InlineSpan span, material.Locale locale) {
  if (span is material.WidgetSpan) {
    return span;
  }
  if (span is! material.TextSpan) {
    return span;
  }

  return material.TextSpan(
    text: span.text == null ? null : localizeAppCopy(span.text!, locale),
    children: span.children
        ?.map((child) => _localizedSpan(child, locale))
        .toList(growable: false),
    style: span.style,
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: span.semanticsLabel == null
        ? null
        : localizeAppCopy(span.semanticsLabel!, locale),
    locale: span.locale,
    spellOut: span.spellOut,
  );
}

class LocalizedRichText extends material.StatelessWidget {
  final InlineSpan text;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final bool softWrap;
  final TextOverflow overflow;
  final material.TextScaler textScaler;
  final int? maxLines;
  final material.Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final SelectionRegistrar? selectionRegistrar;
  final material.Color? selectionColor;
  final bool translate;

  const LocalizedRichText({
    super.key,
    required this.text,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaler = material.TextScaler.noScaling,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.selectionRegistrar,
    this.selectionColor,
    this.translate = true,
  });

  @override
  material.Widget build(material.BuildContext context) {
    return material.RichText(
      text: translate
          ? _localizedSpan(text, material.Localizations.localeOf(context))
          : text,
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionRegistrar: selectionRegistrar,
      selectionColor: selectionColor,
    );
  }
}
