import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/study_provider.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/study_session.dart';
import '../../core/localization/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyProvider);
    final themeMode = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // تجميع الجلسات الحالية حسب الـ threadId وإظهار أول رسالة فقط كعنوان
    final Map<String, StudySession> threads = {};
    for (var session in state.sessions.where((s) => !s.isDeleted)) {
      final threadId = session.threadId ?? session.id;
      if (!threads.containsKey(threadId) ||
          session.timestamp.isBefore(threads[threadId]!.timestamp)) {
        threads[threadId] = session;
      }
    }
    final sortedThreads = threads.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.translate('appTitle'),
          style:
              const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync',
            onPressed: () => ref.read(studyProvider.notifier).syncData(),
          ),
          IconButton(
            icon: const Icon(Icons.language_rounded),
            onPressed: () {
              final current = ref.read(languageProvider);
              ref.read(languageProvider.notifier).state =
                  current.languageCode == 'en'
                      ? const Locale('ar')
                      : const Locale('en');
            },
          ),
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: () {
              ref.read(themeProvider.notifier).state =
                  themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, colorScheme),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(studyProvider.notifier).syncData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colorScheme),
                const SizedBox(height: 24),
                _buildSearchBar(context, colorScheme),
                const SizedBox(height: 24),
                _buildQuickActions(context, colorScheme),
                const SizedBox(height: 32),
                _buildSectionHeader('Recent Studies', Icons.history),
                const SizedBox(height: 16),
                _buildThreadsList(context, sortedThreads),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ColorScheme colorScheme) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withAlpha(200)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              FirebaseAuth.instance.currentUser?.displayName ?? 'Student',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorScheme.onPrimary,
              child: Icon(Icons.person, color: colorScheme.primary, size: 40),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Recent History'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Trash'),
            onTap: () {
              Navigator.pop(context);
              // We need to re-fetch trash sessions here or use the existing ones
              final state = ref.read(studyProvider);
              final Map<String, StudySession> trashThreads = {};
              for (var session in state.sessions.where((s) => s.isDeleted)) {
                final threadId = session.threadId ?? session.id;
                if (!trashThreads.containsKey(threadId) ||
                    session.timestamp
                        .isBefore(trashThreads[threadId]!.timestamp)) {
                  trashThreads[threadId] = session;
                }
              }
              _showTrashDialog(context, trashThreads.values.toList());
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(AppLocalizations.of(context)!.translate('logout')),
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.translate('welcome'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
          ),
          Text(
            '${user?.displayName ?? AppLocalizations.of(context)!.translate('student')}!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.translate('searchHint'),
          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward,
                  color: Colors.white, size: 18),
              onPressed: () => _navigateToChat(context, _searchController.text),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.primary.withAlpha(10),
        ),
        onSubmitted: (val) => _navigateToChat(context, val),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme colorScheme) {
    final actions = [
      {'icon': Icons.summarize, 'label': 'Summarize', 'query': 'Summarize '},
      {'icon': Icons.quiz, 'label': 'Quiz Me', 'query': 'Create a quiz about '},
      {'icon': Icons.lightbulb, 'label': 'Explain', 'query': 'Explain simply '},
    ];

    return SizedBox(
      height: 45,
      child: Center(
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final action = actions[index];
            return ActionChip(
              avatar: Icon(action['icon'] as IconData,
                  size: 16, color: colorScheme.primary),
              label: Text(action['label'] as String),
              backgroundColor: colorScheme.primary.withAlpha(20),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                _searchController.text = action['query'] as String;
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _searchController.text.length),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildThreadsList(BuildContext context, List<StudySession> threads) {
    if (threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.auto_stories_outlined,
                  size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text('Your study journey starts here.',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: threads.length,
      itemBuilder: (context, index) {
        final session = threads[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withAlpha(50)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chat_bubble_outline,
                  color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(
              session.query,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('MMM d, h:mm a').format(session.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: () async {
                final confirmed = await _showConfirmDialog(
                  context,
                  title: 'Move to Trash?',
                  content: 'This thread will be moved to the trash.',
                  confirmLabel: 'Move',
                );
                if (confirmed) {
                  ref.read(studyProvider.notifier).moveToTrash(session.id);
                }
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatScreen(threadId: session.threadId ?? session.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToChat(BuildContext context, String query) {
    if (query.trim().isNotEmpty) {
      ref.read(studyProvider.notifier).setCurrentThread(null);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(initialQuery: query),
        ),
      );
      _searchController.clear();
    }
  }

  void _showTrashDialog(BuildContext context, List<StudySession> trashThreads) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          return AlertDialog(
            title: const Text('Trash'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: trashThreads.isEmpty
                  ? const Center(child: Text('Trash is empty'))
                  : ListView.builder(
                      itemCount: trashThreads.length,
                      itemBuilder: (context, index) {
                        final session = trashThreads[index];
                        final threadId = session.threadId ?? session.id;
                        return ListTile(
                          title: Text(session.query, maxLines: 1),
                          subtitle: const Text('Entire thread'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.restore,
                                    color: Colors.green),
                                tooltip: 'Restore thread',
                                onPressed: () {
                                  ref
                                      .read(studyProvider.notifier)
                                      .restoreFromThread(threadId);
                                  Navigator.pop(context);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever,
                                    color: Colors.red),
                                tooltip: 'Delete thread forever',
                                onPressed: () async {
                                  final confirmed = await _showConfirmDialog(
                                    context,
                                    title: 'Delete Permanently?',
                                    content: 'This action cannot be undone.',
                                    confirmLabel: 'Delete Forever',
                                    isDestructive: true,
                                  );
                                  if (confirmed) {
                                    ref
                                        .read(studyProvider.notifier)
                                        .deleteThreadPermanently(threadId);
                                    if (context.mounted) Navigator.pop(context);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              if (trashThreads.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final confirmed = await _showConfirmDialog(
                      context,
                      title: 'Clear All Trash?',
                      content: 'All items will be permanently deleted.',
                      confirmLabel: 'Clear All',
                      isDestructive: true,
                    );
                    if (confirmed) {
                      ref.read(studyProvider.notifier).clearAllTrash();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Clear All',
                      style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDestructive ? Colors.red : null,
                  foregroundColor: isDestructive ? Colors.white : null,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}
