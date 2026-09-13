import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../models/call_model.dart';
import 'call_service.dart';

class ZegoCallService {
  ZegoCallService._();

  static final ZegoCallService instance = ZegoCallService._();

// ============================================================
// ZEGOCLOUD PROJECT
// ============================================================

  static const int appID = 1532825529;

// IMPORTANT:
// This AppSign has already been exposed.
// Regenerate it before production.
  static const String appSign =
      'fe1e774fe9325328ff6b4c647553d00e785ff82857dc872a812a61e2190ef719';

// We will restore offline push configuration after
// basic online calling is confirmed working.
  static const String resourceID = 'ringr_call';

  bool _initialized = false;

// ============================================================
// ACTIVE CALL
// ============================================================

  String? _activeCallId;
  String? _activeRemoteUid;
  String? _activeRemoteName;

  bool _activeIsVideo = false;
  bool _activeIsGroup = false;

  CallType? _activeCallType;
  DateTime? _activeConnectedAt;

// ============================================================
// NOTIFICATION / OVERLAY PERMISSION
// ============================================================

  Future<void> requestNotificationPermission() async {
    try {
// Android 13+
      final notificationStatus =
      await Permission.notification.status;

      debugPrint(
        'Notification permission: $notificationStatus',
      );

      if (!notificationStatus.isGranted) {
        final result =
        await Permission.notification.request();

        debugPrint(
          'Notification permission result: $result',
        );
      }

// Android overlay permission.
//
// This will be needed later for the full-screen
// incoming-call UI.
      final overlayStatus =
      await Permission.systemAlertWindow.status;

      debugPrint(
        'System alert window permission: $overlayStatus',
      );

      if (!overlayStatus.isGranted) {
        final result =
        await Permission.systemAlertWindow.request();

        debugPrint(
          'System alert window result: $result',
        );
      }
    } catch (e) {
      debugPrint(
        'Call notification permission request failed: $e',
      );
    }
  }

// ============================================================
// INITIALIZE
// ============================================================

