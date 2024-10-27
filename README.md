# Object Relational Mapping SDK for Dart Net Core API

IMPORTANT: This library is in development and is not ready for any use
At the moment I'm only making a simple PostgreSQL support 


This library is based on reflections and will not work with AOT compilation.

## Getting Started

Initialize the library somewhere in the beginning of your program
Basically that's all you need. You don't even have to assign it to any variable 
since internally is is assigned and will be used by the ORM library on its own

```dart
import 'package:dart_core_orm/dart_core_orm.dart';

Orm.initialize(
  database: 'postgres',
  username: 'postgres',
  password: '',
  host: 'localhost',
  family: DatabaseFamily.postgres,
  isSecureConnection: false,
);
```

# Usage

Take any class like 

```dart
class Dude {
  int? id;
  String? name;
}
```

and select its instances 

```dart
final result = await (Dude).select().execute();
```

or select specific fields
```dart
final result = await (Dude).select(['name']).execute();
```

The name of the table is retrieved from the class name by making in plural and converting it to snake case.
so if the class name is `Dude` the table name will be `dudes`

But you can also specify a different table name by using the `@TableName` annotation on a class

```dart
@TableName('buddies')
class Dude {
  int? id;
  String? name;
}
```

