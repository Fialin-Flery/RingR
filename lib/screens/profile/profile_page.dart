import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends State<ProfilePage> {
  Map<String, dynamic>? _profile;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      final snapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        _profile = snapshot.data();
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'Failed to load profile: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final currentName =
    (_profile?['name'] ??
        user.displayName ??
        '')
        .toString();

    final currentPhone =
    (_profile?['phone'] ?? '')
        .toString();

    final result =
    await showModalBottomSheet<_EditProfileResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor:
      Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return _EditProfileSheet(
          currentName: currentName,
          currentPhone: currentPhone,
          email: user.email ?? '',
        );
      },
    );

    // User cancelled / closed the sheet.
    if (result == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      debugPrint(
        '===== RINGR EDIT PROFILE =====',
      );

      debugPrint(
        'Updating name: ${result.name}',
      );

      debugPrint(
        'Updating phone: ${result.phone}',
      );

      await UserService.instance.updateUserProfile(
        name: result.name,
        phone: result.phone,
      );

      debugPrint(
        'Profile update successful.',
      );

      await _loadProfile();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint(
        '===== EDIT PROFILE ERROR =====',
      );

      debugPrint(
        'ERROR: $e',
      );

      debugPrint(
        'STACK TRACE:',
      );

      debugPrint(
        '$stack',
      );

      debugPrint(
        '==============================',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          duration:
          const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(
      BuildContext context) async {
    await UserService.instance
        .updatePresence(false);

    await AuthService.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const LoginPage(),
      ),
          (_) => false,
    );
  }

  // ============================================================
  // INITIAL
  // ============================================================

  String _initial(User? user) {
    final name =
    (_profile?['name'] ??
        user?.displayName ??
        '')
        .toString()
        .trim();

    if (name.isEmpty) {
      return '?';
    }

    return name
        .substring(0, 1)
        .toUpperCase();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context) {
    final theme =
    Theme.of(context);

    final scheme =
        theme.colorScheme;

    final user =
        FirebaseAuth.instance.currentUser;

    final name =
    (_profile?['name'] ??
        user?.displayName ??
        'User')
        .toString();

    final email =
    (_profile?['email'] ??
        user?.email ??
        'No email available')
        .toString();

    final phone =
    (_profile?['phone'] ?? '')
        .toString()
        .trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(20),
          children: [
            // ------------------------------------------------
            // PROFILE HEADER
            // ------------------------------------------------

            Container(
              padding:
              const EdgeInsets.all(22),
              decoration:
              BoxDecoration(
                color: scheme.primary
                    .withOpacity(0.08),
                borderRadius:
                BorderRadius.circular(
                  24,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor:
                    scheme.primary,
                    backgroundImage:
                    user?.photoURL !=
                        null
                        ? NetworkImage(
                      user!
                          .photoURL!,
                    )
                        : null,
                    child:
                    user?.photoURL ==
                        null
                        ? Text(
                      _initial(
                        user,
                      ),
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize:
                        30,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    )
                        : null,
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Text(
                    name,
                    style: theme
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    email,
                    style: theme
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: scheme
                          .onSurface
                          .withOpacity(
                        0.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'Profile details',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            _detailTile(
              context,
              icon:
              Icons.person_outline,
              title: 'Name',
              value: name.isEmpty
                  ? 'Not available'
                  : name,
            ),

            _detailTile(
              context,
              icon:
              Icons.email_outlined,
              title: 'Email',
              value: email.isEmpty
                  ? 'Not available'
                  : email,
            ),

            _detailTile(
              context,
              icon:
              Icons.phone_outlined,
              title: 'Phone',
              value: phone.isEmpty
                  ? 'Not added'
                  : phone,
            ),

            const SizedBox(
              height: 18,
            ),

            SizedBox(
              height: 50,
              child:
              OutlinedButton.icon(
                onPressed:
                _saving
                    ? null
                    : _editProfile,
                icon: const Icon(
                  Icons.edit_outlined,
                ),
                label: const Text(
                  'Edit profile',
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            SizedBox(
              height: 50,
              child:
              OutlinedButton.icon(
                onPressed: () =>
                    _logout(context),
                icon: const Icon(
                  Icons.logout_rounded,
                ),
                label: const Text(
                  'Logout',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL TILE
  // ============================================================

  Widget _detailTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
      }) {
    final scheme =
        Theme.of(context)
            .colorScheme;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: scheme
            .surfaceContainerHighest
            .withOpacity(0.45),
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: scheme.primary,
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  )
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: scheme
                        .onSurface
                        .withOpacity(
                      0.55,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  )
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EDIT PROFILE RESULT
// ============================================================

class _EditProfileResult {
  final String name;
  final String phone;

  const _EditProfileResult({
    required this.name,
    required this.phone,
  });
}


// ============================================================
// EDIT PROFILE BOTTOM SHEET
// ============================================================

class _EditProfileSheet extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String email;

  const _EditProfileSheet({
    required this.currentName,
    required this.currentPhone,
    required this.email,
  });

  @override
  State<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}


class _EditProfileSheetState
    extends State<_EditProfileSheet> {

  final _formKey =
  GlobalKey<FormState>();

  late final TextEditingController
  _nameController;

  late final TextEditingController
  _phoneController;


  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(
          text: widget.currentName,
        );

    _phoneController =
        TextEditingController(
          text: widget.currentPhone,
        );
  }


  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();

    super.dispose();
  }


  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name =
    _nameController.text.trim();

    final phone =
    _phoneController.text.trim();

    Navigator.pop(
      context,
      _EditProfileResult(
        name: name,
        phone: phone,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final scheme =
        theme.colorScheme;

    final mediaQuery =
    MediaQuery.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom:
          mediaQuery.viewInsets.bottom + 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
            mediaQuery.size.height * 0.85,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  // ==================================================
                  // TITLE
                  // ==================================================

                  Text(
                    'Edit profile',
                    style: theme
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),


                  // ==================================================
                  // NAME
                  // ==================================================

                  TextFormField(
                    controller:
                    _nameController,
                    textCapitalization:
                    TextCapitalization.words,
                    decoration:
                    const InputDecoration(
                      labelText: 'Name',
                      prefixIcon:
                      Icon(
                        Icons.person_outline,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your name';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),


                  // ==================================================
                  // PHONE
                  // ==================================================

                  TextFormField(
                    controller:
                    _phoneController,
                    keyboardType:
                    TextInputType.phone,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Phone number',
                      prefixIcon:
                      Icon(
                        Icons.phone_outlined,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),


                  // ==================================================
                  // EMAIL
                  // ==================================================

                  TextFormField(
                    initialValue:
                    widget.email,
                    readOnly: true,
                    decoration:
                    const InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                      Icon(
                        Icons.email_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),


                  // ==================================================
                  // SAVE
                  // ==================================================

                  SizedBox(
                    width:
                    double.infinity,
                    height: 52,
                    child:
                    FilledButton(
                      onPressed:
                      _save,
                      child:
                      const Text(
                        'Save changes',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),


                  // ==================================================
                  // CANCEL
                  // ==================================================

                  SizedBox(
                    width:
                    double.infinity,
                    height: 48,
                    child:
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      child:
                      const Text(
                        'Cancel',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}