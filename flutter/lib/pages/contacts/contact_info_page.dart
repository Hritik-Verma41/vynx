import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/models/contact_model.dart';
import 'package:vynx/pages/contacts/contacts_controller.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/widgets/vynx_alert_popup.dart';

class ContactInfoPage extends StatelessWidget {
  const ContactInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ContactModel? contact = Get.arguments as ContactModel?;
    final u = contact?.contactUser;
    final contactsCtrl = Get.find<ContactsController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Contact Info",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: u == null
              ? Center(
                  child: Text(
                    "Contact not found",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: _glass(isDark),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Get.toNamed(
                                  Routes.profileImageViewer,
                                  arguments: {
                                    'title': 'Contact Info',
                                    'type':
                                        (u.profileImage != null &&
                                            u.profileImage!.isNotEmpty)
                                        ? 'network'
                                        : 'none',
                                    'value': u.profileImage ?? '',
                                  },
                                );
                              },
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: Colors.purple.withValues(
                                  alpha: 0.18,
                                ),
                                backgroundImage:
                                    (u.profileImage != null &&
                                        u.profileImage!.isNotEmpty)
                                    ? NetworkImage(u.profileImage!)
                                    : null,
                                child:
                                    (u.profileImage == null ||
                                        u.profileImage!.isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        size: 42,
                                        color: Colors.purple,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              u.fullName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              u.status.isEmpty ? "Available" : u.status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _actionButton(
                                  isDark: isDark,
                                  icon: Icons.chat_bubble_outline_rounded,
                                  label: "Chat",
                                  onTap: () {
                                    Get.snackbar(
                                      "Next",
                                      "Open chat thread from here",
                                    );
                                  },
                                ),
                                const SizedBox(width: 14),
                                _actionButton(
                                  isDark: isDark,
                                  icon: Icons.call_outlined,
                                  label: "Call",
                                  onTap: () {
                                    Get.snackbar(
                                      "Next",
                                      "Start call flow from here",
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: _glass(isDark),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Phone",
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              u.phoneNumber ?? "Not available",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "Status",
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              u.status.isEmpty ? "Available" : u.status,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        decoration: _glass(isDark),
                        child: ListTile(
                          leading: const Icon(
                            Icons.person_remove_outlined,
                            color: Colors.redAccent,
                          ),
                          title: const Text(
                            "Remove Contact",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            "This will remove contact from your list.",
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => _confirmRemove(contact!, contactsCtrl),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  BoxDecoration _glass(bool isDark) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _actionButton({
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(ContactModel contact, ContactsController ctrl) {
    Get.dialog(
      VynxAlertPopup(
        title: "Remove Contact",
        message: "Do you want to remove ${contact.contactUser.fullName}?",
        confirmBtnText: "Remove",
        enableCancel: true,
        onConfirm: () async {
          if (Get.isDialogOpen ?? false) Get.back();
          final ok = await ctrl.removeContact(contact.id);

          if (ok) {
            if (Get.currentRoute == Routes.contactInfo) {
              Get.back();
            }
            Get.dialog(
              VynxAlertPopup(
                title: "Removed",
                message: "${contact.contactUser.fullName} was removed.",
                confirmBtnText: "OK",
                onConfirm: () {
                  if (Get.isDialogOpen ?? false) Get.back();
                },
              ),
            );
          } else {
            Get.dialog(
              VynxAlertPopup(
                title: "Failed",
                message: "Unable to remove contact. Please try again.",
                confirmBtnText: "OK",
                onConfirm: () {
                  if (Get.isDialogOpen ?? false) Get.back();
                },
              ),
            );
          }
        },
      ),
    );
  }
}
