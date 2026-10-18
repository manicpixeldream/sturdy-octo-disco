import 'package:flutter/foundation.dart';

@immutable
class Teammate {
  const Teammate({required this.id, required this.name});

  factory Teammate.fromMap(Map<String, Object?> map) =>
      Teammate(id: map['id']! as String, name: map['name']! as String);

  final String id;
  final String name;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  Teammate copyWith({String? id, String? name}) =>
      Teammate(id: id ?? this.id, name: name ?? this.name);

  Map<String, Object?> toMap() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      other is Teammate && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
