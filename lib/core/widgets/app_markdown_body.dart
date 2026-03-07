import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:liankhawpui/core/utils/markdown_content_utils.dart';
import 'package:markdown/markdown.dart' as md;

const _justifyTag = 'justify';
final RegExp _justifyStartPattern = RegExp(r'^\s*:::justify\s*$');
final RegExp _justifyEndPattern = RegExp(r'^\s*:::\s*$');

class AppMarkdownBody extends StatelessWidget {
  final String data;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;
  final MarkdownTapLinkCallback? onTapLink;

  const AppMarkdownBody({
    super.key,
    required this.data,
    this.selectable = false,
    this.styleSheet,
    this.onTapLink,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: styleSheet,
      onTapLink: onTapLink,
      blockSyntaxes: const <md.BlockSyntax>[_JustifyBlockSyntax()],
      builders: <String, MarkdownElementBuilder>{
        _justifyTag: _JustifyMarkdownBuilder(selectable: selectable),
      },
    );
  }
}

class _JustifyBlockSyntax extends md.BlockSyntax {
  const _JustifyBlockSyntax();

  @override
  RegExp get pattern => _justifyStartPattern;

  @override
  md.Node parse(md.BlockParser parser) {
    parser.advance();

    final buffer = StringBuffer();
    while (!parser.isDone &&
        !_justifyEndPattern.hasMatch(parser.current.content)) {
      buffer.writeln(parser.current.content);
      parser.advance();
    }

    if (!parser.isDone) {
      parser.advance();
    }

    return md.Element(_justifyTag, <md.Node>[
      md.Text(buffer.toString().trim()),
    ]);
  }
}

class _JustifyMarkdownBuilder extends MarkdownElementBuilder {
  final bool selectable;

  _JustifyMarkdownBuilder({required this.selectable});

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final paragraphs = element.textContent
        .split(RegExp(r'\n\s*\n'))
        .map(
          (paragraph) => markdownToPlainText(paragraph.replaceAll('\n', ' ')),
        )
        .where((paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);

    final textStyle =
        preferredStyle ??
        parentStyle ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle();

    if (paragraphs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          selectable
              ? SelectableText(
                  paragraphs[i],
                  textAlign: TextAlign.justify,
                  style: textStyle,
                )
              : Text(
                  paragraphs[i],
                  textAlign: TextAlign.justify,
                  style: textStyle,
                ),
          if (i < paragraphs.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
