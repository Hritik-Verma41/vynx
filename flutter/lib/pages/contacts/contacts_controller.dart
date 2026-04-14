import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/models/contact_model.dart';
import 'package:vynx/services/api_service.dart';

enum QrAddOutcome { added, alreadyAdded, userNotFound, invalidQr, failed }

enum PhoneAddOutcome { added, alreadyAdded, userNotFound, invalidPhone, failed }

class QrAddResult {
  final QrAddOutcome outcome;
  final String message;
  const QrAddResult(this.outcome, this.message);
}

class PhoneAddResult {
  final PhoneAddOutcome outcome;
  final String message;
  const PhoneAddResult(this.outcome, this.message);
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

  Future<PhoneAddResult> addByPhone(String phoneNumber) async {
    try {
      final res = await _dio.post(
        ApiUrls.contactsAddByPhone,
        data: {'phoneNumber': phoneNumber},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchContacts();
        final alreadyExists = res.data['alreadyExists'] == true;
        final message =
            res.data['message']?.toString() ??
            (alreadyExists ? "Already in contacts." : "Contact added.");
        return PhoneAddResult(
          alreadyExists ? PhoneAddOutcome.alreadyAdded : PhoneAddOutcome.added,
          message,
        );
      }

      return const PhoneAddResult(
        PhoneAddOutcome.failed,
        "Failed to add contact.",
      );
    } catch (e) {
      if (e is DioException) {
        final msg =
            e.response?.data?['message']?.toString() ?? "Failed to add contact";
        final lc = msg.toLowerCase();

        if (lc.contains('already')) {
          return PhoneAddResult(PhoneAddOutcome.alreadyAdded, msg);
        }
        if (lc.contains('not found')) {
          return PhoneAddResult(PhoneAddOutcome.userNotFound, msg);
        }
        if (lc.contains('invalid') || lc.contains('phone')) {
          return PhoneAddResult(PhoneAddOutcome.invalidPhone, msg);
        }

        return PhoneAddResult(PhoneAddOutcome.failed, msg);
      }

      return const PhoneAddResult(
        PhoneAddOutcome.failed,
        "Failed to add contact.",
      );
    }
  }

  Future<void> syncFromPhonebook() async {
    try {
      isSyncingPhonebook.value = true;

      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        Get.snackbar(
          "Permission",
          "Contacts permission denied",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
          margin: const EdgeInsets.all(15),
          borderRadius: 10,
        );
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
        Get.snackbar(
          "Info",
          "No phone numbers found in contacts",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
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

        final result = await addByPhone(num);
        if (result.outcome == PhoneAddOutcome.added) {
          added++;
        }
      }

      await fetchContacts();

      if (added != 0) {
        Get.snackbar(
          "Sync complete",
          "Added $added contact(s) from phonebook",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Phonebook sync failed",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        margin: const EdgeInsets.all(15),
        borderRadius: 10,
      );
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
      Get.snackbar(
        "Error",
        "Unable to load QR",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        margin: const EdgeInsets.all(15),
        borderRadius: 10,
      );
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