  Future<void> initializeForCurrentUser() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint(
        '❌ Zego initialization skipped: no Firebase user.',
      );
      return;
    }

    if (_initialized) {
      debugPrint(
        '✅ Zego already initialized.',
      );
      return;
    }

    await requestNotificationPermission();

    final userID =
    toZegoUserId(user.uid);

    final userName =
    user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : 'Ringr User';

    debugPrint('');
    debugPrint(
      '==================================================',
    );
    debugPrint(
      '===== ZEGOCLOUD INITIALIZATION START =====',
    );
    debugPrint(
      'Firebase UID: ${user.uid}',
    );
    debugPrint(
      'Zego UID: $userID',
    );
    debugPrint(
      'Zego UID length: ${userID.length}',
    );
    debugPrint(
      'Zego Name: $userName',
    );
    debugPrint(
      'App ID: $appID',
    );
    debugPrint(
      'Resource ID: $resourceID',
    );
    debugPrint(
      '==================================================',
    );

    try {
      await ZegoUIKitPrebuiltCallInvitationService()
          .init(
        appID: appID,
        appSign: appSign,
        userID: userID,
        userName: userName,

// --------------------------------------------------------
// SIGNALING PLUGIN
// --------------------------------------------------------

        plugins: [
          ZegoUIKitSignalingPlugin(),
        ],

// --------------------------------------------------------
// PERMISSIONS
// --------------------------------------------------------

        config: ZegoCallInvitationConfig(
          permissions: [
            ZegoCallInvitationPermission.microphone,
            ZegoCallInvitationPermission.camera,
            ZegoCallInvitationPermission.systemAlertWindow,
          ],
        ),

// --------------------------------------------------------
// IMPORTANT:
//
// Offline notificationConfig is intentionally disabled
// for this test.
//
// First we need to prove that the basic online call
// invitation works.
//
// Once that works, we will restore:
//
// ZegoCallInvitationNotificationConfig(...)
//
// with:
//
// showOnLockedScreen: true
// showOnFullScreen: true
//
// --------------------------------------------------------

// notificationConfig intentionally omitted.

// --------------------------------------------------------
// CALL CONFIGURATION
// --------------------------------------------------------

        requireConfig:
            (ZegoCallInvitationData data) {
          final isGroup =
              data.invitees.length > 1;

          if (isGroup) {
            if (data.type ==
                ZegoCallInvitationType.videoCall) {
              return ZegoUIKitPrebuiltCallConfig
                  .groupVideoCall();
            }

            return ZegoUIKitPrebuiltCallConfig
                .groupVoiceCall();
          }

          if (data.type ==
              ZegoCallInvitationType.videoCall) {
            return ZegoUIKitPrebuiltCallConfig
                .oneOnOneVideoCall();
          }

          return ZegoUIKitPrebuiltCallConfig
              .oneOnOneVoiceCall();
        },

// --------------------------------------------------------
// INVITATION EVENTS
// --------------------------------------------------------

        invitationEvents:
        ZegoUIKitPrebuiltCallInvitationEvents(

// ======================================================
// INCOMING CALL
// ======================================================

          onIncomingCallReceived: (
              String callID,
              ZegoCallUser caller,
              ZegoCallInvitationType callType,
              List<ZegoCallUser> callees,
              String customData,
              ) async {
            debugPrint(
              '📞 Incoming call received: $callID',
            );

            final isVideo =
                callType ==
                    ZegoCallInvitationType.videoCall;

            bool isGroup = false;

            String remoteUid = caller.id;
            String remoteName = caller.name;

            try {
              final data =
              jsonDecode(customData);

              if (data is Map) {
                isGroup =
                    data['groupCall'] == true;

                remoteUid =
                    data['callerUid']?.toString() ??
                        remoteUid;
              }
            } catch (_) {}

            _activeCallId = callID;
            _activeRemoteUid = remoteUid;
            _activeRemoteName =
            isGroup
                ? 'Group call'
                : remoteName;

            _activeIsVideo = isVideo;
            _activeIsGroup = isGroup;
            _activeCallType =
                CallType.incoming;
            _activeConnectedAt = null;

            await CallService.instance
                .addOrUpdateCall(
              CallModel(
                callId: callID,
                name:
                isGroup
                    ? 'Group call'
                    : remoteName,
                uid:
                isGroup
                    ? null
                    : remoteUid,
                phoneNumber: null,
                type: CallType.incoming,
                status: CallStatus.ringing,
                mode:
                isVideo
                    ? CallMode.video
                    : CallMode.audio,
                time: DateTime.now(),
                duration: Duration.zero,
              ),
            );
          },

// ======================================================
// INCOMING ACCEPTED
// ======================================================

          onIncomingCallAcceptButtonPressed:
              () async {
            debugPrint(
              '✅ Incoming call accepted.',
            );

            final callID =
                _activeCallId;

            if (callID == null) {
              return;
            }

            _activeConnectedAt =
                DateTime.now();

            await CallService.instance
                .updateStatus(
              callID,
              CallStatus.connected,
              connectedAt:
              _activeConnectedAt,
            );
          },

// ======================================================
// INCOMING DECLINED
// ======================================================

          onIncomingCallDeclineButtonPressed:
              () async {
            debugPrint(
              '❌ Incoming call declined.',
            );

            final callID =
                _activeCallId;

            if (callID == null) {
              return;
            }

            await CallService.instance
                .finishCall(
              callId: callID,
              status: CallStatus.rejected,
            );

            _clearActiveCall();
          },

// ======================================================
// INCOMING TIMEOUT / MISSED
// ======================================================

          onIncomingCallTimeout: (
              String callID,
              ZegoCallUser caller,
              ) async {
            debugPrint(
              '⏱️ Incoming call missed: $callID',
            );

            await CallService.instance
                .finishCall(
              callId: callID,
              status: CallStatus.missed,
            );

            _clearActiveCall();
          },

// ======================================================
// CALLER CANCELLED
// ======================================================

          onIncomingCallCanceled: (
              String callID,
              ZegoCallUser caller,
              String customData,
              ) async {
            debugPrint(
              '🚫 Incoming call cancelled: $callID',
            );

            await CallService.instance
                .finishCall(
              callId: callID,
              status: CallStatus.cancelled,
            );

            _clearActiveCall();
          },

// ======================================================
// OUTGOING SENT
// ======================================================

          onOutgoingCallSent: (
              String callID,
              ZegoCallUser caller,
              ZegoCallInvitationType callType,
              List<ZegoCallUser> callees,
              String customData,
              ) {
            debugPrint(
              '📤 Outgoing invitation sent: $callID',
            );
            debugPrint(
              '📤 Callees: ${callees.length}',
            );
          },

// ======================================================
// OUTGOING ACCEPTED
// ======================================================

          onOutgoingCallAccepted: (
              String callID,
              ZegoCallUser callee,
              ) async {
            debugPrint(
              '✅ Outgoing call accepted: $callID',
            );

            _activeConnectedAt =
                DateTime.now();

            await CallService.instance
                .updateStatus(
              callID,
              CallStatus.connected,
              connectedAt:
              _activeConnectedAt,
            );
          },

// ======================================================
// OUTGOING DECLINED
// ======================================================

          onOutgoingCallDeclined: (
              String callID,
              ZegoCallUser callee,
              String customData,
              ) async {
            debugPrint(
              '❌ Outgoing call declined: $callID',
            );

            await CallService.instance
                .finishCall(
              callId: callID,
              status: CallStatus.rejected,
            );

            _clearActiveCall();
          },

// ======================================================
// OUTGOING BUSY
// ======================================================

          onOutgoingCallRejectedCauseBusy: (
              String callID,
              ZegoCallUser callee,
              String customData,
              ) async {
            debugPrint(
              '📵 Outgoing call busy: $callID',
            );

            await CallService.instance
                .finishCall(
              callId: callID,
              status: CallStatus.busy,
            );

            _clearActiveCall();
          },

// ======================================================
// OUTGOING TIMEOUT
// ======================================================

          onOutgoingCallTimeout: (
              String callID,
              List<ZegoCallUser> callees,
              bool isVideoCall,
              ) async {
            debugPrint(
              '⏱️ Outgoing call timeout: $callID',
            );

            await CallService.instance
                .finishCall(
              callId: callID,
              status: CallStatus.missed,
            );

            _clearActiveCall();
          },
        ),

// --------------------------------------------------------
// ACTUAL CALL EVENTS
// --------------------------------------------------------

        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (
              ZegoCallEndEvent event,
              VoidCallback defaultAction,
              ) async {
            final callID =
                event.callID;

            debugPrint(
              '📴 Zego call ended: $callID',
            );

            final existingCall =
            CallService.instance
                .getCall(callID);

            if (existingCall != null) {
              Duration duration =
                  existingCall.duration;

              if (_activeConnectedAt != null) {
                duration =
                    DateTime.now()
                        .difference(
                      _activeConnectedAt!,
                    );

                if (duration.isNegative) {
                  duration =
                      Duration.zero;
                }
              }

              await CallService.instance
                  .addOrUpdateCall(
                existingCall.copyWith(
                  status: CallStatus.ended,
                  endedAt: DateTime.now(),
                  duration: duration,
                ),
              );
            }

            _clearActiveCall();

            defaultAction();
          },
        ),
      );

      _initialized = true;

      debugPrint('');
      debugPrint(
        '==================================================',
      );
      debugPrint(
        '✅ ZEGOCLOUD INITIALIZED SUCCESSFULLY',
      );
      debugPrint(
        'Zego UID: $userID',
      );
      debugPrint(
        'Online call invitations are now ready.',
      );
      debugPrint(
        '==================================================',
      );
      debugPrint('');
    } catch (e, stack) {
      _initialized = false;

      debugPrint('');
      debugPrint(
        '==================================================',
      );
      debugPrint(
        '❌ ZEGOCLOUD INITIALIZATION FAILED',
      );
      debugPrint('$e');
      debugPrint('$stack');
      debugPrint(
        '==================================================',
      );
      debugPrint('');

      rethrow;
    }
  }

