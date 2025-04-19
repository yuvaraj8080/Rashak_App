import 'dart:async';
import 'package:location/location.dart';
import 'package:get/get.dart';
import 'package:background_sms/background_sms.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../Constants/contactsm.dart';
import '../../../../DB/db_services.dart';
import '../../../../common/widgets.Login_Signup/loaders/snackbar_loader.dart';

class SOSController extends GetxController {
  final _contactList = <TContact>[].obs;
  RxBool isSOSActive = false.obs;  // Make isSOSActive observable
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _loadContacts();
  }

  /// Reloads contact list whenever contacts are added or changed
  Future<void> refreshContacts() async {
    _contactList.assignAll(await DatabaseHelper().getContactList());
  }

  void _loadContacts() async {
    await refreshContacts();
  }

  /// Send SOS help SMS to all trusted contacts
  Future<void> sendSOS(LocationData locationData) async {
    await refreshContacts();  // Ensure we have the latest contacts
    if (!isSOSActive.value) {
      if (_contactList.isEmpty) {
        TLoaders.warningSnackBar(title: "No trusted contacts available? Please Add Trusted Contact!");
        return;
      }

      bool permissionsGranted = await _arePermissionsGranted();
      if (permissionsGranted){
        isSOSActive.value = true;  // Update observable
        TLoaders.successSnackBar(title: "SOS Help Activated");

        // Send SOS message immediately
        await _sendSOSMessage(locationData);

        // Start sending SOS messages every 10 seconds
        _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
          await _sendSOSMessage(locationData);
        });
      }
    } else {
      // Stop sending SOS messages
      _timer?.cancel();
      String message = "I am safe now! My current location: https://www.google.com/maps/search/?api=1&query=${locationData.latitude},${locationData.longitude}";

      for (TContact contact in _contactList) {
        await sendMessage(contact.number, message);
      }
      TLoaders.successSnackBar(title: "SOS Help Deactivated");
      isSOSActive.value = false;  // Update observable
    }
  }

  Future<void> _sendSOSMessage(LocationData locationData) async {
    String message = "I am in trouble! Please reach me at my current live location: https://www.google.com/maps/search/?api=1&query=${locationData.latitude},${locationData.longitude}";

    for (TContact contact in _contactList) {
      await sendMessage(contact.number, message);
      TLoaders.customToast(message: "Sent SOS message successfully");
    }
  }

  Future<void> sendShakeSOS(LocationData locationData) async {
    await refreshContacts();  // Ensure we have the latest contacts
    if (_contactList.isEmpty) {
      TLoaders.warningSnackBar(title: "No trusted contacts available? Please Add Trusted Contact!");
      return;
    }

    bool permissionsGranted = await _arePermissionsGranted();
    if (permissionsGranted) {
      String message = "I am in trouble! Please reach me at my current live location: https://www.google.com/maps/search/?api=1&query=${locationData.latitude},${locationData.longitude}";

      for (TContact contact in _contactList) {
        await sendMessage(contact.number, message);
        // Optionally show a notification here
      }
    }
  }

  Future<bool> _arePermissionsGranted() async {
    return await Permission.sms.isGranted && await Permission.contacts.isGranted;
  }

  Future<void> sendMessage(String phoneNumber, String message) async {
    await BackgroundSms.sendMessage(phoneNumber: phoneNumber, message: message, simSlot: 1);
  }
}