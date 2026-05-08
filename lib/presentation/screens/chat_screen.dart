import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/study_provider.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? threadId;
  final String? initialQuery;
  final bool shouldSummarize;

  const ChatScreen({
    super.key,
    this.threadId,
    this.initialQuery,
    this.shouldSummarize = false,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late final String _lockedThreadId;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _lockedThreadId = widget.threadId ?? const Uuid().v4();
    _controller.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(studyProvider.notifier).setCurrentThread(_lockedThreadId);
      if (widget.initialQuery != null) {
        if (widget.shouldSummarize) {
          ref.read(studyProvider.notifier).askAISummary(
                widget.initialQuery!,
                threadId: _lockedThreadId,
              );
        } else {
          ref.read(studyProvider.notifier).askAI(
                widget.initialQuery!,
                threadId: _lockedThreadId,
              );
        }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    ref.read(studyProvider.notifier).setCurrentThread(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // نستخدم فلتر ذكي يدعم الرسائل القديمة والجديدة
    final threadSessions = state.sessions.where((s) {
      final sThreadId = s.threadId ?? s.id;
      return sThreadId == _lockedThreadId && !s.isDeleted;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Study Chat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (state.isLoading)
              Text(
                'AI is typing...',
                style: TextStyle(
                    fontSize: 12, color: colorScheme.onPrimary.withAlpha(200)),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          image: isDark
              ? null
              : const DecorationImage(
                  image: NetworkImage(
                      'https://www.transparenttextures.com/patterns/cubes.png'),
                  opacity: 0.05,
                  repeat: ImageRepeat.repeat,
                ),
        ),
        child: Column(
          children: [
            Expanded(
              child: threadSessions.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                      itemCount:
                          threadSessions.length + (state.error != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < threadSessions.length) {
                          final session = threadSessions[index];
                          return ChatBubble(
                            id: session.id,
                            query: session.query,
                            response: session.response,
                            timestamp: session.timestamp,
                            isStreaming: state.isLoading &&
                                index == threadSessions.length - 1,
                            isLast: index == threadSessions.length - 1,
                          );
                        }

                        if (state.error != null) {
                          return _buildErrorWidget(state.error!);
                        }

                        return const SizedBox.shrink();
                      },
                    ),
            ),
            _buildInputArea(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school_outlined,
                size: 64, color: colorScheme.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Start your learning journey!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ask anything about your studies, or ask for a summary of a topic.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withAlpha(100)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final state = ref.watch(studyProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 100 : 20),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colorScheme.primary.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Ask anything...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (val) => _handleSend(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.article_outlined,
                      color: _controller.text.isNotEmpty
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withAlpha(100),
                    ),
                    tooltip: 'Summarize',
                    onPressed: _handleSummarize,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, child) {
              final isNotEmpty =
                  value.text.trim().isNotEmpty && !state.isLoading;
              return GestureDetector(
                onTap: isNotEmpty ? _handleSend : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isNotEmpty
                        ? colorScheme.primary
                        : colorScheme.primary.withAlpha(100),
                    shape: BoxShape.circle,
                    boxShadow: isNotEmpty
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withAlpha(100),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 24),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(studyProvider.notifier).askAI(
            text,
            threadId: _lockedThreadId,
          );
      _controller.clear();
      _scrollToBottom();
    }
  }

  void _handleSummarize() {
    if (_controller.text.trim().isNotEmpty) {
      ref
          .read(studyProvider.notifier)
          .askAISummary(_controller.text, threadId: _lockedThreadId);
      _controller.clear();
    }
  }
}
