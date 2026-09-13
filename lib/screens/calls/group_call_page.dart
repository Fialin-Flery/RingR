import 'package:flutter/material.dart';

import '../../models/contact_model.dart';
import '../../services/zego_call_service.dart';
import 'group_video_preview_page.dart';

class GroupCallPage extends StatefulWidget {
  final List<ContactModel> contacts;

  const GroupCallPage({
    super.key,
    required this.contacts,
  });

  @override
  State<GroupCallPage> createState() =>
      _GroupCallPageState();
}

class _GroupCallPageState
    extends State<GroupCallPage> {
  final Set<String> _selectedUids = {};

  List<ContactModel> get _registeredContacts {
    return widget.contacts
        .where(
          (contact) =>
      contact.isRegistered &&
          contact.uid != null &&
          contact.uid!.isNotEmpty,
    )
        .toList();
  }

  List<ContactModel> get _selectedContacts {
    return _registeredContacts
        .where(
          (contact) =>
          _selectedUids.contains(
            contact.uid,
          ),
    )
        .toList();
  }

  void _toggle(ContactModel contact) {
    final uid = contact.uid;

    if (uid == null || uid.isEmpty) {
      return;
    }

    setState(() {
      if (_selectedUids.contains(uid)) {
        _selectedUids.remove(uid);
      } else {
        _selectedUids.add(uid);
      }
    });
  }

  List<ContactCallTarget>
  _buildParticipants() {
    return _selectedContacts
        .map(
          (contact) =>
          ContactCallTarget(
            uid: contact.uid!,
            name: contact.name,
          ),
    )
        .toList();
  }

  Future<void> _startAudio() async {
    if (_selectedUids.length < 2) {
      _showMessage(
        'Select at least 2 people.',
      );
      return;
    }

    final success =
    await ZegoCallService.instance
        .startGroupAudioCall(
      participants:
      _buildParticipants(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      _showMessage(
        'Group audio call could not be started.',
      );
    }
  }

  Future<void> _startVideo() async {
    if (_selectedUids.length < 2) {
      _showMessage(
        'Select at least 2 people.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GroupVideoPreviewPage(
              participants:
              _buildParticipants(),
            ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final contacts =
        _registeredContacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Group call',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: contacts.isEmpty
          ? const Center(
        child: Text(
          'No registered Ringr contacts available.',
        ),
      )
          : Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              8,
            ),
            child: Align(
              alignment:
              Alignment.centerLeft,
              child: Text(
                '${_selectedUids.length} selected',
                style: theme
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                4,
                18,
                120,
              ),
              itemCount:
              contacts.length,
              itemBuilder:
                  (context, index) {
                final contact =
                contacts[index];

                final uid =
                contact.uid!;

                final selected =
                _selectedUids
                    .contains(uid);

                final name =
                contact.name
                    .trim()
                    .isEmpty
                    ? contact.phoneNumber ??
                    'Ringr User'
                    : contact.name;

                return Card(
                  margin:
                  const EdgeInsets
                      .only(
                    bottom: 8,
                  ),
                  child: ListTile(
                    onTap: () =>
                        _toggle(
                          contact,
                        ),
                    leading:
                    CircleAvatar(
                      child: Text(
                        name
                            .substring(
                          0,
                          1,
                        )
                            .toUpperCase(),
                      ),
                    ),
                    title: Text(name),
                    subtitle: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                          BoxDecoration(
                            shape:
                            BoxShape
                                .circle,
                            color:
                            contact
                                .isOnline
                                ? Colors
                                .green
                                : scheme
                                .onSurface
                                .withOpacity(
                              0.3,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Text(
                          contact.isOnline
                              ? 'Online'
                              : 'Offline',
                        ),
                      ],
                    ),
                    trailing:
                    Checkbox(
                      value: selected,
                      onChanged: (_) =>
                          _toggle(
                            contact,
                          ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar:
      contacts.isEmpty
          ? null
          : SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.all(
            16,
          ),
          child: Row(
            children: [
              Expanded(
                child:
                FilledButton.icon(
                  onPressed:
                  _selectedUids
                      .length >=
                      2
                      ? _startAudio
                      : null,
                  icon: const Icon(
                    Icons
                        .call_rounded,
                  ),
                  label: const Text(
                    'Audio',
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                FilledButton.icon(
                  onPressed:
                  _selectedUids
                      .length >=
                      2
                      ? _startVideo
                      : null,
                  icon: const Icon(
                    Icons
                        .videocam_rounded,
                  ),
                  label: const Text(
                    'Video',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}