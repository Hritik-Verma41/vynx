import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/models/contact_model.dart';
import 'package:vynx/services/api_service.dart';

enum QrAddOutcome { added, alreadyAdded, userNotFound, invalidQr, failed }

class QrAddResult {
  final QrAddOutcome outcome;
  final String message;
  const QrAddResult(this.outcome, this.message);
}

class ContactsController extends GetxController {
  final Dio _dio = Get.find<ApiService>().dio;

  final contacts = <ContactModel>[].obs;
  final isLoading = false.obs;
  final isSyncingPhonebook = false.obs;
  final myQrPayload = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    try {
      isLoading.value = true;
      final res = await _dio.get(ApiUrls.contacts);
      if (res.statusCode == 200) {
        final List list = (res.data['contacts'] as List?) ?? [];
        contacts.value = list
            .map((e) => ContactModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      log("fetchContacts error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addByPhone(String phoneNumber) async {
    try {
      final res = await _dio.post(
        ApiUrls.contactsAddByPhone,
        data: {'phoneNumber': phoneNumber},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchContacts();
        Get.snackbar("Success", res.data['message'] ?? "Contact added");
        return true;
      }
      return false;
    } catch (e) {
      final msg = e is DioException
          ? (e.response?.data?['message'] ?? "Failed to add contact")
          : "Failed to add contact";
      Get.snackbar("Error", "$msg");
      return false;
    }
  }

  Future<void> syncFromPhonebook() async {
    try {
      isSyncingPhonebook.value = true;

      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        Get.snackbar("Permission", "Contacts permission denied");
        return;
      }

      final all = await FlutterContacts.getContacts(withProperties: true);
      final phones = <String>[];
      for (final contact in all) {
        for (final phone in contact.phones) {
          final value = phone.number.trim();
          if (value.isNotEmpty) phones.add(value);
        }
      }

      if (phones.isEmpty) {
        Get.snackbar("Info", "No phone numbers found in contacts");
        return;
      }

      final res = await _dio.post(
        ApiUrls.contactsMatchPhonebook,
        data: {'phoneNumbers': phones},
      );

      if (res.statusCode != 200) return;

      final matches = (res.data['matches'] as List?) ?? [];
      int added = 0;

      for (final m in matches) {
        final isAlready = m['isAlreadyContact'] == true;
        if (isAlready) continue;

        final user = Map<String, dynamic>.from(m['user'] ?? {});
        final num = user['phoneNumber']?.toString() ?? '';
        if (num.isEmpty) continue;

        final ok = await addByPhone(num);
        if (ok) added++;
      }

      await fetchContacts();
      Get.snackbar("Sync complete", "Added $added contact(s) from phonebook");
    } catch (e) {
      Get.snackbar("Error", "Phonebook sync failed");
    } finally {
      isSyncingPhonebook.value = false;
    }
  }

  Future<void> loadMyQr() async {
    try {
      final res = await _dio.get(ApiUrls.contactsMyQr);
      if (res.statusCode == 200) {
        myQrPayload.value = res.data['qrPayload']?.toString();
      }
    } catch (e) {
      Get.snackbar("Error", "Unable to load QR");
    }
  }

  Future<QrAddResult> addByQr(String token) async {
    try {
      final res = await _dio.post(
        ApiUrls.contactsAddByQr,
        data: {'token': token},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchContacts();
        final bool alreadyExists = res.data['alreadyExists'] == true;
        final String msg =
            res.data['message']?.toString() ??
            (alreadyExists ? "User already in contacts." : "Contact added.");
        return QrAddResult(
          alreadyExists ? QrAddOutcome.alreadyAdded : QrAddOutcome.added,
          msg,
        );
      }

      return const QrAddResult(QrAddOutcome.failed, "Unable to add contact.");
    } catch (e) {
      if (e is DioException) {
        final String msg =
            e.response?.data?['message']?.toString() ?? "Invalid QR";
        final lc = msg.toLowerCase();

        if (lc.contains("already")) {
          return QrAddResult(QrAddOutcome.alreadyAdded, msg);
        }
        if (lc.contains("not found")) {
          return QrAddResult(QrAddOutcome.userNotFound, msg);
        }
        if (lc.contains("invalid") ||
            lc.contains("expired") ||
            lc.contains("qr")) {
          return QrAddResult(QrAddOutcome.invalidQr, msg);
        }
        return QrAddResult(QrAddOutcome.failed, msg);
      }

      return const QrAddResult(QrAddOutcome.failed, "Unable to add contact.");
    }
  }
}
