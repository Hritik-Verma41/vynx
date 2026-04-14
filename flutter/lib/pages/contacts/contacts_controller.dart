import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:vynx/config/api_urls.dart';
import 'package:vynx/models/contact_model.dart';
import 'package:vynx/services/api_service.dart';

enum QrAddOutcome {
  requestSent,
  requestAccepted,
  alreadyAdded,
  alreadyRequested,
  userNotFound,
  invalidQr,
  failed,
}

enum PhoneAddOutcome {
  requestSent,
  requestAccepted,
  alreadyAdded,
  alreadyRequested,
  userNotFound,
  invalidPhone,
  failed,
}

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
  final phonebookMatches = <PhonebookMatchModel>[].obs;
  final isLoading = false.obs;
  final isSyncingPhonebook = false.obs;
  final myQrPayload = RxnString();

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    await fetchContacts();
    await syncFromPhonebook(showSnackbars: false);
  }

  List<ContactModel> get incomingRequests =>
      contacts.where((c) => c.isIncomingPending).toList();

  List<ContactModel> get addedContacts =>
      contacts.where((c) => c.isAccepted).toList();

  List<PhonebookMatchModel> get addableFromPhonebook =>
      phonebookMatches.where((m) => m.relationStatus != 'accepted').toList();

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

  PhoneAddResult _mapPhoneCode(String? code, String message) {
    switch (code) {
      case 'REQUEST_SENT':
        return PhoneAddResult(PhoneAddOutcome.requestSent, message);
      case 'REQUEST_ACCEPTED':
        return PhoneAddResult(PhoneAddOutcome.requestAccepted, message);
      case 'ALREADY_ADDED':
        return PhoneAddResult(PhoneAddOutcome.alreadyAdded, message);
      case 'REQUEST_PENDING':
        return PhoneAddResult(PhoneAddOutcome.alreadyRequested, message);
      default:
        return PhoneAddResult(PhoneAddOutcome.failed, message);
    }
  }

  Future<PhoneAddResult> addByPhone(String phoneNumber) async {
    try {
      final res = await _dio.post(
        ApiUrls.contactsAddByPhone,
        data: {'phoneNumber': phoneNumber},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await refreshAll();
        final message = res.data['message']?.toString() ?? "Request sent.";
        return _mapPhoneCode(res.data['code']?.toString(), message);
      }

      return const PhoneAddResult(
        PhoneAddOutcome.failed,
        "Failed to process request.",
      );
    } catch (e) {
      if (e is DioException) {
        final msg =
            e.response?.data?['message']?.toString() ??
            "Failed to process request.";
        final lc = msg.toLowerCase();

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
        "Failed to process request.",
      );
    }
  }

  Future<void> syncFromPhonebook({bool showSnackbars = true}) async {
    try {
      isSyncingPhonebook.value = true;

      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (showSnackbars) {
          Get.snackbar("Permission", "Contacts permission denied");
        }
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
        phonebookMatches.clear();
        if (showSnackbars) {
          Get.snackbar("Info", "No phone numbers found in contacts");
        }
        return;
      }

      final res = await _dio.post(
        ApiUrls.contactsMatchPhonebook,
        data: {
          'phoneNumbers': phones,
          'defaultCountryCode': _defaultDialCode(),
        },
      );

      if (res.statusCode != 200) return;

      final matches = (res.data['matches'] as List?) ?? [];
      phonebookMatches.value = matches
          .map(
            (m) => PhonebookMatchModel.fromJson(Map<String, dynamic>.from(m)),
          )
          .toList();

      if (showSnackbars) {
        Get.snackbar("Synced", "Phonebook updated");
      }
    } catch (e) {
      if (showSnackbars) {
        Get.snackbar("Error", "Phonebook sync failed");
      }
    } finally {
      isSyncingPhonebook.value = false;
    }
  }

  String _defaultDialCode() {
    final cc = (Get.deviceLocale?.countryCode ?? 'IN').toUpperCase();
    switch (cc) {
      case 'IN':
        return '91';
      case 'US':
      case 'CA':
        return '1';
      case 'GB':
        return '44';
      case 'AU':
        return '61';
      case 'SG':
        return '65';
      case 'AE':
        return '971';
      default:
        return '';
    }
  }

  Future<bool> acceptRequest(String contactId) async {
    try {
      final res = await _dio.post('${ApiUrls.contactsBase}/$contactId/accept');
      if (res.statusCode == 200) {
        await refreshAll();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectRequest(String contactId) async {
    try {
      final res = await _dio.post('${ApiUrls.contactsBase}/$contactId/reject');
      if (res.statusCode == 200) {
        await refreshAll();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelRequest(String contactId) async {
    try {
      final res = await _dio.post('${ApiUrls.contactsBase}/$contactId/cancel');
      if (res.statusCode == 200) {
        await refreshAll();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeContact(String contactId) async {
    try {
      final res = await _dio.delete('${ApiUrls.contactsBase}/$contactId');
      if (res.statusCode == 200) {
        await refreshAll();
        return true;
      }
      return false;
    } catch (_) {
      return false;
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

  QrAddResult _mapQrCode(String? code, String message) {
    switch (code) {
      case 'REQUEST_SENT':
        return QrAddResult(QrAddOutcome.requestSent, message);
      case 'REQUEST_ACCEPTED':
        return QrAddResult(QrAddOutcome.requestAccepted, message);
      case 'ALREADY_ADDED':
        return QrAddResult(QrAddOutcome.alreadyAdded, message);
      case 'REQUEST_PENDING':
        return QrAddResult(QrAddOutcome.alreadyRequested, message);
      default:
        return QrAddResult(QrAddOutcome.failed, message);
    }
  }

  Future<QrAddResult> addByQr(String token) async {
    try {
      final res = await _dio.post(
        ApiUrls.contactsAddByQr,
        data: {'token': token},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await refreshAll();
        final msg = res.data['message']?.toString() ?? "Request sent.";
        return _mapQrCode(res.data['code']?.toString(), msg);
      }

      return const QrAddResult(
        QrAddOutcome.failed,
        "Unable to process request.",
      );
    } catch (e) {
      if (e is DioException) {
        final msg = e.response?.data?['message']?.toString() ?? "Invalid QR";
        final lc = msg.toLowerCase();

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

      return const QrAddResult(
        QrAddOutcome.failed,
        "Unable to process request.",
      );
    }
  }
}
