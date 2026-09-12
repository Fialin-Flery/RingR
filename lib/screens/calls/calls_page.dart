import 'package:flutter/material.dart';

import '../../models/call_model.dart';
import '../../services/call_service.dart';

class CallsPage extends StatelessWidget {
  const CallsPage({super.key});

  // ============================================================
  // TIME
  // ============================================================

  String _formatTime(
      DateTime time,
      ) {
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

  // ============================================================
  // DATE + TIME
  // ============================================================

  String _formatDateTime(
      DateTime time,
      ) {
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

    return '${time.day}/${time.month}/${time.year}'
        ', ${_formatTime(time)}';
  }

  // ============================================================
  // DURATION
  // ============================================================

  String _formatDuration(
      Duration duration,
      ) {
    if (duration <= Duration.zero) {
      return '';
    }

    final hours =
        duration.inHours;

    final minutes =
        duration.inMinutes % 60;

    final seconds =
        duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData _callIcon(
      CallModel call,
      ) {
    switch (call.status) {
      case CallStatus.calling:
        return Icons.call_made_rounded;

      case CallStatus.ringing:
        if (call.type ==
            CallType.incoming) {
          return Icons.call_received_rounded;
        }

        return Icons.call_made_rounded;

      case CallStatus.connected:
        return call.type ==
            CallType.incoming
            ? Icons.call_received_rounded
            : Icons.call_made_rounded;

      case CallStatus.ended:
        return call.type ==
            CallType.incoming
            ? Icons.call_received_rounded
            : Icons.call_made_rounded;

      case CallStatus.rejected:
        return Icons.call_end_rounded;

      case CallStatus.missed:
        return Icons.call_missed_rounded;

      case CallStatus.busy:
        return Icons.phone_disabled_rounded;

      case CallStatus.failed:
        return Icons.error_outline_rounded;

      case CallStatus.disconnected:
        return Icons.signal_cellular_connected_no_internet_0_bar_rounded;

      case CallStatus.cancelled:
        return Icons.call_end_rounded;
    }
  }

  // ============================================================
  // COLOR
  // ============================================================

  Color _callColor(
      BuildContext context,
      CallModel call,
      ) {
    final scheme =
        Theme.of(context).colorScheme;

    switch (call.status) {
      case CallStatus.missed:
      case CallStatus.rejected:
      case CallStatus.failed:
      case CallStatus.cancelled:
        return Colors.red;

      case CallStatus.busy:
        return Colors.orange;

      case CallStatus.connected:
        return Colors.green;

      default:
        return scheme.primary;
    }
  }

  // ============================================================
  // STATUS LABEL
  // ============================================================

  String _callLabel(
      CallModel call,
      ) {
    switch (call.status) {
      case CallStatus.calling:
        return 'Calling';

      case CallStatus.ringing:
        return 'Ringing';

      case CallStatus.connected:
        return 'Connected';

      case CallStatus.ended:
        return call.type ==
            CallType.incoming
            ? 'Incoming'
            : 'Outgoing';

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

  // ============================================================
  // CALL TYPE TEXT
  // ============================================================

  String _typeText(
      CallModel call,
      ) {
    if (call.status ==
        CallStatus.missed) {
      return 'Missed call';
    }

    if (call.status ==
        CallStatus.rejected) {
      return 'Rejected';
    }

    if (call.status ==
        CallStatus.busy) {
      return 'Busy';
    }

    if (call.status ==
        CallStatus.failed) {
      return 'Failed';
    }

    if (call.status ==
        CallStatus.cancelled) {
      return 'Cancelled';
    }

    if (call.status ==
        CallStatus.disconnected) {
      return 'Disconnected';
    }

    if (call.type ==
        CallType.incoming) {
      return 'Incoming';
    }

    return 'Outgoing';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calls',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListenableBuilder(
        listenable:
        CallService.instance,

        builder: (
            context,
            _,
            ) {
          final calls =
          CallService.instance
              .getCalls();

          if (calls.isEmpty) {
            return _buildEmptyState(
              context,
            );
          }

          return ListView.builder(
            padding:
            const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              30,
            ),
            itemCount:
            calls.length,
            itemBuilder: (
                context,
                index,
                ) {
              final call =
              calls[index];

              return _buildCallTile(
                context,
                call,
                theme,
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState(
      BuildContext context,
      ) {
    final scheme =
        Theme.of(context)
            .colorScheme;

    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration:
            BoxDecoration(
              color:
              scheme.primary
                  .withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.call_outlined,
              size: 34,
              color:
              scheme.primary,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            'No calls yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(
              fontWeight:
              FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            'Your Ringr call history will appear here.',
            textAlign:
            TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TILE
  // ============================================================

  Widget _buildCallTile(
      BuildContext context,
      CallModel call,
      ThemeData theme,
      ) {
    final color =
    _callColor(
      context,
      call,
    );

    final durationText =
    _formatDuration(
      call.duration,
    );

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
        color: theme
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.45),
        borderRadius:
        BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        children: [
          // ------------------------------------------------------
          // ICON
          // ------------------------------------------------------

          CircleAvatar(
            radius: 24,
            backgroundColor:
            color.withOpacity(
              0.12,
            ),
            child: Icon(
              _callIcon(call),
              color: color,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ------------------------------------------------------
          // DETAILS
          // ------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
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

                const SizedBox(
                  height: 5,
                ),

                Wrap(
                  crossAxisAlignment:
                  WrapCrossAlignment
                      .center,
                  spacing: 5,
                  runSpacing: 3,
                  children: [
                    Icon(
                      _callIcon(call),
                      size: 14,
                      color: color,
                    ),

                    Text(
                      _typeText(call),
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: color,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),

                    Text(
                      '•',
                      style: theme
                          .textTheme
                          .bodySmall,
                    ),

                    Text(
                      _callLabel(call),
                      style: theme
                          .textTheme
                          .bodySmall,
                    ),

                    if (durationText
                        .isNotEmpty)
                      Text(
                        '• $durationText',
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),

                    Icon(
                      call.mode ==
                          CallMode.video
                          ? Icons
                          .videocam_outlined
                          : Icons
                          .call_outlined,
                      size: 14,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  _formatDateTime(
                    call.time,
                  ),
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
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