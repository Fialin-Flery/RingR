import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact_model.dart';
import 'user_service.dart';

class ContactService {
  ContactService._();

  static final ContactService instance = ContactService._();

  final UserService _userService = UserService.instance;

  // ============================================================
  // GET ALL RINGR CONTACTS
  // ============================================================

  Future<List<ContactModel>> getContacts() async {
    final deviceContacts = await getDeviceContacts();

    if (deviceContacts.isEmpty) {
      return [];
    }

    // ----------------------------------------------------------
    // Build lookup keys
    // ----------------------------------------------------------

    final lookupKeys = <String>{};

    for (final contact in deviceContacts) {
      final phone = contact.phoneNumber;
      final email = contact.email;

      if (phone != null && phone.trim().isNotEmpty) {
        final key = UserService.phoneLookupKey(phone);

        if (key.isNotEmpty) {
          lookupKeys.add(key);
        }
      }

      if (email != null && email.trim().isNotEmpty) {
        final key = UserService.emailLookupKey(email);

        if (key.isNotEmpty) {
          lookupKeys.add(key);
        }
      }
    }

    // ----------------------------------------------------------
    // Find Ringr users
    // ----------------------------------------------------------

    final registeredUsers =
    await _userService.findRegisteredUsers(
      lookupKeys.toList(),
    );

    final registered = <ContactModel>[];
    final unregistered = <ContactModel>[];

    final addedRegisteredUids = <String>{};

    // ----------------------------------------------------------
    // Match contacts
    // ----------------------------------------------------------

    for (final contact in deviceContacts) {
      String? matchedUid;
      Map<String, dynamic>? matchedData;

      // --------------------------------------------------------
      // PHONE MATCH
      // --------------------------------------------------------

      final phone = contact.phoneNumber;

      if (phone != null && phone.trim().isNotEmpty) {
        final phoneKey = UserService.phoneLookupKey(phone);

        for (final entry in registeredUsers.entries) {
          final data = entry.value;

          if (data['phoneLookupKey'] == phoneKey) {
            matchedUid = entry.key;
            matchedData = data;
            break;
          }
        }
      }

      // --------------------------------------------------------
      // EMAIL MATCH
      // --------------------------------------------------------

      if (matchedUid == null) {
        final email = contact.email;

        if (email != null && email.trim().isNotEmpty) {
          final emailKey =
          UserService.emailLookupKey(email);

          for (final entry in registeredUsers.entries) {
            final data = entry.value;

            if (data['emailLookupKey'] == emailKey) {
              matchedUid = entry.key;
              matchedData = data;
              break;
            }
          }
        }
      }

      // --------------------------------------------------------
      // REGISTERED
      // --------------------------------------------------------

      if (matchedUid != null &&
          matchedData != null) {

        // --------------------------------------------------------
        // EXTRA SELF-CALL PROTECTION
        // Never add the currently logged-in user
        // as their own Ringr contact.
        // --------------------------------------------------------
        final currentUserUid =
            FirebaseAuth.instance.currentUser?.uid;

        if (currentUserUid != null &&
            matchedUid == currentUserUid) {
          continue;
        }

        if (addedRegisteredUids
            .contains(matchedUid)) {
          continue;
        }

        addedRegisteredUids.add(matchedUid);

        final registeredName =
        (matchedData['name'] ?? contact.name)
            .toString()
            .trim();

        registered.add(
          ContactModel(
            uid: matchedUid,
            name: registeredName.isEmpty
                ? (contact.name.isEmpty
                ? contact.phoneNumber ?? 'Unknown'
                : contact.name)
                : registeredName,
            phoneNumber: contact.phoneNumber,
            email: contact.email,
            source: ContactSource.registered,
            isOnline: matchedData['isOnline'] == true,
          ),
        );
      }

      // --------------------------------------------------------
      // NOT REGISTERED
      // --------------------------------------------------------

      else {
        unregistered.add(
          ContactModel(
            name: contact.name.isEmpty
                ? contact.phoneNumber ?? 'Unknown'
                : contact.name,
            phoneNumber: contact.phoneNumber,
            email: contact.email,
            source: ContactSource.phoneContact,
            isOnline: false,
          ),
        );
      }
    }

    // Registered Ringr users first.
    return [
      ...registered,
      ...unregistered,
    ];
  }

  // ============================================================
  // DEVICE CONTACTS
  // ============================================================

  Future<List<ContactModel>> getDeviceContacts() async {
    try {
      final permission =
      await FlutterContacts.permissions.request(
        PermissionType.read,
      );

      if (permission != PermissionStatus.granted) {
        return [];
      }

      final contacts = await FlutterContacts.getAll(
        properties: {
          ContactProperty.name,
          ContactProperty.phone,
          ContactProperty.email,
        },
      );

      final List<ContactModel> result = [];

      for (final contact in contacts) {
        // IMPORTANT:
        // displayName can be null on Android.
        final name =
        (contact.displayName ?? '').trim();

        String? phoneNumber;

        if (contact.phones.isNotEmpty) {
          final number =
          contact.phones.first.number.trim();

          if (number.isNotEmpty) {
            phoneNumber = number;
          }
        }

        String? email;

        if (contact.emails.isNotEmpty) {
          final address =
          contact.emails.first.address.trim();

          if (address.isNotEmpty) {
            email = address;
          }
        }

        // Ignore completely empty contacts.
        if (name.isEmpty &&
            (phoneNumber == null ||
                phoneNumber.isEmpty) &&
            (email == null ||
                email.isEmpty)) {
          continue;
        }

        result.add(
          ContactModel(
            name: name.isEmpty
                ? phoneNumber ?? 'Unknown'
                : name,
            phoneNumber: phoneNumber,
            email: email,
            source: ContactSource.phoneContact,
            isOnline: false,
          ),
        );
      }

      return result;
    } catch (e) {
      print(
        'Failed to read device contacts: $e',
      );

      return [];
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<List<ContactModel>> searchContacts(
      String query,
      ) async {
    final contacts = await getContacts();

    final search = query.trim().toLowerCase();

    if (search.isEmpty) {
      return contacts;
    }

    return contacts.where(
          (contact) {
        final name =
        contact.name.toLowerCase();

        final phone =
            contact.phoneNumber
                ?.toLowerCase() ??
                '';

        final email =
            contact.email
                ?.toLowerCase() ??
                '';

        return name.contains(search) ||
            phone.contains(search) ||
            email.contains(search);
      },
    ).toList();
  }
}