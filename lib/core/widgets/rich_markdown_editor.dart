import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:liankhawpui/core/services/post_attachment_service.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownEditing {
  static void insertText(
    TextEditingController controller,
    String value, {
    bool addLeadingBreak = false,
    bool addTrailingBreak = false,
  }) {
    final text = controller.text;
    final selection = controller.selection;

    final insertValue =
        '${addLeadingBreak ? '\n' : ''}$value${addTrailingBreak ? '\n' : ''}';

    if (!selection.isValid || selection.start < 0 || selection.end < 0) {
      controller.value = TextEditingValue(
        text: '$text$insertValue',
        selection: TextSelection.collapsed(offset: '$text$insertValue'.length),
      );
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final updated = text.replaceRange(start, end, insertValue);
    controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + insertValue.length),
    );
  }
}

class RichMarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;

  const RichMarkdownEditor({
    super.key,
    required this.controller,
    required this.hintText,
    this.minLines = 8,
    this.maxLines = 20,
  });

  @override
  State<RichMarkdownEditor> createState() => _RichMarkdownEditorState();
}

class _RichMarkdownEditorState extends State<RichMarkdownEditor> {
  bool _previewMode = false;
  final PostAttachmentService _attachmentService = PostAttachmentService();

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text.trim();
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _toolButton(
                icon: Icons.format_bold_rounded,
                tooltip: 'Bold',
                onTap: () => _surroundSelection('**', '**'),
              ),
              _toolButton(
                icon: Icons.format_italic_rounded,
                tooltip: 'Italic',
                onTap: () => _surroundSelection('*', '*'),
              ),
              _toolButton(
                icon: Icons.code_rounded,
                tooltip: 'Inline code',
                onTap: () => _surroundSelection('`', '`'),
              ),
              _toolButton(
                icon: Icons.title_rounded,
                tooltip: 'Heading',
                onTap: () => _prefixLines('## '),
              ),
              _toolButton(
                icon: Icons.format_list_bulleted_rounded,
                tooltip: 'Bullet list',
                onTap: () => _prefixLines('- '),
              ),
              _toolButton(
                icon: Icons.format_list_numbered_rounded,
                tooltip: 'Numbered list',
                onTap: _prefixNumberedLines,
              ),
              _toolButton(
                icon: Icons.format_quote_rounded,
                tooltip: 'Quote',
                onTap: () => _prefixLines('> '),
              ),
              _toolButton(
                icon: Icons.link_rounded,
                tooltip: 'Insert link',
                onTap: _insertLink,
              ),
              _toolButton(
                icon: _previewMode
                    ? Icons.edit_note_rounded
                    : Icons.preview_rounded,
                tooltip: _previewMode ? 'Edit markdown' : 'Preview markdown',
                onTap: () => setState(() => _previewMode = !_previewMode),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (_previewMode)
            Container(
              constraints: BoxConstraints(
                minHeight: widget.minLines * 22,
                maxHeight: widget.maxLines * 24,
              ),
              width: double.infinity,
              child: text.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Preview will appear here.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: MarkdownBody(
                        data: widget.controller.text,
                        selectable: true,
                        onTapLink: (_, href, __) async {
                          if (href == null || href.isEmpty) return;
                          final uri = await _attachmentService.resolveLaunchUri(
                            href,
                          );
                          if (uri == null) return;
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ),
            )
          else
            TextField(
              controller: widget.controller,
              minLines: widget.minLines,
              maxLines: widget.maxLines,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hintText,
              ),
            ),
        ],
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceVariant
                : AppColors.surfaceVariantLight,
          ),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }

  void _surroundSelection(String left, String right) {
    final selection = widget.controller.selection;
    final text = widget.controller.text;

    if (!selection.isValid || selection.start < 0 || selection.end < 0) {
      final placeholder = text.isEmpty ? 'text' : text;
      MarkdownEditing.insertText(widget.controller, '$left$placeholder$right');
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);
    final replacement = '$left$selectedText$right';
    final updated = text.replaceRange(start, end, replacement);

    widget.controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  void _prefixLines(String prefix) {
    final selection = widget.controller.selection;
    final text = widget.controller.text;

    if (!selection.isValid || selection.start < 0 || selection.end < 0) {
      MarkdownEditing.insertText(widget.controller, prefix);
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);
    final lines = selectedText.split('\n');
    final prefixed = lines.map((line) => '$prefix$line').join('\n');
    final updated = text.replaceRange(start, end, prefixed);
    widget.controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + prefixed.length),
    );
  }

  void _prefixNumberedLines() {
    final selection = widget.controller.selection;
    final text = widget.controller.text;

    if (!selection.isValid || selection.start < 0 || selection.end < 0) {
      MarkdownEditing.insertText(widget.controller, '1. ');
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);
    final lines = selectedText.split('\n');
    final numbered = <String>[];
    for (var i = 0; i < lines.length; i++) {
      numbered.add('${i + 1}. ${lines[i]}');
    }
    final replacement = numbered.join('\n');
    final updated = text.replaceRange(start, end, replacement);

    widget.controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  Future<void> _insertLink() async {
    final textController = TextEditingController();
    final urlController = TextEditingController(text: 'https://');
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Insert link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(labelText: 'Link text'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Insert'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      final label = textController.text.trim().isEmpty
          ? 'Link'
          : textController.text.trim();
      final href = urlController.text.trim();
      if (href.isEmpty) return;

      MarkdownEditing.insertText(
        widget.controller,
        '[$label]($href)',
        addLeadingBreak: true,
      );
    } finally {
      textController.dispose();
      urlController.dispose();
    }
  }
}
