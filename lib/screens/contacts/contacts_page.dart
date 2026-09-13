import 'package:flutter/material.dart';

import '../../models/contact_model.dart';
import '../../services/contact_service.dart';
import 'contact_tile.dart';
import '../calls/group_call_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() =>
      _ContactsPageState();
}

class _ContactsPageState
    extends State<ContactsPage> {
  final ContactService _contactService =
      ContactService.instance;

  final TextEditingController
  _searchController =
  TextEditingController();

  List<ContactModel> _contacts = [];

  bool _isLoading = true;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _searchQuery =
            _searchController.text
                .trim()
                .toLowerCase();
      });
    });

    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final contacts =
      await _contactService
          .getContacts();

      if (!mounted) return;

      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Failed to load contacts: $e',
      );

      if (!mounted) return;

      setState(() {
        _contacts = [];
        _isLoading = false;
      });
    }
  }

  List<ContactModel>
  get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return _contacts;
    }

    return _contacts.where((contact) {
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

      return name.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          email.contains(_searchQuery);
    }).toList();
  }

  void _startAudioCall(
      ContactModel contact) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Starting audio call with ${contact.name}',
        ),
      ),
    );
  }

  void _startVideoCall(
      ContactModel contact) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Starting video call with ${contact.name}',
        ),
      ),
    );
  }

  void _inviteContact(
      ContactModel contact) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Invite sent to '
              '${contact.phoneNumber ?? contact.name}',
        ),
      ),
    );
  }

  Future<void> _openGroupCall() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GroupCallPage(
              contacts: _contacts,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    final filteredContacts =
        _filteredContacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contacts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Group call',
            onPressed:
            _isLoading
                ? null
                : _openGroupCall,
            icon: const Icon(
              Icons.group_add_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Refresh contacts',
            onPressed:
            _isLoading
                ? null
                : _loadContacts,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                14,
              ),
              child: TextField(
                controller:
                _searchController,
                textInputAction:
                TextInputAction.search,
                decoration:
                InputDecoration(
                  hintText:
                  'Search name, phone or email',
                  prefixIcon:
                  const Icon(
                    Icons.search_rounded,
                  ),
                  suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                    onPressed:
                        () {
                      _searchController
                          .clear();
                    },
                    icon:
                    const Icon(
                      Icons
                          .clear_rounded,
                    ),
                  )
                      : null,
                  filled: true,
                  fillColor: scheme
                      .surfaceContainerHighest
                      .withOpacity(0.45),
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                    borderSide:
                    BorderSide.none,
                  ),
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                child:
                CircularProgressIndicator(),
              )
                  : RefreshIndicator(
                onRefresh:
                _loadContacts,
                child:
                filteredContacts
                    .isEmpty
                    ? ListView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height:
                      MediaQuery.of(
                        context,
                      ).size.height *
                          0.25,
                    ),
                    _buildEmptyState(
                      context,
                    ),
                  ],
                )
                    : ListView.builder(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets.fromLTRB(
                    18,
                    4,
                    18,
                    24,
                  ),
                  itemCount:
                  filteredContacts
                      .length,
                  itemBuilder:
                      (
                      context,
                      index,
                      ) {
                    final contact =
                    filteredContacts[
                    index];

                    return ContactTile(
                      contact:
                      contact,
                      onAudioCall:
                      contact
                          .isRegistered
                          ? () =>
                          _startAudioCall(
                            contact,
                          )
                          : null,
                      onVideoCall:
                      contact
                          .isRegistered
                          ? () =>
                          _startVideoCall(
                            contact,
                          )
                          : null,
                      onInvite:
                      !contact
                          .isRegistered
                          ? () =>
                          _inviteContact(
                            contact,
                          )
                          : null,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    final hasSearch =
        _searchQuery.isNotEmpty;

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      child: Column(
        children: [
          Icon(
            hasSearch
                ? Icons.search_off_rounded
                : Icons.contacts_outlined,
            size: 58,
            color:
            scheme.onSurface
                .withOpacity(0.30),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'No contacts found'
                : 'No contacts yet',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
              FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try searching with a different name, phone number or email.'
                : 'Allow Ringr to access your contacts to find people you can connect with.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
              color:
              scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}