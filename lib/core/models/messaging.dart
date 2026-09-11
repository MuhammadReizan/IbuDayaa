import 'package:flutter/foundation.dart';

import '../db/row.dart';

enum ThreadKind {
  /// Member ↔ the cooperative's admins. Loan updates post here too.
  support,

  /// Admin broadcasts; members read only.
  announcement,

  /// One arisan group.
  group,

  /// Member ↔ member.
  direct;

  static ThreadKind fromDb(String? v) => switch (v) {
    'announcement' => announcement,
    'group' => group,
    'direct' => direct,
    _ => support,
  };

  String get db => name;
}

@immutable
class MessageThread {
  const MessageThread({
    required this.id,
    required this.cooperativeId,
    required this.kind,
    required this.title,
    this.refId,
    required this.createdAt,
  });

  final String id;
  final String cooperativeId;
  final ThreadKind kind;
  final String title;

  /// Member id for support threads, group id for arisan threads.
  final String? refId;
  final DateTime createdAt;

  factory MessageThread.fromRow(Map<String, dynamic> r) => MessageThread(
    id: rStr(r, 'id'),
    cooperativeId: rStr(r, 'cooperative_id'),
    kind: ThreadKind.fromDb(rStrN(r, 'kind')),
    title: rStr(r, 'title'),
    refId: rStrN(r, 'ref_id'),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'cooperative_id': cooperativeId,
    'kind': kind.db,
    'title': title,
    'ref_id': refId,
    'created_at': ts(createdAt),
  };
}

@immutable
class ThreadParticipant {
  const ThreadParticipant({
    required this.id,
    required this.threadId,
    required this.userId,
    this.lastReadAt,
  });

  final String id;
  final String threadId;
  final String userId;
  final DateTime? lastReadAt;

  factory ThreadParticipant.fromRow(Map<String, dynamic> r) =>
      ThreadParticipant(
        id: rStr(r, 'id'),
        threadId: rStr(r, 'thread_id'),
        userId: rStr(r, 'user_id'),
        lastReadAt: rDateN(r, 'last_read_at'),
      );

  Map<String, dynamic> toRow() => {
    'id': id,
    'thread_id': threadId,
    'user_id': userId,
    'last_read_at': lastReadAt == null ? null : ts(lastReadAt!),
  };
}

@immutable
class Message {
  const Message({
    required this.id,
    required this.threadId,
    this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String threadId;

  /// Null for system messages (loan status changes and the like).
  final String? senderId;
  final String body;
  final DateTime createdAt;

  bool get isSystem => senderId == null;

  factory Message.fromRow(Map<String, dynamic> r) => Message(
    id: rStr(r, 'id'),
    threadId: rStr(r, 'thread_id'),
    senderId: rStrN(r, 'sender_id'),
    body: rStr(r, 'body'),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'thread_id': threadId,
    'sender_id': senderId,
    'body': body,
    'created_at': ts(createdAt),
  };
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.route,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String userId;

  /// 'loan' | 'payment' | 'quota' | 'booking' | 'announcement' | 'member'.
  final String type;
  final String title;
  final String body;
  final String? route;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromRow(Map<String, dynamic> r) => AppNotification(
    id: rStr(r, 'id'),
    userId: rStr(r, 'user_id'),
    type: rStr(r, 'type'),
    title: rStr(r, 'title'),
    body: rStr(r, 'body'),
    route: rStrN(r, 'route'),
    readAt: rDateN(r, 'read_at'),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'user_id': userId,
    'type': type,
    'title': title,
    'body': body,
    'route': route,
    'read_at': readAt == null ? null : ts(readAt!),
    'created_at': ts(createdAt),
  };
}

@immutable
class ScoreSnapshot {
  const ScoreSnapshot({
    required this.id,
    required this.userId,
    required this.month,
    required this.score,
    required this.factorPoints,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime month;
  final int score;

  /// Category name → points, for "naik/turun berapa poin" per factor.
  final Map<String, int> factorPoints;
  final DateTime createdAt;

  factory ScoreSnapshot.fromRow(Map<String, dynamic> r) => ScoreSnapshot(
    id: rStr(r, 'id'),
    userId: rStr(r, 'user_id'),
    month: monthOf(rDate(r, 'month')),
    score: rInt(r, 'score'),
    factorPoints: {
      for (final e in ((r['factor_points'] as Map?) ?? const {}).entries)
        if (e.key is String && e.value is num)
          e.key as String: (e.value as num).toInt(),
    },
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'user_id': userId,
    'month': dateOnly(month),
    'score': score,
    'factor_points': factorPoints,
    'created_at': ts(createdAt),
  };
}
