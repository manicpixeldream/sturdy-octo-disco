import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Stores browser-local workspace data. Failed writes leave the current UI
/// usable and surface a warning that changes may be lost on reload.
class WorkspaceStorage {
  WorkspaceStorage(this._read, this._write);

  factory WorkspaceStorage.memory() {
    final data = <String, String>{};
    return WorkspaceStorage(
      (key) => data[key],
      (key, value) => data[key] = value,
    );
  }

  final String? Function(String key) _read;
  final void Function(String key, String value) _write;
  final saveFailed = ValueNotifier(false);

  T? read<T>(String key, T Function(Object? value) decode) {
    try {
      final value = _read('gavel.workspace.v1.$key');
      return value == null ? null : decode(jsonDecode(value));
    } catch (_) {
      scheduleMicrotask(() => saveFailed.value = true);
      return null;
    }
  }

  void write(String key, Object? value) {
    try {
      _write('gavel.workspace.v1.$key', jsonEncode(value));
    } catch (_) {
      scheduleMicrotask(() => saveFailed.value = true);
    }
  }

  List<T> records<T>(String key, T Function(Map<String, Object?>) decode) {
    final values = read(key, (value) => (value as Map<String, dynamic>).values);
    return [
      for (final value in values ?? const []) ?_decodeRecord(value, decode),
    ];
  }

  T? _decodeRecord<T>(Object? value, T Function(Map<String, Object?>) decode) {
    try {
      return decode(Map<String, Object?>.from(value as Map));
    } catch (_) {
      scheduleMicrotask(() => saveFailed.value = true);
      return null;
    }
  }

  void putRecord(String key, String id, Map<String, Object?> record) {
    final storageKey = 'gavel.workspace.v1.$key';
    try {
      final raw = _read(storageKey);
      final records = <String, Object?>{};
      if (raw != null) {
        try {
          records.addAll(jsonDecode(raw) as Map<String, dynamic>);
        } on FormatException {
          scheduleMicrotask(() => saveFailed.value = true);
        } on TypeError {
          scheduleMicrotask(() => saveFailed.value = true);
        }
      }
      records[id] = record;
      _write(storageKey, jsonEncode(records));
    } catch (_) {
      scheduleMicrotask(() => saveFailed.value = true);
    }
  }
}
