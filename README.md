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

## SELECT

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

## CREATE TABLE

You can create a table by using the `createTable` method

```dart
(Car).createTable().execute();
```

The name of the table is retrieved from the class name by making in plural and converting it to snake case.
and then each field type and name is retrieved internally in a tricky way and the query is built accordingly

In order to add some more parameters to each column you may use ancestors of `TableColumnAnnotation`

```dart
class Car {

  @PrimaryKeyColumn()
  @NotNullColumn()
  @UniqueColumn(autoIncrement: true)
  int? id;

  /// This will be converted to VARCHAR(20) 
  /// on the database where it's supported or similar
  @LimitColumn(limit: 20)
  String? manufacturer;

  /// don't let the car be more powerful than 500 horsepower) 
  /// this will be converted to INTEGER CHECK (enginePower <= 300)
  /// Thus limiting the max value of the int to 300 in this case
  @LimitColumn(limit: 300)
  int? enginePower;
}