import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../calls/video_call_preview_page.dart';
import '../../models/call_model.dart';
import '../../models/contact_model.dart';
import '../../services/auth_service.dart';
import '../../services/call_service.dart';
import '../../services/contact_service.dart';
import '../../services/user_service.dart';
import '../../services/zego_call_service.dart';
import '../auth/login_page.dart';
import '../calls/calls_page.dart';
import '../contacts/contact_tile.dart';
import '../contacts/contacts_page.dart';
import '../profile/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final CallService _callService =
      CallService.instance;

  final ContactService _contactService =
      ContactService.instance;

  final UserService _userService =
      UserService.instance;

  final ZegoCallService _zegoCallService =
      ZegoCallService.instance;

  List<ContactModel> _contacts = [];

  bool _contactsLoading = true;

  bool _refreshing = false;

  bool _recentCallsExpanded = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addObserver(this);

    _initializeHome();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeHome() async {
    try {
      await _userService
          .ensureCurrentUserDirectory();

      await _userService
          .updatePresence(true);

      await _zegoCallService
          .initializeForCurrentUser();

      await _refreshHome();
    } catch (e) {
      debugPrint(
        'Home initialization error: $e',
      );

      await _refreshHome();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshHome() async {
    if (_refreshing) {
      return;
    }

    _refreshing = true;

    if (mounted) {
      setState(() {
        _contactsLoading = true;
      });
    }

    try {
      await _userService
          .updatePresence(true);

      final contacts =
      await _contactService
          .getContacts();

      if (!mounted) {
        _refreshing = false;
        return;
      }

      setState(() {
        _contacts = contacts;
        _contactsLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Failed to refresh Ringr home: $e',
      );

      if (mounted) {
        setState(() {
          _contactsLoading = false;
        });
      }
    }

    _refreshing = false;
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state ==
        AppLifecycleState.resumed) {
      _userService
          .updatePresence(true);

      _refreshHome();
    } else if (state ==
        AppLifecycleState.paused ||
        state ==
            AppLifecycleState.inactive ||
        state ==
            AppLifecycleState.hidden) {
      _userService
          .updatePresence(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    super.dispose();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await _userService
        .updatePresence(false);

    await _zegoCallService.logout();

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
  // NAVIGATION
  // ============================================================

  void _onNavigationChanged(
      int index,
      ) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      _refreshHome();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final pages = [
      _buildHomePage(),
      const ContactsPage(),
      const CallsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar:
      NavigationBar(
        selectedIndex:
        _selectedIndex,
        onDestinationSelected:
        _onNavigationChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.people_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.people_rounded,
            ),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.call_outlined,
            ),
            selectedIcon: Icon(
              Icons.call_rounded,
            ),
            label: 'Calls',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.person_rounded,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget _buildHomePage() {
    final user =
        FirebaseAuth.instance.currentUser;

    final homeContacts =
    _contacts.take(10).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshHome,
        child: CustomScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text(
                'Ringr',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  onPressed:
                  _refreshHome,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  onPressed: _logout,
                  icon: const Icon(
                    Icons.logout_rounded,
                  ),
                ),
              ],
            ),

            SliverPadding(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                24,
              ),
              sliver: SliverList(
                delegate:
                SliverChildListDelegate(
                  [
                    _buildProfileTile(
                      user,
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    _buildRecentCallsSection(),

                    const SizedBox(
                      height: 22,
                    ),

                    _sectionHeader(
                      title: 'Contacts',
                      onSeeAll: () {
                        setState(() {
                          _selectedIndex =
                          1;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    if (_contactsLoading)
                      const Padding(
                        padding:
                        EdgeInsets.all(28),
                        child: Center(
                          child:
                          CircularProgressIndicator(),
                        ),
                      )
                    else if (homeContacts
                        .isEmpty)
                      _emptyCard(
                        icon: Icons
                            .people_outline,
                        text:
                        'No contacts yet',
                      )
                    else
                      ...homeContacts.map(
                            (contact) =>
                            ContactTile(
                              contact: contact,

                              onAudioCall:
                              contact.isRegistered
                                  ? () =>
                                  _startAudioCall(
                                    contact,
                                  )
                                  : null,

                              onVideoCall:
                              contact.isRegistered
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
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE TILE
  // ============================================================

  Widget _buildProfileTile(
      User? user,
      ) {
    final scheme =
        Theme.of(context)
            .colorScheme;

    final name =
    user?.displayName?.trim();

    final displayName =
    name == null ||
        name.isEmpty
        ? 'User'
        : name;

    final initial =
    displayName
        .substring(0, 1)
        .toUpperCase();

    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        gradient:
        LinearGradient(
          colors: [
            scheme.primary,
            scheme.primary
                .withOpacity(0.72),
          ],
        ),
        borderRadius:
        BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor:
            Colors.white
                .withOpacity(0.20),
            backgroundImage:
            user?.photoURL != null
                ? NetworkImage(
              user!.photoURL!,
            )
                : null,
            child:
            user?.photoURL == null
                ? Text(
              initial,
              style:
              const TextStyle(
                color:
                Colors.white,
                fontSize: 24,
                fontWeight:
                FontWeight.bold,
              ),
            )
                : null,
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
                  displayName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  user?.email ??
                      'No email available',
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(
                      0.78,
                    ),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                _selectedIndex = 3;
              });
            },
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT CALLS
  // ============================================================

  Widget _buildRecentCallsSection() {
    return AnimatedBuilder(
      animation: _callService,
      builder: (
          context,
          _,
          ) {
        final recentCalls =
        _callService
            .getRecentCalls();

        return Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Recent calls',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const Spacer(),

                IconButton(
                  tooltip:
                  _recentCallsExpanded
                      ? 'Hide recent calls'
                      : 'Show recent calls',
                  onPressed: () {
                    setState(() {
                      _recentCallsExpanded =
                      !_recentCallsExpanded;
                    });
                  },
                  icon: Icon(
                    _recentCallsExpanded
                        ? Icons
                        .keyboard_arrow_up_rounded
                        : Icons
                        .keyboard_arrow_down_rounded,
                  ),
                ),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex =
                      2;
                    });
                  },
                  child:
                  const Text(
                    'See all',
                  ),
                ),
              ],
            ),

            if (_recentCallsExpanded)
              const SizedBox(
                height: 10,
              ),

            if (_recentCallsExpanded)
              if (recentCalls.isEmpty)
                _emptyCard(
                  icon:
                  Icons.call_outlined,
                  text:
                  'No recent calls yet',
                )
              else
                ...recentCalls.map(
                  _buildCallTile,
                ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CALL TILE
  // ============================================================

  Widget _buildCallTile(CallModel call,) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isMissed =
        call.status == CallStatus.missed ||
            call.type == CallType.missed;

    final isFailed =
        call.status == CallStatus.failed ||
            call.status == CallStatus.rejected ||
            call.status == CallStatus.cancelled;

    final color = isMissed || isFailed
        ? Colors.red
        : call.status == CallStatus.connected ||
        call.status == CallStatus.ended
        ? Colors.green
        : scheme.primary;

    IconData callIcon;

    switch (call.status) {
      case CallStatus.missed:
        callIcon = Icons.call_missed_rounded;
        break;

      case CallStatus.rejected:
        callIcon = Icons.call_end_rounded;
        break;

      case CallStatus.busy:
        callIcon = Icons.phone_disabled_rounded;
        break;

      case CallStatus.failed:
        callIcon = Icons.error_outline_rounded;
        break;

      case CallStatus.cancelled:
        callIcon = Icons.call_end_rounded;
        break;

      case CallStatus.disconnected:
        callIcon =
            Icons.signal_cellular_connected_no_internet_0_bar_rounded;
        break;

      default:
        callIcon = call.type == CallType.incoming
            ? Icons.call_received_rounded
            : Icons.call_made_rounded;
    }

    final directionText =
    call.status == CallStatus.missed
        ? 'Missed'
        : call.status == CallStatus.rejected
        ? 'Rejected'
        : call.status == CallStatus.busy
        ? 'Busy'
        : call.status == CallStatus.failed
        ? 'Failed'
        : call.status == CallStatus.cancelled
        ? 'Cancelled'
        : call.type == CallType.incoming
        ? 'Incoming'
        : 'Outgoing';

    final modeText =
    call.mode == CallMode.video
        ? 'Video call'
        : 'Audio call';

    final durationText =
    call.duration > Duration.zero
        ? _formatDuration(call.duration)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest
            .withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ----------------------------------------------------------
          // CALL ICON
          // ----------------------------------------------------------

          CircleAvatar(
            radius: 24,
            backgroundColor:
            color.withOpacity(0.12),
            child: Icon(
              callIcon,
              color: color,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          // ----------------------------------------------------------
          // INFORMATION
          // ----------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  call.name,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Wrap(
                  spacing: 5,
                  runSpacing: 3,
                  crossAxisAlignment:
                  WrapCrossAlignment.center,
                  children: [
                    Icon(
                      callIcon,
                      size: 14,
                      color: color,
                    ),

                    Text(
                      directionText,
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: color,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    Text(
                      '•',
                      style: theme
                          .textTheme
                          .bodySmall,
                    ),

                    Text(
                      modeText,
                      style: theme
                          .textTheme
                          .bodySmall,
                    ),

                    if (durationText.isNotEmpty) ...[
                      Text(
                        '•',
                        style: theme
                            .textTheme
                            .bodySmall,
                      ),
                      Text(
                        durationText,
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  _formatDateTime(call.time),
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color:
                    scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ----------------------------------------------------------
          // TIME
          // ----------------------------------------------------------

          Text(
            _formatTime(call.time),
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
              color:
              scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CALL HELPERS
  // ============================================================

  IconData _callIcon(
      CallModel call,
      ) {
    switch (call.status) {
      case CallStatus.missed:
        return Icons
            .call_missed_rounded;

      case CallStatus.rejected:
        return Icons
            .call_end_rounded;

      case CallStatus.busy:
        return Icons
            .phone_disabled_rounded;

      case CallStatus.failed:
        return Icons
            .error_outline_rounded;

      case CallStatus.cancelled:
        return Icons
            .cancel_outlined;

      default:
        return _callDirectionIcon(
          call,
        );
    }
  }

  IconData _callDirectionIcon(
      CallModel call,
      ) {
    return call.type ==
        CallType.incoming
        ? Icons
        .call_received_rounded
        : Icons
        .call_made_rounded;
  }

  String _directionText(
      CallModel call,
      ) {
    if (call.type ==
        CallType.incoming) {
      return 'Incoming';
    }

    return 'Outgoing';
  }

  String _statusText(
      CallStatus status,
      ) {
    switch (status) {
      case CallStatus.calling:
        return 'Calling';
      case CallStatus.ringing:
        return 'Ringing';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Ended';
      case CallStatus.rejected:
        return 'Rejected';
      case CallStatus.missed:
        return 'Missed';
      case CallStatus.busy:
        return 'Busy';
      case CallStatus.failed:
        return 'Failed';
      case CallStatus.disconnected:
        return 'Disconnected';
      case CallStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDuration(Duration duration,) {
    if (duration <= Duration.zero) {
      return '';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time,) {
    final hour =
    time.hour % 12 == 0
        ? 12
        : time.hour % 12;

    final minute =
    time.minute
        .toString()
        .padLeft(2, '0');

    final period =
    time.hour >= 12
        ? 'PM'
        : 'AM';

    return '$hour:$minute $period';
  }

  String _formatDateTime(DateTime time,) {
    final now = DateTime.now();

    final sameDay =
        now.year == time.year &&
            now.month == time.month &&
            now.day == time.day;

    if (sameDay) {
      return _formatTime(time);
    }

    final yesterday =
    now.subtract(
      const Duration(days: 1),
    );

    final isYesterday =
        yesterday.year == time.year &&
            yesterday.month == time.month &&
            yesterday.day == time.day;

    if (isYesterday) {
      return 'Yesterday, ${_formatTime(time)}';
    }

    return '${time.day}/${time.month}/${time.year}, '
        '${_formatTime(time)}';
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _sectionHeader({
    required String title,
    required VoidCallback onSeeAll,
  }) {
    return Row(
      children: [
        Text(
          title,
          style:
          const TextStyle(
            fontSize: 20,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed:
          onSeeAll,
          child:
          const Text(
            'See all',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyCard({
    required IconData icon,
    required String text,
  }) {
    final scheme =
        Theme.of(context)
            .colorScheme;

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        28,
      ),
      decoration:
      BoxDecoration(
        color: scheme
            .surfaceContainerHighest
            .withOpacity(0.4),
        borderRadius:
        BorderRadius.circular(
          18,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 38,
            color: scheme
                .onSurface
                .withOpacity(
              0.35,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(text),
        ],
      ),
    );
  }

  // ============================================================
  // AUDIO CALL
  // ============================================================

  Future<void> _startAudioCall(
      ContactModel contact,
      ) async {
    final currentUid =
        FirebaseAuth
            .instance
            .currentUser
            ?.uid;

    if (contact.uid == null ||
        contact.uid!.isEmpty) {
      _showMessage(
        'This contact cannot be called.',
      );
      return;
    }

    if (contact.uid ==
        currentUid) {
      _showMessage(
        'You cannot call yourself.',
      );
      return;
    }

    final success =
    await _zegoCallService
        .startAudioCall(
      uid: contact.uid!,
      name: contact.name,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        'Audio call could not be sent.',
      );
      return;
    }

    _showMessage(
      'Calling ${contact.name}...',
    );
  }

  // ============================================================
  // VIDEO CALL
  // ============================================================

  Future<void> _startVideoCall(
      ContactModel contact,
      ) async {
    final currentUid =
        FirebaseAuth
            .instance
            .currentUser
            ?.uid;

    if (contact.uid == null ||
        contact.uid!.isEmpty) {
      _showMessage(
        'This contact cannot be called.',
      );
      return;
    }

    if (contact.uid ==
        currentUid) {
      _showMessage(
        'You cannot call yourself.',
      );
      return;
    }

    await Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) =>
            VideoCallPreviewPage(
              contact: contact,
            ),
      ),
    );
  }

  // ============================================================
  // INVITE
  // ============================================================

  void _inviteContact(
      ContactModel contact,
      ) {
    _showMessage(
      'Invite sent to '
          '${contact.phoneNumber ?? contact.name}',
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
      ),
    );
  }
}