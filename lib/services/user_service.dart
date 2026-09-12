import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserService {
  UserService._();

  static final UserService instance = UserService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _directory =>
      _firestore.collection('userDirectory');

  // ============================================================
  // USER PROFILE
  // ============================================================

  Future<bool> userProfileExists(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists;
  }

  // ============================================================
  // NORMALIZATION
  // ============================================================

  static String normalizePhone(String phone) {
    var digits =
    phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return '';
    }

    if (digits.startsWith('0091')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('0') &&
        digits.length == 11) {
      digits = digits.substring(1);
    }

    if (digits.startsWith('91') &&
        digits.length == 12) {
      return digits;
    }

    if (digits.length == 10) {
      return '91$digits';
    }

    return digits;
  }

  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  // ============================================================
  // HASHING
  // ============================================================

  static String _hash(String value) {
    return sha256
        .convert(utf8.encode(value))
        .toString();
  }

  static String _phoneLookupKey(String phone) {
    final normalized =
    normalizePhone(phone);

    if (normalized.isEmpty) {
      return '';
    }

    return 'p_${_hash(normalized)}';
  }

  static String _emailLookupKey(String email) {
    final normalized =
    normalizeEmail(email);

    if (normalized.isEmpty) {
      return '';
    }

    return 'e_${_hash(normalized)}';
  }

  // ============================================================
  // CREATE USER PROFILE
  // ============================================================

  Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
    required Map<String, bool> permissions,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not authenticated.',
      );
    }

    final uid = user.uid;

    final cleanName = name.trim();

    final cleanEmail =
    normalizeEmail(email);

    final cleanPhone = phone.trim();

    final normalizedPhone =
    normalizePhone(cleanPhone);

    if (normalizedPhone.isEmpty ||
        normalizedPhone.length < 10) {
      throw Exception(
        'Please enter a valid phone number.',
      );
    }

    final phoneLookupKey =
    _phoneLookupKey(cleanPhone);

    final emailLookupKey =
    cleanEmail.isEmpty
        ? ''
        : _emailLookupKey(cleanEmail);

    final userRef = _users.doc(uid);
    final directoryRef =
    _directory.doc(uid);

    final phoneQuery =
    await _directory
        .where(
      'phoneLookupKey',
      isEqualTo: phoneLookupKey,
    )
        .limit(1)
        .get();

    if (phoneQuery.docs.isNotEmpty) {
      final existingData =
      phoneQuery.docs.first.data();

      final existingUid =
      existingData['uid']?.toString();

      if (existingUid != null &&
          existingUid != uid) {
        throw Exception(
          'This phone number is already registered with another Ringr account.',
        );
      }
    }

    final batch =
    _firestore.batch();

    batch.set(
      userRef,
      {
        'firebaseUserUid': uid,
        'name': cleanName,
        'email': cleanEmail,
        'emailNormalized': cleanEmail,
        'phone': cleanPhone,
        'phoneNormalized': normalizedPhone,
        'permissions': permissions,
        'isOnline': false,
        'lastSeen':
        FieldValue.serverTimestamp(),
        'createdAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      directoryRef,
      {
        'uid': uid,
        'name': cleanName,
        'phoneLookupKey':
        phoneLookupKey,
        'emailLookupKey':
        emailLookupKey.isEmpty
            ? null
            : emailLookupKey,
        'isOnline': false,
        'lastSeen':
        FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    await user.updateDisplayName(
      cleanName,
    );
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<void> updateUserProfile({
    required String name,
    required String phone,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not authenticated.',
      );
    }

    final cleanName = name.trim();
    final cleanPhone = phone.trim();

    if (cleanName.isEmpty) {
      throw Exception(
        'Please enter your name.',
      );
    }

    final normalizedPhone =
    normalizePhone(cleanPhone);

    if (normalizedPhone.isEmpty ||
        normalizedPhone.length < 10) {
      throw Exception(
        'Please enter a valid phone number.',
      );
    }

    final phoneLookupKey =
    _phoneLookupKey(cleanPhone);

    final userRef =
    _users.doc(user.uid);

    final directoryRef =
    _directory.doc(user.uid);

    // ------------------------------------------------------------
    // Make sure another Ringr account does not already use
    // this phone number.
    // ------------------------------------------------------------

    final existingPhone =
    await _directory
        .where(
      'phoneLookupKey',
      isEqualTo: phoneLookupKey,
    )
        .limit(1)
        .get();

    if (existingPhone.docs.isNotEmpty) {
      final existingUid =
      existingPhone.docs.first
          .data()['uid']
          ?.toString();

      if (existingUid != null &&
          existingUid != user.uid) {
        throw Exception(
          'This phone number is already registered with another Ringr account.',
        );
      }
    }

    // ------------------------------------------------------------
    // Update Firestore profile
    // ------------------------------------------------------------

    await userRef.set(
      {
        'name': cleanName,
        'phone': cleanPhone,
        'phoneNormalized': normalizedPhone,
      },
      SetOptions(merge: true),
    );

    // ------------------------------------------------------------
    // Update directory
    // ------------------------------------------------------------

    await directoryRef.set(
      {
        'uid': user.uid,
        'name': cleanName,
        'phoneLookupKey': phoneLookupKey,
      },
      SetOptions(merge: true),
    );

    // ------------------------------------------------------------
    // Update Firebase display name as well
    // ------------------------------------------------------------

    await user.updateDisplayName(
      cleanName,
    );

    await user.reload();
  }

  // ============================================================
  // ENSURE CURRENT USER DIRECTORY
  // ============================================================

  Future<void> ensureCurrentUserDirectory() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final userRef =
    _users.doc(user.uid);

    final snapshot =
    await userRef.get();

    if (!snapshot.exists) {
      return;
    }

    final data =
        snapshot.data() ?? {};

    final name =
    (data['name'] ??
        user.displayName ??
        '')
        .toString()
        .trim();

    final email =
    normalizeEmail(
      (data['email'] ??
          user.email ??
          '')
          .toString(),
    );

    final phone =
    (data['phone'] ?? '')
        .toString()
        .trim();

    if (phone.isEmpty) {
      return;
    }

    await _directory
        .doc(user.uid)
        .set(
      {
        'uid': user.uid,
        'name': name,
        'phoneLookupKey':
        _phoneLookupKey(phone),
        'emailLookupKey':
        email.isEmpty
            ? null
            : _emailLookupKey(email),
        'isOnline':
        data['isOnline'] ?? false,
        'lastSeen':
        data['lastSeen'] ??
            FieldValue
                .serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // PRESENCE
  // ============================================================

  Future<void> updatePresence(
      bool isOnline,
      ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final userRef =
    _users.doc(user.uid);

    final snapshot =
    await userRef.get();

    if (!snapshot.exists) {
      return;
    }

    final data =
        snapshot.data() ?? {};

    final name =
    (data['name'] ??
        user.displayName ??
        '')
        .toString()
        .trim();

    final phone =
    (data['phone'] ?? '')
        .toString()
        .trim();

    final email =
    (data['email'] ??
        user.email ??
        '')
        .toString()
        .trim();

    final timestamp =
    FieldValue.serverTimestamp();

    final batch =
    _firestore.batch();

    batch.set(
      userRef,
      {
        'isOnline': isOnline,
        'lastSeen': timestamp,
      },
      SetOptions(merge: true),
    );

    final directoryRef =
    _directory.doc(user.uid);

    batch.set(
      directoryRef,
      {
        'uid': user.uid,
        'name': name,
        'phoneLookupKey':
        phone.isEmpty
            ? null
            : _phoneLookupKey(phone),
        'emailLookupKey':
        email.isEmpty
            ? null
            : _emailLookupKey(email),
        'isOnline': isOnline,
        'lastSeen': timestamp,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // ============================================================
  // FIND REGISTERED USERS
  // ============================================================

  Future<Map<String, Map<String, dynamic>>>
  findRegisteredUsers(
      List<String> lookupKeys,
      ) async {
    final uniqueKeys =
    lookupKeys
        .map((key) => key.trim())
        .where(
          (key) => key.isNotEmpty,
    )
        .toSet()
        .toList();

    if (uniqueKeys.isEmpty) {
      return {};
    }

    final results =
    <String, Map<String, dynamic>>{};

    for (
    int start = 0;
    start < uniqueKeys.length;
    start += 30
    ) {
      final end =
      (start + 30 < uniqueKeys.length)
          ? start + 30
          : uniqueKeys.length;

      final batchKeys =
      uniqueKeys.sublist(
        start,
        end,
      );

      final phoneKeys =
      batchKeys
          .where(
            (key) =>
            key.startsWith('p_'),
      )
          .toList();

      if (phoneKeys.isNotEmpty) {
        final snapshot =
        await _directory
            .where(
          'phoneLookupKey',
          whereIn: phoneKeys,
        )
            .get();

        for (final doc
        in snapshot.docs) {
          final data =
          doc.data();

          final uid =
          data['uid']?.toString();

          if (uid == null ||
              uid.isEmpty) {
            continue;
          }

          results[uid] = data;
        }
      }

      final emailKeys =
      batchKeys
          .where(
            (key) =>
            key.startsWith('e_'),
      )
          .toList();

      if (emailKeys.isNotEmpty) {
        final snapshot =
        await _directory
            .where(
          'emailLookupKey',
          whereIn: emailKeys,
        )
            .get();

        for (final doc
        in snapshot.docs) {
          final data =
          doc.data();

          final uid =
          data['uid']?.toString();

          if (uid == null ||
              uid.isEmpty) {
            continue;
          }

          results[uid] = data;
        }
      }
    }

    return results;
  }

  // ============================================================
  // LOOKUP HELPERS
  // ============================================================

  static String phoneLookupKey(
      String phone,
      ) {
    if (phone.trim().isEmpty) {
      return '';
    }

    return _phoneLookupKey(phone);
  }

  static String emailLookupKey(
      String email,
      ) {
    if (email.trim().isEmpty) {
      return '';
    }

    return _emailLookupKey(email);
  }

  Future<Map<String, dynamic>>
  getUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return {};
    }

    final snapshot =
    await _users.doc(user.uid).get();

    return snapshot.data() ?? {};
  }



}