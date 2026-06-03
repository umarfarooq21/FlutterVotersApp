import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {

  Future<void> syncContacts(BuildContext context) async {

    // 1️⃣ Check Permission
    if (!await FlutterContacts.requestPermission()) {
      _showPermissionDialog(context);
      return;
    }

    try {
      // 2️⃣ Fetch Contacts
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      print("Total Contacts: ${contacts.length}");

      for (var contact in contacts) {
        print("Name: ${contact.displayName}");
        if (contact.phones.isNotEmpty) {
          print("Phone: ${contact.phones.first.number}");
          print("Last Phone: ${contact.phones.last.number}");
          print("First Phone: ${contact.phones.first.number}");
        }
      }

    } catch (e) {
      print("Error fetching contacts: $e");
    }
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Contacts Permission Required"),
        content: const Text(
          "Please allow contacts access in settings to sync your contact list.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }
}