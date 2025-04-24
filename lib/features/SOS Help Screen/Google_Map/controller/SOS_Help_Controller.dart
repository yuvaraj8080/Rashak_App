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

  Future<void> sendSOS(LocationData locationData) async {
    // Check if SOS is already active
    if (isSOSActive.value) return;

    // Check if contacts are available
    if (_contactList.isEmpty) {
      TLoaders.warningSnackBar(title: "No trusted contacts available? Please Add Trusted Contact!");
      return;
    }

    // Check permissions
    bool permissionsGranted = await _arePermissionsGranted();
    if (!permissionsGranted) {
      TLoaders.warningSnackBar(title: "Permissions not granted. Please enable SMS and Contacts permissions.");
      return;
    }

    // Activate SOS
    isSOSActive.value = true;
    TLoaders.successSnackBar(title: "SOS Help Activated");

    // Send SOS message immediately
    await _sendSOSMessage(locationData);

    // Start the timer for periodic messages
    _startSOSMessageTimer(locationData);
  }
  Future<void> stopSOS() async {
    if (isSOSActive.value) {
      _timer?.cancel();
      isSOSActive.value = false;
      TLoaders.successSnackBar(title: "SOS Help Deactivated");
    }
  }

  void _startSOSMessageTimer(LocationData locationData) {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
      await _sendSOSMessage(locationData);
    });
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