// ============================================================
// ONE-TO-ONE AUDIO
// ============================================================

  Future<bool> startAudioCall({
    required String uid,
    required String name,
  }) {
    return _sendCall(
      uid: uid,
      name: name,
      isVideo: false,
    );
  }

// ============================================================
// ONE-TO-ONE VIDEO
// ============================================================

  Future<bool> startVideoCall({
    required String uid,
    required String name,
  }) {
    return _sendCall(
      uid: uid,
      name: name,
      isVideo: true,
    );
  }

// ============================================================
// SEND ONE-TO-ONE
// ============================================================

  Future<bool> _sendCall({
    required String uid,
    required String name,
    required bool isVideo,
  }) async {
    debugPrint('');
    debugPrint(
      '==================================================',
    );
    debugPrint(
      '===== RINGR SEND CALL =====',
    );

    if (!_initialized) {
      debugPrint(
        '❌ Zego is NOT initialized.',
      );
      debugPrint(
        '❌ Call cannot be sent.',
      );
      debugPrint(
        '==================================================',
      );
      return false;
    }

    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      debugPrint(
        '❌ Firebase user is null.',
      );
      debugPrint(
        '==================================================',
      );
      return false;
    }

    final targetUserID =
    toZegoUserId(uid);

    final callID =
    _createCallID(
      currentUser.uid,
      uid,
    );

    final displayName =
    name.trim().isEmpty
        ? 'Ringr User'
        : name.trim();

    debugPrint(
      'Caller Firebase UID: ${currentUser.uid}',
    );

    debugPrint(
      'Target Firebase UID: $uid',
    );

    debugPrint(
      'Target Zego UID: $targetUserID',
    );

    debugPrint(
      'Target Zego UID length: ${targetUserID.length}',
    );

    debugPrint(
      'Target name: $displayName',
    );

    debugPrint(
      'Call ID: $callID',
    );

    debugPrint(
      'Call type: ${isVideo ? 'VIDEO' : 'AUDIO'}',
    );

    _activeCallId = callID;
    _activeRemoteUid = uid;
    _activeRemoteName = displayName;
    _activeIsVideo = isVideo;
    _activeIsGroup = false;
    _activeCallType = CallType.outgoing;
    _activeConnectedAt = null;

    await CallService.instance
        .addOrUpdateCall(
      CallModel(
        callId: callID,
        name: displayName,
        uid: uid,
        phoneNumber: null,
        type: CallType.outgoing,
        status: CallStatus.calling,
        mode:
        isVideo
            ? CallMode.video
            : CallMode.audio,
        time: DateTime.now(),
        duration: Duration.zero,
      ),
    );

    try {
      final customData =
      jsonEncode({
        'ringrVersion': 1,
        'callerUid': currentUser.uid,
        'calleeUid': uid,
        'isVideo': isVideo,
        'groupCall': false,
      });

      debugPrint(
        'Custom data length: ${customData.length}',
      );

// ========================================================
// IMPORTANT:
//
// resourceID / notificationTitle /
// notificationMessage are intentionally NOT passed here.
//
// This isolates the basic online call invitation.
//
// ========================================================

      debugPrint(
        'Sending Zego invitation...',
      );

      final success =
      await ZegoUIKitPrebuiltCallInvitationService()
          .send(
        invitees: [
          ZegoCallUser(
            targetUserID,
            displayName,
          ),
        ],
        isVideoCall: isVideo,
        callID: callID,
        customData: customData,
        timeoutSeconds: 60,
      );

      debugPrint(
        'Zego send() result: $success',
      );

      if (!success) {
        debugPrint(
          '❌ Zego invitation returned FALSE.',
        );

        await CallService.instance
            .finishCall(
          callId: callID,
          status: CallStatus.failed,
        );

        _clearActiveCall();
      } else {
        debugPrint(
          '✅ Zego invitation sent successfully.',
        );
      }

      debugPrint(
        '==================================================',
      );

      return success;
    } catch (e, stack) {
      debugPrint('');
      debugPrint(
        '==================================================',
      );
      debugPrint(
        '❌ SEND CALL FAILED',
      );
      debugPrint(
        'Error: $e',
      );
      debugPrint(
        'Stack trace:',
      );
      debugPrint('$stack');
      debugPrint(
        '==================================================',
      );

      await CallService.instance
          .finishCall(
        callId: callID,
        status: CallStatus.failed,
      );

      _clearActiveCall();

      return false;
    }
  }

