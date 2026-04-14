import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vynx/pages/chats/group_info_controller.dart';

class GroupInfoPage extends StatelessWidget {
  const GroupInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GroupInfoController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Group Info'),
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
            if (ctrl.isLoading.value || ctrl.current.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final c = ctrl.current.value!;
            final members = ctrl.members;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _tile(isDark),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: c.avatar?.isNotEmpty == true
                            ? NetworkImage(c.avatar!)
                            : null,
                        child: c.avatar?.isNotEmpty == true
                            ? null
                            : const Icon(Icons.groups_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c.name ?? 'Group',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (ctrl.amIAdmin)
                        IconButton(
                          onPressed: () => _showEditSheet(ctrl, c.name ?? ''),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Members (${members.length})',
                  style: TextStyle(
                    color: isDark ? Colors.purple[200] : Colors.purple[700],
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                ...members.map((m) {
                  final isAdmin = ctrl.adminIds.contains(m.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: _tile(isDark),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: m.profileImage?.isNotEmpty == true
                            ? NetworkImage(m.profileImage!)
                            : null,
                        child: m.profileImage?.isNotEmpty == true
                            ? null
                            : const Icon(Icons.person),
                      ),
                      title: Text(
                        m.fullName,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
                      subtitle: Text(
                        isAdmin ? 'Admin' : (m.status.isEmpty ? 'Available' : m.status),
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      trailing: ctrl.amIAdmin && m.id != ctrl.myId
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () => ctrl.removeMember(m.id),
                            )
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 10),
                if (ctrl.amIAdmin)
                  ElevatedButton.icon(
                    onPressed: () => _showAddMembersDialog(ctrl),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add Members'),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: ctrl.leaveGroup,
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text('Leave Group', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  BoxDecoration _tile(bool isDark) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
      ),
    );
  }

  void _showEditSheet(GroupInfoController ctrl, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    final descCtrl = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF16101F) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(hintText: 'Group name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(hintText: 'Description'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (picked == null) return;
                      await ctrl.updateGroup(
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        avatarFilePath: picked.path,
                      );
                      Get.back();
                    },
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Name + Photo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ctrl.updateGroup(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                  );
                  Get.back();
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAddMembersDialog(GroupInfoController ctrl) {
    final existing = ctrl.members.map((m) => m.id).toSet();
    final allContacts = ctrl
        .findAllAcceptedContacts()
        .where((u) => !existing.contains(u.id))
        .toList();
    final selected = <String>{}.obs;

    Get.dialog(
      Obx(
        () => AlertDialog(
          title: const Text('Add Members'),
          content: SizedBox(
            width: 320,
            child: allContacts.isEmpty
                ? const Text('No more contacts available to add.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: allContacts.length,
                    itemBuilder: (_, i) {
                      final u = allContacts[i];
                      final checked = selected.contains(u.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (_) {
                          if (checked) {
                            selected.remove(u.id);
                          } else {
                            selected.add(u.id);
                          }
                        },
                        title: Text(u.fullName),
                        subtitle: Text(u.status),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selected.isEmpty
                  ? null
                  : () async {
                      await ctrl.addMembers(selected.toList());
                      Get.back();
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
