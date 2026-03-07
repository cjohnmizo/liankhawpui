import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/localization/app_strings.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/widgets/app_states.dart';
import 'package:liankhawpui/features/announcement/presentation/announcement_providers.dart';
import 'package:liankhawpui/features/announcement/presentation/widgets/announcement_card.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';

class AnnouncementListScreen extends ConsumerWidget {
  const AnnouncementListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final announcementsAsync = ref.watch(announcementsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(t.announcements),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: announcementsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: AppEmptyState(
                      message: t.noAnnouncementsYet,
                      icon: Icons.campaign_outlined,
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 1050
                        ? 3
                        : width >= 680
                        ? 2
                        : 1;
                    final childAspectRatio = crossAxisCount == 1 ? 1.1 : 1.25;
                    return GridView.builder(
                      itemCount: list.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final card = AnnouncementCard(
                          announcement: item,
                          onTap: () => context.push('/announcement/${item.id}'),
                        );
                        if (!user.role.isEditor) return card;

                        return Stack(
                          children: [
                            card,
                            Positioned(
                              top: 6,
                              right: 6,
                              child: PopupMenuButton<String>(
                                tooltip: 'Manage announcement',
                                icon: const Icon(Icons.more_vert_rounded),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    context.push(
                                      '/announcement/edit/${item.id}',
                                    );
                                    return;
                                  }
                                  if (value == 'delete') {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Delete Announcement?',
                                        ),
                                        content: const Text(
                                          'This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (shouldDelete != true) return;
                                    await ref
                                        .read(announcementRepositoryProvider)
                                        .deleteAnnouncement(item.id);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem<String>(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit_rounded),
                                      title: Text('Edit'),
                                      contentPadding: EdgeInsets.zero,
                                      minLeadingWidth: 18,
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.error,
                                      ),
                                      title: Text('Delete'),
                                      contentPadding: EdgeInsets.zero,
                                      minLeadingWidth: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              loading: () => AppLoadingState(message: t.loadingAnnouncements),
              error: (_, __) => AppEmptyState(
                message: t.couldNotLoadAnnouncements,
                icon: Icons.error_outline_rounded,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: user.role.isEditor
          ? FloatingActionButton(
              heroTag: 'announcement_create_fab',
              onPressed: () => context.push('/announcement/create'),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}
