import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/pages/chats/create_group_controller.dart';
import 'package:vynx/routes/app_routes.dart';

class CreateGroupPage extends StatelessWidget {
  const CreateGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CreateGroupController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'New Group',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A0B2E), const Color(0xFF09040F)]
                : [const Color(0xFFF3E5F5), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (ctrl.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Group name',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => ctrl.groupName.value = v,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: ctrl.contacts.length,
                    itemBuilder: (_, i) {
                      final c = ctrl.contacts[i];
                      final id = c.contactUser.id;
                      final checked = ctrl.selectedIds.contains(id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
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
                          leading: CircleAvatar(
                            backgroundImage:
                                c.contactUser.profileImage?.isNotEmpty == true
                                ? NetworkImage(c.contactUser.profileImage!)
                                : null,
                            child:
                                c.contactUser.profileImage?.isNotEmpty == true
                                ? null
                                : const Icon(Icons.person),
                          ),
                          title: Text(
                            c.contactUser.fullName,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            c.contactUser.status,
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          trailing: Checkbox(
                            value: checked,
                            onChanged: (_) => ctrl.toggle(id),
                          ),
                          onTap: () => ctrl.toggle(id),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            ctrl.selectedIds.length >= 2 &&
                                ctrl.groupName.value.trim().length >= 2
                            ? () async {
                                final conversation = await ctrl.createGroup();
                                if (conversation == null) return;
                                Get.back();
                                Get.toNamed(
                                  Routes.chatThread,
                                  arguments: conversation,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Create Group'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
