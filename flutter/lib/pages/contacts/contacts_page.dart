import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/pages/contacts/contacts_controller.dart';
import 'package:vynx/routes/app_routes.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ContactsController>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Contacts",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(Routes.myQr),
            icon: const Icon(Icons.qr_code_2_rounded),
          ),
          IconButton(
            onPressed: () => Get.toNamed(Routes.scanQr),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
          Obx(
            () => IconButton(
              onPressed: ctrl.isSyncingPhonebook.value
                  ? null
                  : ctrl.syncFromPhonebook,
              icon: ctrl.isSyncingPhonebook.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? Colors.purple[300] : Colors.purple[700],
        onPressed: () => _showAddByPhoneSheet(context, ctrl, isDark),
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
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
          child: Obx(() {
            if (ctrl.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.purple),
              );
            }

            if (ctrl.contacts.isEmpty) {
              return Center(
                child: Text(
                  "No contacts yet.\nUse + to add by phone or scan QR.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: ctrl.fetchContacts,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                itemCount: ctrl.contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final c = ctrl.contacts[i];
                  final u = c.contactUser;

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
                      onTap: () => Get.back(),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.purple.withValues(alpha: 0.18),
                        backgroundImage:
                            (u.profileImage != null &&
                                u.profileImage!.isNotEmpty)
                            ? NetworkImage(u.profileImage!)
                            : null,
                        child:
                            (u.profileImage == null || u.profileImage!.isEmpty)
                            ? const Icon(Icons.person, color: Colors.purple)
                            : null,
                      ),
                      title: Text(
                        u.fullName,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        u.phoneNumber ?? u.status,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showAddByPhoneSheet(
    BuildContext context,
    ContactsController ctrl,
    bool isDark,
  ) {
    final phoneCtrl = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16101F) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Add Contact",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Enter phone number",
                prefixIcon: const Icon(Icons.phone_outlined),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final phone = phoneCtrl.text.trim();
                  if (phone.isEmpty) return;
                  final ok = await ctrl.addByPhone(phone);
                  if (ok) Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Add"),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
