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
  final UserService _userService =
      UserService.instance;

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
      await _userService
          .userProfileExists(
        user.uid,
      );

      if (!snapshot) {
        if (mounted) {
          setState(() {
            _profile = {};
            _loading = false;
          });
        }

        return;
      }

      // Fetch profile through Firestore indirectly
      // using the existing users collection.
      final profile =
      await _getProfileData();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'Failed to load profile: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>>
  _getProfileData() async {
    // Importing Firestore only here keeps the
    // rest of the page focused on UI.
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {};
    }

    final snapshot =
    await UserService.instance
        .getUserProfile();

    return snapshot;
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  Future<void> _editProfile() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final nameController =
    TextEditingController(
      text: (_profile?['name'] ??
          user.displayName ??
          '')
          .toString(),
    );

    final phoneController =
    TextEditingController(
      text: (_profile?['phone'] ?? '')
          .toString(),
    );

    final formKey =
    GlobalKey<FormState>();

    final saved =
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
      Theme.of(context)
          .colorScheme
          .surface,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder:
              (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom:
                MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                    24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Edit profile',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(
                                  context,
                                  false,
                                ),
                            icon: const Icon(
                              Icons.close_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      TextFormField(
                        controller:
                        nameController,
                        textCapitalization:
                        TextCapitalization
                            .words,
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
                            return 'Enter your name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        initialValue:
                        user.email ?? '',
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
                        height: 16,
                      ),

                      TextFormField(
                        controller:
                        phoneController,
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
                            return 'Enter your phone number';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child:
                        ElevatedButton(
                          onPressed:
                          _saving
                              ? null
                              : () async {
                            if (!formKey
                                .currentState!
                                .validate()) {
                              return;
                            }

                            setSheetState(() {
                              _saving =
                              true;
                            });

                            try {
                              await _userService
                                  .updateUserProfile(
                                name:
                                nameController
                                    .text
                                    .trim(),
                                phone:
                                phoneController
                                    .text
                                    .trim(),
                              );

                              if (!context
                                  .mounted) {
                                return;
                              }

                              Navigator.pop(
                                context,
                                true,
                              );
                            } catch (e) {
                              setSheetState(() {
                                _saving =
                                false;
                              });

                              ScaffoldMessenger
                                  .of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content:
                                  Text(
                                    e
                                        .toString()
                                        .replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          child: _saving
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              2.2,
                              color:
                              Colors.white,
                            ),
                          )
                              : const Text(
                            'Save changes',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();

    if (saved == true) {
      await _loadProfile();
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await _userService
        .updatePresence(false);

    await AuthService.signOut();

    if (!mounted) {
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
      BuildContext context,
      ) {
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
        onRefresh:
        _loadProfile,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(20),
          children: [
            Container(
              padding:
              const EdgeInsets.all(
                22,
              ),
              decoration:
              BoxDecoration(
                color: scheme.primary
                    .withOpacity(
                  0.08,
                ),
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
                    textAlign:
                    TextAlign.center,
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
                    textAlign:
                    TextAlign.center,
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
              value: name,
            ),

            _detailTile(
              context,
              icon:
              Icons.email_outlined,
              title: 'Email',
              value: email,
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
                _editProfile,
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
                onPressed:
                _logout,
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
      decoration:
      BoxDecoration(
        color: scheme
            .surfaceContainerHighest
            .withOpacity(0.45),
        borderRadius:
        BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color:
            scheme.primary,
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