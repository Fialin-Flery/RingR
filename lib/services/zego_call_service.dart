import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../models/call_model.dart';
import 'call_service.dart';
import '../main.dart';

class ZegoCallService {
  ZegoCallService._();

  static final ZegoCallService instance =
  ZegoCallService._();

  // ============================================================
  // ZEGOCLOUD
  // ============================================================

  static const int appID =
  1532825529;

  // IMPORTANT:
  // Rotate this AppSign because it has already been exposed.
  static const String appSign =
      'fe1e774fe9325328ff6b4c647553d00e785ff82857dc872a812a61e2190ef719';

  bool _initialized = false;

  // ============================================================
  // ACTIVE CALL
  // ============================================================

  String? _activeCallId;

  String? _activeRemoteUid;

  String? _activeRemoteName;

  bool? _activeIsVideo;

  DateTime? _activeConnectedAt;

  CallType? _activeCallType;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void>
  initializeForCurrentUser() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    if (_initialized) {
      return;
    }

    final userID =
    toZegoUserId(user.uid);

    final userName =
    user.displayName
        ?.trim()
        .isNotEmpty ==
        true
        ? user.displayName!.trim()
        : 'Ringr User';

    await ZegoUIKitPrebuiltCallInvitationService()
        .init(
      appID: appID,
      appSign: appSign,
      userID: userID,
      userName: userName,

      plugins: [
        ZegoUIKitSignalingPlugin(),
      ],


      // --------------------------------------------------------
      // MISSED CALL NOTIFICATIONS
      // --------------------------------------------------------

      config: ZegoCallInvitationConfig(
        missedCall: ZegoCallInvitationMissedCallConfig(
          enabled: true,
          enableDialBack: true,
        ),
      ),

      // --------------------------------------------------------
      // CALL CONFIGURATION
      // --------------------------------------------------------

      requireConfig:
          (ZegoCallInvitationData data) {
        if (data.invitees.length > 1) {
          return data.type ==
              ZegoCallType.videoCall
              ? ZegoUIKitPrebuiltCallConfig
              .groupVideoCall()
              : ZegoUIKitPrebuiltCallConfig
              .groupVoiceCall();
        }

        return data.type ==
            ZegoCallType.videoCall
            ? ZegoUIKitPrebuiltCallConfig
            .oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig
            .oneOnOneVoiceCall();
      },

      // --------------------------------------------------------
      // INVITATION EVENTS
      // --------------------------------------------------------

      invitationEvents:
      ZegoUIKitPrebuiltCallInvitationEvents(
        // ------------------------------------------------------
        // INCOMING
        // ------------------------------------------------------

        onIncomingCallReceived: (
            String callID,
            ZegoCallUser caller,
            ZegoCallInvitationType callType,
            List<ZegoCallUser> callees,
            String customData,
            ) {
          final isVideo =
              callType ==
                  ZegoCallInvitationType
                      .videoCall;

          _activeCallId = callID;
          _activeRemoteUid =
              caller.id;
          _activeRemoteName =
              caller.name;
          _activeIsVideo =
              isVideo;
          _activeCallType =
              CallType.incoming;
          _activeConnectedAt =
          null;

          CallService.instance
              .addOrUpdateCall(
            CallModel(
              callId: callID,
              name: caller.name.isEmpty
                  ? 'Ringr User'
                  : caller.name,
              uid: caller.id,
              phoneNumber: null,
              type: CallType.incoming,
              status:
              CallStatus.ringing,
              mode: isVideo
                  ? CallMode.video
                  : CallMode.audio,
              time: DateTime.now(),
              duration:
              Duration.zero,
            ),
          );
        },

        // ------------------------------------------------------
        // INCOMING ACCEPTED
        // ------------------------------------------------------

        onIncomingCallAcceptButtonPressed:
            () {
          final callID =
              _activeCallId;

          if (callID == null) {
            return;
          }

          final connectedAt =
          DateTime.now();

          _activeConnectedAt =
              connectedAt;

          CallService.instance
              .updateStatus(
            callID,
            CallStatus.connected,
            connectedAt:
            connectedAt,
          );
        },

        // ------------------------------------------------------
        // INCOMING REJECTED
        // ------------------------------------------------------

        onIncomingCallDeclineButtonPressed:
            () {
          final callID =
              _activeCallId;

          if (callID == null) {
            return;
          }

          CallService.instance
              .finishCall(
            callId: callID,
            status:
            CallStatus.rejected,
          );

          _clearActiveCall();
        },

        // ------------------------------------------------------
        // INCOMING MISSED
        // ------------------------------------------------------

        onIncomingCallTimeout: (
            String callID,
            ZegoCallUser caller,
            ) {
          CallService.instance
              .finishCall(
            callId: callID,
            status:
            CallStatus.missed,
          );

          _clearActiveCall();
        },

        // ------------------------------------------------------
        // INCOMING CANCELLED
        // ------------------------------------------------------

        onIncomingCallCanceled: (
            String callID,
            ZegoCallUser caller,
            String customData,
            ) {
          final existing =
          CallService.instance
              .getCall(callID);

          if (existing != null &&
              existing.connectedAt !=
                  null) {
            CallService.instance
                .finishCall(
              callId: callID,
              status:
              CallStatus.ended,
            );
          } else {
            CallService.instance
                .finishCall(
              callId: callID,
              status:
              CallStatus.cancelled,
            );
          }

          _clearActiveCall();
        },

        // ------------------------------------------------------
        // OUTGOING SENT
        // ------------------------------------------------------

        onOutgoingCallSent: (
            String callID,
            ZegoCallUser caller,
            ZegoCallInvitationType callType,
            List<ZegoCallUser> callees,
            String customData,
            ) {
          CallService.instance
              .updateStatus(
            callID,
            CallStatus.ringing,
          );
        },

        // ------------------------------------------------------
        // OUTGOING ACCEPTED
        // ------------------------------------------------------

        onOutgoingCallAccepted: (
            String callID,
            ZegoCallUser callee,
            ) {
          final connectedAt =
          DateTime.now();

          _activeCallId =
              callID;

          _activeRemoteUid =
              callee.id;

          _activeRemoteName =
              callee.name;

          _activeConnectedAt =
              connectedAt;

          CallService.instance
              .updateStatus(
            callID,
            CallStatus.connected,
            connectedAt:
            connectedAt,
          );
        },

        // ------------------------------------------------------
        // OUTGOING REJECTED
        // ------------------------------------------------------

        onOutgoingCallDeclined: (
            String callID,
            ZegoCallUser callee,
            String customData,
            ) {
          CallService.instance
              .finishCall(
            callId: callID,
            status:
            CallStatus.rejected,
          );

          _clearActiveCall();
        },

        // ------------------------------------------------------
        // BUSY
        // ------------------------------------------------------

        onOutgoingCallRejectedCauseBusy: (
            String callID,
            ZegoCallUser callee,
            String customData,
            ) {
          CallService.instance
              .finishCall(
            callId: callID,
            status:
            CallStatus.busy,
          );

          _clearActiveCall();
        },

        // ------------------------------------------------------
        // OUTGOING TIMEOUT
        // ------------------------------------------------------

        onOutgoingCallTimeout: (
            String callID,
            List<ZegoCallUser> callees,
            bool isVideoCall,
            ) {
          CallService.instance
              .finishCall(
            callId: callID,
            status:
            CallStatus.missed,
          );

          _clearActiveCall();
        },
      ),

      // --------------------------------------------------------
      // ACTUAL CALL EVENTS
      // --------------------------------------------------------

      events:
      ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (
            ZegoCallEndEvent event,
            VoidCallback defaultAction,
            ) async {
          debugPrint(
            'Ringr call ended: ${event.reason}',
          );

          final callID = _activeCallId;

          if (callID != null) {
            final existing =
            CallService.instance.getCall(callID);

            if (existing != null) {
              final endedAt = DateTime.now();

              if (_activeConnectedAt != null) {
                await CallService.instance.finishCall(
                  callId: callID,
                  status: CallStatus.ended,
                  endedAt: endedAt,
                );
              } else {
                await CallService.instance.finishCall(
                  callId: callID,
                  status: CallStatus.cancelled,
                  endedAt: endedAt,
                );
              }
            }
          }

          _clearActiveCall();

          // VERY IMPORTANT:
          // Let Zego close its own call screen first.
          defaultAction.call();

          // Then return Ringr to Home.
          await Future.delayed(
            const Duration(milliseconds: 250),
          );

          final navigator =
              navigatorKey.currentState;

          if (navigator != null) {
            navigator.popUntil(
                  (route) => route.isFirst,
            );
          }
        },
      ),
    );

    _initialized = true;

    debugPrint(
      'ZEGOCLOUD INITIALIZED: $userID',
    );
  }

  // ============================================================
  // AUDIO CALL
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
  // VIDEO CALL
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
  // SEND CALL
  // ============================================================

  Future<bool> _sendCall({
    required String uid,
    required String name,
    required bool isVideo,
  }) async {
    if (!_initialized) {
      debugPrint(
        'Cannot call: Zego is not initialized.',
      );

      return false;
    }

    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return false;
    }

    final currentFirebaseUid =
        currentUser.uid;

    final targetFirebaseUid =
    uid.trim();

    // ==========================================================
    // SELF-CALL PROTECTION
    // ==========================================================

    if (targetFirebaseUid.isEmpty) {
      debugPrint(
        '❌ CALL BLOCKED: empty target UID.',
      );

      return false;
    }

    if (targetFirebaseUid ==
        currentFirebaseUid) {
      debugPrint(
        '================================',
      );
      debugPrint(
        '❌ RINGR SELF-CALL BLOCKED',
      );
      debugPrint(
        'Current UID: '
            '$currentFirebaseUid',
      );
      debugPrint(
        'Target UID: '
            '$targetFirebaseUid',
      );
      debugPrint(
        '================================',
      );

      return false;
    }

    final currentZegoID =
    toZegoUserId(
      currentFirebaseUid,
    );

    final targetZegoID =
    toZegoUserId(
      targetFirebaseUid,
    );

    // Second protection layer.
    if (currentZegoID ==
        targetZegoID) {
      debugPrint(
        '❌ CALL BLOCKED: Zego IDs are identical.',
      );

      return false;
    }

    final callID =
    _createCallID(
      currentFirebaseUid,
      targetFirebaseUid,
    );

    final displayName =
    name.trim().isEmpty
        ? 'Ringr User'
        : name.trim();

    final now =
    DateTime.now();

    // ==========================================================
    // SAVE CALL
    // ==========================================================

    _activeCallId =
        callID;

    _activeRemoteUid =
        targetFirebaseUid;

    _activeRemoteName =
        displayName;

    _activeIsVideo =
        isVideo;

    _activeCallType =
        CallType.outgoing;

    _activeConnectedAt =
    null;

    await CallService.instance
        .addOrUpdateCall(
      CallModel(
        callId: callID,
        name: displayName,
        uid: targetFirebaseUid,
        phoneNumber: null,
        type: CallType.outgoing,
        status:
        CallStatus.calling,
        mode: isVideo
            ? CallMode.video
            : CallMode.audio,
        time: now,
        duration:
        Duration.zero,
      ),
    );

    debugPrint(
      '================================',
    );
    debugPrint(
      'RINGR STARTING CALL',
    );
    debugPrint(
      'Caller Firebase UID: '
          '$currentFirebaseUid',
    );
    debugPrint(
      'Target Firebase UID: '
          '$targetFirebaseUid',
    );
    debugPrint(
      'Caller Zego ID: '
          '$currentZegoID',
    );
    debugPrint(
      'Target Zego ID: '
          '$targetZegoID',
    );
    debugPrint(
      'Call ID: $callID',
    );
    debugPrint(
      'Video: $isVideo',
    );
    debugPrint(
      '================================',
    );

    try {
      final customData =
      jsonEncode({
        'ringrVersion': 1,
        'callerUid':
        currentFirebaseUid,
        'calleeUid':
        targetFirebaseUid,
        'isVideo': isVideo,
      });

      final success =
      await ZegoUIKitPrebuiltCallInvitationService()
          .send(
        invitees: [
          ZegoCallUser(
            targetZegoID,
            displayName,
          ),
        ],
        isVideoCall: isVideo,
        callID: callID,
        customData:
        customData,
        timeoutSeconds: 60,
      );

      debugPrint(
        'Zego send() result: '
            '$success',
      );

      if (!success) {
        await CallService.instance
            .finishCall(
          callId: callID,
          status:
          CallStatus.failed,
        );

        _clearActiveCall();
      }

      return success;
    } catch (e) {
      debugPrint(
        'RINGR CALL SEND ERROR: $e',
      );

      await CallService.instance
          .finishCall(
        callId: callID,
        status:
        CallStatus.failed,
      );

      _clearActiveCall();

      return false;
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void _clearActiveCall() {
    _activeCallId = null;
    _activeRemoteUid = null;
    _activeRemoteName = null;
    _activeIsVideo = null;
    _activeConnectedAt = null;
    _activeCallType = null;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    if (!_initialized) {
      return;
    }

    try {
      await ZegoUIKitPrebuiltCallInvitationService()
          .uninit();

      _initialized = false;

      _clearActiveCall();
    } catch (e) {
      debugPrint(
        'Zego logout error: $e',
      );
    }
  }

  // ============================================================
  // ZEGOCLOUD USER ID
  // ============================================================

  String toZegoUserId(
      String uid,
      ) {
    final cleaned =
    uid.replaceAll(
      RegExp(r'[^a-zA-Z0-9_]'),
      '_',
    );

    if (cleaned.length <= 32) {
      return cleaned;
    }

    return cleaned.substring(
      0,
      32,
    );
  }

  // ============================================================
  // CALL ID
  // ============================================================

  String _createCallID(
      String callerUid,
      String calleeUid,
      ) {
    final caller =
    toZegoUserId(
      callerUid,
    );

    final callee =
    toZegoUserId(
      calleeUid,
    );

    final timestamp =
        DateTime.now()
            .microsecondsSinceEpoch;

    final callerShort =
    caller.substring(
      0,
      caller.length > 6
          ? 6
          : caller.length,
    );

    final calleeShort =
    callee.substring(
      0,
      callee.length > 6
          ? 6
          : callee.length,
    );

    return 'ringr_${timestamp}_'
        '${callerShort}_'
        '$calleeShort';
  }
}