import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:vynx/models/contact_model.dart';
import 'package:vynx/pages/contacts/contacts_controller.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/widgets/vynx_alert_popup.dart';

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
              onPressed: (ctrl.isSyncingPhonebook.value || ctrl.isLoading.value)
                  ? null
                  : ctrl.refreshAll,
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
            if (ctrl.isLoading.value && ctrl.contacts.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.purple),
              );
            }

            final requests = ctrl.incomingRequests;
            final sentRequests = ctrl.outgoingRequests;
            final added = ctrl.addedContacts;
            final options = ctrl.addableFromPhonebook;

            if (requests.isEmpty &&
                sentRequests.isEmpty &&
                added.isEmpty &&
                options.isEmpty) {
              return Center(
                child: Text(
                  "No contacts yet.\nUse +, Scan QR, or Sync to discover people.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: ctrl.refreshAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                children: [
                  if (requests.isNotEmpty) ...[
                    _sectionHeader("Requests", isDark),
                    const SizedBox(height: 10),
                    ...requests.map((c) => _requestTile(c, isDark, ctrl)),
                    const SizedBox(height: 18),
                  ],
                  if (sentRequests.isNotEmpty) ...[
                    _sectionHeader("Pending Sent", isDark),
                    const SizedBox(height: 10),
                    ...sentRequests.map((c) => _outgoingRequestTile(c, isDark, ctrl)),
                    const SizedBox(height: 18),
                  ],
                  if (added.isNotEmpty) ...[
                    _sectionHeader("Added Contacts", isDark),
                    const SizedBox(height: 10),
                    ...added.map((c) => _addedTile(c, isDark)),
                    const SizedBox(height: 18),
                  ],
                  _sectionHeader("Add from Phonebook", isDark),
                  const SizedBox(height: 10),
                  if (options.isEmpty)
                    _emptyCard(
                      isDark,
                      "No Vynx users found in your phonebook yet.",
                    )
                  else
                    ...options.map((m) => _phonebookTile(m, isDark, ctrl)),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: isDark ? Colors.purple[200] : Colors.purple[700],
        ),
      ),
    );
  }

  Widget _emptyCard(bool isDark, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _tileDecor(isDark),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
    );
  }

  Widget _requestTile(
    ContactModel c,
    bool isDark,
    ContactsController ctrl,
  ) {
    final u = c.contactUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _tileDecor(isDark),
      child: ListTile(
        leading: _avatar(u.profileImage),
        title: Text(
          u.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          "Wants to add you",
          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        ),
        trailing: SizedBox(
          width: 84,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _smallIcon(
                icon: Icons.close_rounded,
                color: Colors.redAccent,
                onTap: () async {
                  final ok = await ctrl.rejectRequest(c.id);
                  _showResultPopup(
                    title: ok ? "Request Rejected" : "Failed",
                    message: ok
                        ? "Contact request rejected."
                        : "Could not reject request.",
                  );
                },
              ),
              const SizedBox(width: 6),
              _smallIcon(
                icon: Icons.check_rounded,
                color: Colors.green,
                onTap: () async {
                  final ok = await ctrl.acceptRequest(c.id);
                  _showResultPopup(
                    title: ok ? "Request Accepted" : "Failed",
                    message: ok
                        ? "Contact added successfully."
                        : "Could not accept request.",
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addedTile(ContactModel c, bool isDark) {
    final u = c.contactUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _tileDecor(isDark),
      child: ListTile(
        onTap: () => Get.toNamed(Routes.contactInfo, arguments: c),
        leading: _avatar(u.profileImage),
        title: Text(
          u.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          u.status.isEmpty ? "Available" : u.status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 12,
          ),
        ),
        trailing: SizedBox(
          width: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _smallIcon(
                icon: Icons.chat_bubble_outline_rounded,
                color: isDark ? Colors.purple[200]! : Colors.purple[700]!,
                onTap: () {
                  Get.snackbar("Next", "Open chat with ${u.fullName}");
                },
              ),
              const SizedBox(width: 4),
              _smallIcon(
                icon: Icons.call_outlined,
                color: isDark ? Colors.purple[200]! : Colors.purple[700]!,
                onTap: () {
                  Get.snackbar("Next", "Start call with ${u.fullName}");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outgoingRequestTile(
    ContactModel c,
    bool isDark,
    ContactsController ctrl,
  ) {
    final u = c.contactUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _tileDecor(isDark),
      child: ListTile(
        leading: _avatar(u.profileImage),
        title: Text(
          u.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          "Waiting for acceptance",
          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        ),
        trailing: SizedBox(
          width: 90,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.hourglass_top_rounded, color: Colors.orange[400], size: 18),
              const SizedBox(width: 8),
              _smallIcon(
                icon: Icons.close_rounded,
                color: Colors.redAccent,
                onTap: () async {
                  final ok = await ctrl.cancelRequest(c.id);
                  _showResultPopup(
                    title: ok ? "Canceled" : "Failed",
                    message: ok
                        ? "Request canceled."
                        : "Could not cancel request.",
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phonebookTile(
    PhonebookMatchModel m,
    bool isDark,
    ContactsController ctrl,
  ) {
    final u = m.user;
    final isPendingOutgoing = m.relationStatus == 'pending_outgoing';
    final isPendingIncoming = m.relationStatus == 'pending_incoming';
    final isRejected = m.relationStatus == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _tileDecor(isDark),
      child: ListTile(
        leading: _avatar(u.profileImage),
        title: Text(
          u.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isPendingOutgoing
              ? "Request pending"
              : isPendingIncoming
              ? "Sent you a request"
              : (isRejected ? "Request was declined" : "Tap to send request"),
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 12,
          ),
        ),
        trailing: _phonebookAction(m, isDark, ctrl),
      ),
    );
  }

  Widget _phonebookAction(
    PhonebookMatchModel m,
    bool isDark,
    ContactsController ctrl,
  ) {
    if (m.relationStatus == 'pending_outgoing' && m.contactId != null) {
      return SizedBox(
        width: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.hourglass_top_rounded, color: Colors.orange[400], size: 18),
            const SizedBox(width: 8),
            _smallIcon(
              icon: Icons.close_rounded,
              color: Colors.redAccent,
              onTap: () async {
                final ok = await ctrl.cancelRequest(m.contactId!);
                _showResultPopup(
                  title: ok ? "Canceled" : "Failed",
                  message: ok
                      ? "Request canceled."
                      : "Could not cancel request.",
                );
              },
            ),
          ],
        ),
      );
    }

    if (m.relationStatus == 'pending_incoming' && m.contactId != null) {
      return SizedBox(
        width: 84,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _smallIcon(
              icon: Icons.close_rounded,
              color: Colors.redAccent,
              onTap: () async {
                final ok = await ctrl.rejectRequest(m.contactId!);
                _showResultPopup(
                  title: ok ? "Request Rejected" : "Failed",
                  message: ok
                      ? "Contact request rejected."
                      : "Could not reject request.",
                );
              },
            ),
            const SizedBox(width: 6),
            _smallIcon(
              icon: Icons.check_rounded,
              color: Colors.green,
              onTap: () async {
                final ok = await ctrl.acceptRequest(m.contactId!);
                _showResultPopup(
                  title: ok ? "Request Accepted" : "Failed",
                  message: ok
                      ? "Contact added successfully."
                      : "Could not accept request.",
                );
              },
            ),
          ],
        ),
      );
    }

    return TextButton.icon(
      onPressed: () async {
        final phone = m.user.phoneNumber?.trim() ?? '';
        if (phone.isEmpty) {
          _showResultPopup(
            title: "Missing Phone",
            message: "This user doesn't have a valid phone number.",
          );
          return;
        }

        final result = await ctrl.addByPhone(phone);
        _handlePhoneAddResult(result);
      },
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
      label: const Text("Request"),
      style: TextButton.styleFrom(
        foregroundColor: isDark ? Colors.purple[200] : Colors.purple[700],
      ),
    );
  }

  BoxDecoration _tileDecor(bool isDark) {
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

  Widget _avatar(String? profileImage) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.purple.withValues(alpha: 0.18),
      backgroundImage:
          (profileImage != null && profileImage.isNotEmpty)
          ? NetworkImage(profileImage)
          : null,
      child: (profileImage == null || profileImage.isEmpty)
          ? const Icon(Icons.person, color: Colors.purple)
          : null,
    );
  }

  Widget _smallIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }

  void _showAddByPhoneSheet(
    BuildContext context,
    ContactsController ctrl,
    bool isDark,
  ) {
    String? fullPhone;
    String localNumber = '';
    bool canSubmit = false;
    int minLength = 10;
    int maxLength = 10;

    bool isPhoneValid(String value) {
      return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(value);
    }

    bool isLocalLengthValid(String value) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      return digits.length >= minLength && digits.length <= maxLength;
    }

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16101F) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                IntlPhoneField(
                  initialCountryCode: 'IN',
                  invalidNumberMessage: 'Invalid mobile number',
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: "Enter phone number",
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (phone) {
                    final candidate = phone.completeNumber.trim();
                    localNumber = phone.number;
                    setModalState(() {
                      fullPhone = candidate;
                      canSubmit =
                          isPhoneValid(candidate) &&
                          isLocalLengthValid(localNumber);
                    });
                  },
                  onCountryChanged: (country) {
                    setModalState(() {
                      minLength = country.minLength;
                      maxLength = country.maxLength;
                      canSubmit =
                          isPhoneValid((fullPhone ?? '').trim()) &&
                          isLocalLengthValid(localNumber);
                    });
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSubmit
                        ? () async {
                            final phone = (fullPhone ?? '').trim();
                            if (!isPhoneValid(phone)) {
                              _showResultPopup(
                                title: "Invalid Phone",
                                message:
                                    "Please select country code and enter a valid number.",
                              );
                              return;
                            }

                            final result = await ctrl.addByPhone(phone);
                            if (Get.isBottomSheetOpen ?? false) {
                              Get.back();
                            }
                            _handlePhoneAddResult(result);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.withValues(
                        alpha: 0.35,
                      ),
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Request"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  void _handlePhoneAddResult(PhoneAddResult result) {
    switch (result.outcome) {
      case PhoneAddOutcome.requestSent:
        _showResultPopup(title: "Request Sent", message: result.message);
        return;
      case PhoneAddOutcome.requestAccepted:
        _showResultPopup(title: "Request Accepted", message: result.message);
        return;
      case PhoneAddOutcome.alreadyAdded:
        _showResultPopup(title: "Already Added", message: result.message);
        return;
      case PhoneAddOutcome.alreadyRequested:
        _showResultPopup(title: "Pending Request", message: result.message);
        return;
      case PhoneAddOutcome.userNotFound:
        _showResultPopup(title: "User Not Found", message: result.message);
        return;
      case PhoneAddOutcome.invalidPhone:
        _showResultPopup(title: "Invalid Phone", message: result.message);
        return;
      case PhoneAddOutcome.failed:
        _showResultPopup(title: "Failed", message: result.message);
        return;
    }
  }

  void _showResultPopup({required String title, required String message}) {
    Get.dialog(
      VynxAlertPopup(
        title: title,
        message: message,
        confirmBtnText: "OK",
        onConfirm: () {
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }
        },
      ),
      barrierDismissible: false,
    );
  }
}
