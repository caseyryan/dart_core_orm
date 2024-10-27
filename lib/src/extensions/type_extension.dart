import 'dart:mirrors';

import 'package:dart_core_orm/src/annotations/class_annotations.dart';
import 'package:dart_core_orm/src/orm.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

extension TypeExtension on Type {

  ChainedQuery _toChainedQuery() {
    final query = this is ChainedQuery ? this as ChainedQuery : ChainedQuery()
      .._type = this;
    return query;
  }

  ChainedQuery select([List<String>? paramsNames]) {
    final query = _toChainedQuery();
    final tableName = toTableName();
    query.add('SELECT ');
    if (paramsNames?.isNotEmpty != true) {
      query.add('*');
    } else {
      query.add(paramsNames!.join(', '));
    }
    query.add(' FROM $tableName');
    return query;
  }



  bool isSubclassOf<T>() {
    final classMirror = reflectType(this) as ClassMirror;
    return classMirror.isSubclassOf(reflectType(T) as ClassMirror);
  }

  String toTableName() {
    final typeMirror = reflectType(this);

    final metadata = reflectType(this).metadata;
    final classAnnotations = metadata.where(
      (e) {
        return e.reflectee.runtimeType.isSubclassOf<ClassAnnotation>();
      },
    ).toList();
    return (classAnnotations.lastOrNull?.reflectee as TableName?)?.name ??
        '${typeMirror.simpleName.toName().camelToSnake()}s';
  }
}

class ChainedQuery {
  Type? _type;

  final List<String> _parts = [];

  void add(String part) {
    _parts.add(part);
  }

  Future<List> execute() async {
    final List mappedResult = await orm?.executeSimpleQuery(query: '${_parts.join()};') as List? ?? [];
    return mappedResult.map((e) {
      return _type!.fromJson(e);
    }).toList();
  }
}
