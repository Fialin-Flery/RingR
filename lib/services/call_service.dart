import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/call_model.dart';

class CallService extends ChangeNotifier {
  CallService._();

  static final CallService instance =
  CallService._();

  static const String _databaseName =
      'ringr_calls.db';

  static const String _tableName =
      'calls';

  Database? _database;

  final List<CallModel> _calls = [];

  bool _initialized = false;

  // ============================================================
  // INITIALIZE DATABASE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final databasesPath =
    await getDatabasesPath();

    final databasePath =
    path.join(
      databasesPath,
      _databaseName,
    );

    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (
          Database db,
          int version,
          ) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            callId TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            phoneNumber TEXT,
            uid TEXT,
            type TEXT NOT NULL,
            status TEXT NOT NULL,
            mode TEXT NOT NULL,
            time INTEGER NOT NULL,
            connectedAt INTEGER,
            endedAt INTEGER,
            durationSeconds INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_calls_time
          ON $_tableName(time DESC)
        ''');
      },
    );

    await _loadFromDatabase();

    _initialized = true;

    debugPrint(
      'CallService SQLite initialized.',
    );

    debugPrint(
      'Loaded ${_calls.length} call records.',
    );
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadFromDatabase() async {
    final db = _database;

    if (db == null) {
      return;
    }

    final rows = await db.query(
      _tableName,
      orderBy: 'time DESC',
    );

    _calls
      ..clear()
      ..addAll(
        rows.map(
          CallModel.fromMap,
        ),
      );

    notifyListeners();
  }

  // ============================================================
  // GET ALL
  // ============================================================

  List<CallModel> getCalls() {
    final calls =
    List<CallModel>.from(_calls);

    calls.sort(
          (a, b) =>
          b.time.compareTo(a.time),
    );

    return calls;
  }

  // ============================================================
  // RECENT
  // ============================================================

  List<CallModel> getRecentCalls() {
    return getCalls()
        .take(10)
        .toList();
  }

  // ============================================================
  // MISSED
  // ============================================================

  List<CallModel> getMissedCalls() {
    return getCalls()
        .where(
          (call) =>
      call.status ==
          CallStatus.missed ||
          call.type ==
              CallType.missed,
    )
        .toList();
  }

  // ============================================================
  // ADD OR UPDATE
  // ============================================================

  Future<void> addOrUpdateCall(
      CallModel call,
      ) async {
    final index =
    _calls.indexWhere(
          (existing) =>
      existing.callId ==
          call.callId,
    );

    if (index == -1) {
      _calls.add(call);
    } else {
      _calls[index] = call;
    }

    final db = _database;

    if (db != null) {
      await db.insert(
        _tableName,
        call.toMap(),
        conflictAlgorithm:
        ConflictAlgorithm.replace,
      );
    }

    notifyListeners();
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<void> addCall(
      CallModel call,
      ) async {
    await addOrUpdateCall(call);
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> updateStatus(
      String callId,
      CallStatus status, {
        DateTime? connectedAt,
        DateTime? endedAt,
        Duration? duration,
      }) async {
    final index =
    _calls.indexWhere(
          (call) =>
      call.callId == callId,
    );

    if (index == -1) {
      debugPrint(
        'CallService: cannot update '
            'unknown call $callId',
      );
      return;
    }

    final oldCall =
    _calls[index];

    final updatedCall =
    oldCall.copyWith(
      status: status,
      connectedAt:
      connectedAt ??
          oldCall.connectedAt,
      endedAt:
      endedAt ??
          oldCall.endedAt,
      duration:
      duration ??
          oldCall.duration,
    );

    await addOrUpdateCall(
      updatedCall,
    );
  }

  // ============================================================
  // UPDATE COMPLETE CALL
  // ============================================================

  Future<void> finishCall({
    required String callId,
    required CallStatus status,
    DateTime? endedAt,
  }) async {
    final call =
    getCall(callId);

    if (call == null) {
      debugPrint(
        'CallService: cannot finish '
            'unknown call $callId',
      );
      return;
    }

    final actualEnd =
        endedAt ?? DateTime.now();

    Duration duration =
        call.duration;

    if (call.connectedAt != null) {
      duration =
          actualEnd.difference(
            call.connectedAt!,
          );

      if (duration.isNegative) {
        duration = Duration.zero;
      }
    }

    await addOrUpdateCall(
      call.copyWith(
        status: status,
        endedAt: actualEnd,
        duration: duration,
      ),
    );
  }

  // ============================================================
  // FIND
  // ============================================================

  CallModel? getCall(
      String callId,
      ) {
    for (final call in _calls) {
      if (call.callId == callId) {
        return call;
      }
    }

    return null;
  }

  // ============================================================
  // DELETE ONE
  // ============================================================

  Future<void> deleteCall(
      String callId,
      ) async {
    _calls.removeWhere(
          (call) =>
      call.callId == callId,
    );

    final db = _database;

    if (db != null) {
      await db.delete(
        _tableName,
        where: 'callId = ?',
        whereArgs: [callId],
      );
    }

    notifyListeners();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<void> clearCalls() async {
    _calls.clear();

    final db = _database;

    if (db != null) {
      await db.delete(
        _tableName,
      );
    }

    notifyListeners();
  }

  // ============================================================
  // CLOSE
  // ============================================================

  Future<void> close() async {
    await _database?.close();

    _database = null;
    _initialized = false;
  }
}