// ============================================================
// GROUP AUDIO
// ============================================================

  Future<bool> startGroupAudioCall({
    required List<ContactCallTarget> participants,
  }) {
    return _sendGroupCall(
      participants: participants,
      isVideo: false,
    );
  }

// ============================================================
// GROUP VIDEO
// ============================================================

  Future<bool> startGroupVideoCall({
    required List<ContactCallTarget> participants,
  }) {
    return _sendGroupCall(
      participants: participants,
      isVideo: true,
    );
  }

// ============================================================
// SEND GROUP CALL
// ============================================================

  Future<bool> _sendGroupCall({
    required List<ContactCallTarget> participants,
    required bool isVideo,
  }) async {
    debugPrint('');
    debugPrint(
      '==================================================',
    );
    debugPrint(
      '===== RINGR SEND GROUP CALL =====',
    );

    if (!_initialized) {
      debugPrint(
        '❌ Zego is NOT initialized.',
      );
      return false;
    }

    if (participants.isEmpty) {
      debugPrint(
        '❌ No group participants.',
      );
      return false;
    }

    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      debugPrint(
        '❌ Firebase user is null.',
      );
      return false;
    }

    final uniqueParticipants =
    <String, ContactCallTarget>{};

    for (final participant
    in participants) {
      if (participant.uid.isEmpty) {
        continue;
      }

      if (participant.uid ==
          currentUser.uid) {
        continue;
      }

      uniqueParticipants[
      participant.uid] = participant;
    }

    if (uniqueParticipants.isEmpty) {
      debugPrint(
        '❌ No valid group participants.',
      );
      return false;
    }

    final invitees =
    uniqueParticipants.values
        .map(
          (participant) =>
          ZegoCallUser(
            toZegoUserId(
              participant.uid,
            ),
            participant.name
                .trim()
                .isEmpty
                ? 'Ringr User'
                : participant.name
                .trim(),
          ),
    )
        .toList();

    final callID =
        'ringr_group_${DateTime.now().microsecondsSinceEpoch}';

    _activeCallId = callID;
    _activeRemoteUid = null;
    _activeRemoteName = 'Group call';
    _activeIsVideo = isVideo;
    _activeIsGroup = true;
    _activeCallType = CallType.outgoing;
    _activeConnectedAt = null;

    await CallService.instance
        .addOrUpdateCall(
      CallModel(
        callId: callID,
        name: 'Group call',
        uid: null,
        phoneNumber: null,
        type: CallType.outgoing,
        status: CallStatus.calling,
        mode:
        isVideo
            ? CallMode.video
            : CallMode.audio,
        time: DateTime.now(),
        duration: Duration.zero,
      ),
    );

    final customData =
    jsonEncode({
      'ringrVersion': 1,
      'groupCall': true,
      'callerUid': currentUser.uid,
      'isVideo': isVideo,
      'participantCount':
      invitees.length,
    });

    debugPrint(
      'Group Call ID: $callID',
    );

    debugPrint(
      'Participants: ${invitees.length}',
    );

    debugPrint(
      'Video: $isVideo',
    );

    debugPrint(
      'Custom data length: ${customData.length}',
    );

    try {
// ========================================================
// Same isolation as one-to-one calls.
//
// Offline notification parameters are intentionally
// omitted for this test.
// ========================================================

      final success =
      await ZegoUIKitPrebuiltCallInvitationService()
          .send(
        invitees: invitees,
        isVideoCall: isVideo,
        callID: callID,
        customData: customData,
        timeoutSeconds: 60,
      );

      debugPrint(
        'Group invitation result: $success',
      );

      if (!success) {
        debugPrint(
          '❌ Group invitation returned FALSE.',
        );

        await CallService.instance
            .finishCall(
          callId: callID,
          status: CallStatus.failed,
        );

        _clearActiveCall();
      } else {
        debugPrint(
          '✅ Group invitation sent successfully.',
        );
      }

      return success;
    } catch (e, stack) {
      debugPrint('');
      debugPrint(
        '==================================================',
      );
      debugPrint(
        '❌ GROUP CALL FAILED',
      );
      debugPrint('$e');
      debugPrint('$stack');
      debugPrint(
        '==================================================',
      );

      await CallService.instance
          .finishCall(
        callId: callID,
        status: CallStatus.failed,
      );

      _clearActiveCall();

      return false;
    }
  }

