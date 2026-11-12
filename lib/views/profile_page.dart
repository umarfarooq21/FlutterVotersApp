import 'package:flutter/material.dart';
//import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:quiz_app/services/contact_services.dart';
import 'package:quiz_app/views/login_page.dart';
import 'dart:io';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  List<Contact> contacts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    /*
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contactService.syncContacts(context);
    });*/
  }

  Future<bool> hasContactPermission() async {
    return await FlutterContacts.requestPermission();
  }

  Future<bool> hasContactPermission2() async {
    PermissionStatus status = await Permission.contacts.status;
    bool isGranted = status.isGranted;
    print("Has Permission: $isGranted");

    if (!isGranted) {
      status = await Permission.contacts.request();
      isGranted = status.isGranted;
      print("Requested Permission Result: $isGranted");
    }

    return isGranted;
  }

  Future<bool> checkContactPermission() async {

    if (Platform.isIOS) {
      // iOS → use flutter_contacts
      return await hasContactPermission();
    }

    if (Platform.isAndroid) {
      // Android → use permission_handler
      return await hasContactPermission2();
    }

    return false;
  }

  Future<void> getContacts(BuildContext context) async {

  bool permissionGranted = await checkContactPermission();

  setState(() {
    isLoading = true;
  });

  if (!permissionGranted) {
    setState(() => isLoading = false);
    showPermissionDialog(context);
    return;
  }

  final fetchedContacts = await FlutterContacts.getContacts(
    withProperties: true,
    withPhoto: true,
  );

  setState(() {
    contacts = fetchedContacts;
    isLoading = false;
  });

  print("Total Contacts: ${contacts.length}");
}

void showPermissionDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text("Contacts Permission Required"),
      content: const Text(
        "Please allow contacts access in settings.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await openAppSettings();
          },
          child: const Text("Open Settings"),
        ),
      ],
    ),
  );
}
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginPage(),
            ),
          );
        },
        icon: const Icon(Icons.logout),
      ),
      actions: [
        IconButton(
          onPressed: () => getContacts(context),
          icon: const Icon(Icons.sync, size: 30),
        

        ),
      ],
      title: const Text("Contacts Sync"),
      centerTitle: true,
    ),

    body: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      child: Column(
        children: [

          const SizedBox(height: 16),

          /// Title
          const Text(
            "Sync your Contact List Here..",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          /// Subtitle
          const Text(
            "Please sync your contacts using the sync button.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          /// Contact List Section
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : contacts.isEmpty
                    ? const Center(
                        child: Text(
                          "No contacts synced yet",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {

                          final contact = contacts[index];

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: contact.photo != null &&
                                      contact.photo!.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage:
                                          MemoryImage(contact.photo!),
                                    )
                                  : const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),

                              title: Text(
                                contact.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              subtitle: contact.phones.isNotEmpty
                                  ? Text(
                                      contact.phones.first.number,
                                    )
                                  : const Text("No phone number"),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
  );
}
}
