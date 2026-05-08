import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/atom-one-light.dart';
import '../providers/study_provider.dart';
import 'package:markdown/markdown.dart' as md;

class ChatBubble extends ConsumerWidget {
  final String id;
  final String query;
  final String response;
  final DateTime timestamp;
  final bool isStreaming;
  final bool isLast;

  const ChatBubble({
    super.key,
    required this.id,
    required this.query,
    required this.response,
    required this.timestamp,
    this.isStreaming = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User Query
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.fromLTRB(40, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withAlpha(200),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                query,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // AI Response
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 40, 8),
              padding: const EdgeInsets.all(2), // For gradient border effect
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withAlpha(100),
                    colorScheme.secondary.withAlpha(100),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.auto_awesome,
                              size: 16, color: colorScheme.primary),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'AI Assistant',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 0.5),
                    if (response.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Assistant is thinking...',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      MarkdownBody(
                        data: response + (isStreaming ? ' █' : ''),
                        selectable: true,
                        builders: {
                          'code': CodeElementBuilder(isDark: isDark),
                        },
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: colorScheme.onSurface,
                            height: 1.6,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                          h1: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            height: 1.4,
                          ),
                          h2: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            height: 1.4,
                          ),
                          h3: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            height: 1.4,
                          ),
                          listBullet: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          code: TextStyle(
                            backgroundColor: colorScheme.primary.withAlpha(20),
                            color: colorScheme.primary,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: isDark ? Colors.black38 : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: colorScheme.primary.withAlpha(40)),
                          ),
                          blockquote: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                            fontSize: 15,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            border: Border(
                                left: BorderSide(
                                    color: colorScheme.primary, width: 4)),
                            color: colorScheme.primary.withAlpha(15),
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(8)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM d, h:mm a').format(timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant.withAlpha(150),
                          ),
                        ),
                        Row(
                          children: [
                            _ActionButton(
                              icon: Icons.translate,
                              onTap: () => _showTranslateDialog(context, ref),
                            ),
                            _ActionButton(
                              icon: Icons.copy,
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: response));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Copied to clipboard'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                );
                              },
                            ),
                            _ActionButton(
                              icon: Icons.share,
                              onTap: () => Share.share(response),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTranslateDialog(BuildContext context, WidgetRef ref) {
    final languages = [
      'Arabic',
      'Spanish',
      'French',
      'German',
      'Chinese',
      'Japanese'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Translate to...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages
              .map((lang) => ListTile(
                    title: Text(lang),
                    onTap: () {
                      ref
                          .read(studyProvider.notifier)
                          .translateSession(id, lang);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon, size: 16),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      color: colorScheme.primary.withAlpha(180),
      onPressed: onTap,
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final bool isDark;

  CodeElementBuilder({required this.isDark});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';

    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      language = lg.substring(9);
    }

    final String textContent = element.textContent;

    if (language.isEmpty && !textContent.contains('\n')) {
      return null; // Inline code will use default style
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HighlightView(
          textContent.trim(),
          language: language,
          theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
          padding: const EdgeInsets.all(12),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