// ============================================================
// LOGOUT
// ============================================================

  Future<void> logout() async {
    if (!_initialized) {
      return;
    }

    try {
      debugPrint(
        'Uninitializing ZEGOCLOUD...',
      );

      await ZegoUIKitPrebuiltCallInvitationService()
          .uninit();

      _initialized = false;

      _clearActiveCall();

      debugPrint(
        'ZEGOCLOUD uninitialized.',
      );
    } catch (e) {
      debugPrint(
        'Zego logout error: $e',
      );
    }
  }

// ============================================================
// HELPERS
// ============================================================

  String toZegoUserId(String uid) {
    final cleaned =
    uid.replaceAll(
      RegExp(r'[^a-zA-Z0-9_]'),
      '_',
    );

    if (cleaned.length <= 32) {
      return cleaned;
    }

    return cleaned.substring(0, 32);
  }

  String _createCallID(
      String callerUid,
      String receiverUid,
      ) {
    return 'ringr_'
        '${DateTime.now().microsecondsSinceEpoch}_'
        '${callerUid.hashCode.abs()}_'
        '${receiverUid.hashCode.abs()}';
  }

  void _clearActiveCall() {
    _activeCallId = null;
    _activeRemoteUid = null;
    _activeRemoteName = null;
    _activeIsVideo = false;
    _activeIsGroup = false;
    _activeCallType = null;
    _activeConnectedAt = null;
  }
}

// ============================================================
// GROUP CALL TARGET
// ============================================================

class ContactCallTarget {
  final String uid;
  final String name;

  const ContactCallTarget({
    required this.uid,
    required this.name,
  });
}

