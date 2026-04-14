import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/controllers/user_controller.dart';
import 'package:vynx/pages/chats/chats_controller.dart';
import 'package:vynx/routes/app_routes.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ChatsController>();
    final userCtrl = Get.find<UserController>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Text(
                  "Chats",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.toNamed(Routes.contacts),
                  icon: Icon(
                    Icons.person_add_alt_1_rounded,
                    color: isDark ? Colors.purple[200] : Colors.purple[700],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.toNamed(Routes.createGroup),
                  icon: Icon(
                    Icons.group_add_rounded,
                    color: isDark ? Colors.purple[200] : Colors.purple[700],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              onChanged: (v) => ctrl.query.value = v,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Search chats",
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.purple),
                );
              }

              final list = ctrl.filtered;
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    "No chats yet.\nTap + to add contacts.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              final myId = userCtrl.user.value?.id ?? '';

              return RefreshIndicator(
                onRefresh: ctrl.fetchConversations,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  itemBuilder: (_, i) {
                    final c = list[i];
                    final peer = c.members.firstWhereOrNull((m) => m.id != myId);
                    final isGroup = c.type == 'group';
                    final avatarUrl = isGroup ? c.avatar : peer?.profileImage;
                    final name = isGroup
                        ? (c.name?.trim().isNotEmpty == true
                              ? c.name!.trim()
                              : 'Group')
                        : (peer?.fullName.isNotEmpty == true ? peer!.fullName : "Unknown");

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          Get.toNamed(Routes.chatThread, arguments: c);
                        },
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.purple.withValues(
                            alpha: 0.18,
                          ),
                          backgroundImage:
                              (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty)
                              ? Icon(
                                  isGroup ? Icons.groups_rounded : Icons.person,
                                  color: Colors.purple,
                                )
                              : null,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          c.lastMessage ?? "Start chatting",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        trailing: Icon(
                          c.unreadCount > 0
                              ? Icons.mark_chat_unread_rounded
                              : Icons.chevron_right,
                          color: c.unreadCount > 0
                              ? Colors.greenAccent
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemCount: list.length,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
