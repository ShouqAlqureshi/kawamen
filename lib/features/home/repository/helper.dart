import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentSnapshotWrapper implements DocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  DocumentSnapshotWrapper(this._id, this._data);

  @override
  Map<String, dynamic> data() {
    return _data;
  }

  @override
  String get id => _id;

  @override
  // Implement other required methods with minimal functionality
  dynamic get(Object field) => _data[field];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}