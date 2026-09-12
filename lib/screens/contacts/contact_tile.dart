import 'package:flutter/material.dart';
import '../../models/contact_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactTile extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback? onAudioCall;
  final VoidCallback? onVideoCall;
  final VoidCallback? onInvite;

  const ContactTile({
    super.key,
    required this.contact,
    this.onAudioCall,
    this.onVideoCall,
    this.onInvite,
  });

  String get _displayName {
    if (contact.name.trim().isNotEmpty) {
      return contact.name;
    }

    return contact.phoneNumber ?? 'Unknown';
  }

  String get _initial {
    if (contact.name.trim().isEmpty) {
      return '';
    }

    return contact.name
        .trim()
        .substring(0, 1)
        .toUpperCase();
  }

  Color _avatarColor(BuildContext context) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
    ];

    final index =
        _displayName.codeUnitAt(0) %
            colors.length;

    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currentUid =
        FirebaseAuth.instance.currentUser?.uid;
    final isSelf =
        contact.uid != null &&
            contact.uid == currentUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest
            .withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
// ------------------------------------------------------
// AVATAR
// ------------------------------------------------------

          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor:
                contact.name.trim().isEmpty
                    ? Colors.grey.shade400
                    : _avatarColor(context),
                child: contact.name.trim().isEmpty
                    ? const Icon(
                  Icons.person,
                  color: Colors.white,
                )
                    : Text(
                  _initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              if (contact.isRegistered)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: contact.isOnline
                          ? Colors.green
                          : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

// ------------------------------------------------------
// NAME + STATUS
// ------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      contact.isRegistered
                          ? Icons.verified
                          : Icons.person_outline,
                      size: 15,
                      color: contact.isRegistered
                          ? Colors.green
                          : scheme.onSurface
                          .withOpacity(0.55),
                    ),

                    const SizedBox(width: 4),

                    Text(
                      contact.isRegistered
                          ? 'Verified'
                          : 'Not verified',
                      style:
                      theme.textTheme.bodySmall
                          ?.copyWith(
                        color:
                        contact.isRegistered
                            ? Colors.green
                            : scheme
                            .onSurface
                            .withOpacity(
                          0.55,
                        ),
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

// ------------------------------------------------------
// ACTIONS
// ------------------------------------------------------

          if (contact.isRegistered && !isSelf)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _roundActionButton(
                  context,
                  icon: Icons.call_rounded,
                  onPressed: onAudioCall,
                ),

                const SizedBox(width: 7),

                _roundActionButton(
                  context,
                  icon: Icons.videocam_rounded,
                  onPressed: onVideoCall,
                ),
              ],
            )
          else if (contact.isRegistered && isSelf)
            Icon(
              Icons.person_rounded,
              size: 23,
              color: scheme.onSurfaceVariant,
            )
          else
            _roundActionButton(
              context,
              icon: Icons.person_add_alt_1_rounded,
              onPressed: onInvite,
            ),
        ],
      ),
    );
  }

  Widget _roundActionButton(
      BuildContext context, {
        required IconData icon,
        required VoidCallback? onPressed,
      }) {
    final scheme =
        Theme.of(context).colorScheme;

    return Material(
      color: scheme.primary.withOpacity(0.10),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            icon,
            size: 19,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}
