import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../Constants/contactsm.dart';
import '../../../DB/db_services.dart';
import '../../../common/widgets.Login_Signup/loaders/snackbar_loader.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/halpers/helper_function.dart';


class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> contacts = [];
  List<Contact> contactsFiltered = [];
  DatabaseHelper _databaseHelper = DatabaseHelper();
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    askPermissions();
  }

  String flattenPhoneNumber(String phoneStr) {
    return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
      return m[0] == "+" ? "+" : "";
    });
  }

  void filterContact() {
    List<Contact> _contacts = contacts.toList();

    if (searchController.text.isNotEmpty) {
      String searchTerm = searchController.text.toLowerCase();
      String searchTermFlatten = flattenPhoneNumber(searchTerm);

      _contacts.retainWhere((element) {
        String contactName = element.displayName.toLowerCase();
        var matchingPhone = element.phones.firstWhereOrNull((p) {
          return flattenPhoneNumber(p.number).contains(searchTermFlatten);
        });

        return contactName.contains(searchTerm) || (matchingPhone != null);
      });
    }

    setState(() {
      contactsFiltered = _contacts;
    });
  }

  Future<void> askPermissions() async {
    PermissionStatus permissionStatus = await getContactsPermissions();
    if (permissionStatus == PermissionStatus.granted) {
      getAllContacts();
      searchController.addListener(() {
        filterContact();
      });
    } else {
      handleInvalidPermissions(permissionStatus);
    }
  }

  void handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      TLoaders.warningSnackBar(title: "Access to the contacts denied by the user");
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      TLoaders.warningSnackBar(title: "May contact does not exist on this device");
    }
  }

  Future<PermissionStatus> getContactsPermissions() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      return await Permission.contacts.request();
    } else {
      return permission;
    }
  }

  Future<void> getAllContacts() async {
    if (await FlutterContacts.requestPermission()) {
      List<Contact> _contacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: true);
      setState(() {
        contacts = _contacts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunction.isDarkMode(context);
    bool isSearching = searchController.text.isNotEmpty;
    bool listItemExists = contactsFiltered.isNotEmpty || contacts.isNotEmpty;

    return Scaffold(
      backgroundColor: dark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: dark ? Colors.black87 : Colors.white,
        title: Text(
          "Contacts",
          style: TextStyle(color: dark ? Colors.white : Colors.black),
        ),
        elevation: 0,
        leading: Icon(Icons.contact_page_outlined, color: dark ? Colors.white : Colors.black),
      ),
      body: contacts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      TColors.primaryColor.withOpacity(0.7),
                      Colors.pinkAccent.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: TextFormField(
                  controller: searchController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    labelText: "Search Contact",
                    labelStyle: TextStyle(color: dark ? Colors.white : Colors.black),
                    prefixIcon: Icon(Icons.search, color: dark ? Colors.white : Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: dark ? Colors.white : Colors.black),
                ),
              ),
              SizedBox(height: TSizes.size12),
              listItemExists
                  ? Expanded(
                child: ListView.builder(
                  itemCount: isSearching ? contactsFiltered.length : contacts.length,
                  itemBuilder: (BuildContext context, int index) {
                    Contact contact = isSearching
                        ? contactsFiltered[index]
                        : contacts[index];

                    final displayName = contact.displayName;
                    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : 'No Phone Number';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                      shadowColor: dark ? Colors.white54 : Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      child: ListTile(
                        tileColor: dark ? Colors.grey[850] : Colors.white,
                        leading: contact.photo != null
                            ? CircleAvatar(backgroundImage: MemoryImage(contact.photo!))
                            : CircleAvatar(
                          backgroundColor: TColors.primaryColor,
                          child: Text(
                            displayName.isNotEmpty ? displayName[0] : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: dark ? Colors.white : Colors.black),
                        ),
                        subtitle: Text(
                          phone,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: dark ? Colors.white70 : Colors.black54),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: dark ? Colors.white70 : Colors.black),
                        onTap: () {
                          if (contact.phones.isNotEmpty) {
                            final String phoneNum = contact.phones.first.number;
                            final String name = contact.displayName;
                            _addContact(TContact(phoneNum, name));
                          } else {
                            TLoaders.errorSnackBar(title: "Oops! Phone number does not exist");
                          }
                        },
                      ),
                    );
                  },
                ),
              )
                  : Center(
                child: Text(
                  "No contacts found",
                  style: TextStyle(color: dark ? Colors.white70 : TColors.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addContact(TContact newContact) async {
    int result = await _databaseHelper.insertContact(newContact);
    if (result != 0) {
      TLoaders.successSnackBar(title: "Contact added successfully");
    } else {
      TLoaders.errorSnackBar(title: "Failed to add contact");
    }
    Navigator.of(context).pop(true);
  }
}
