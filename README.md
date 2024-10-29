# Object Relational Mapping SDK for [Dart Net Core API](https://github.com/caseyryan/dart_net_core_api)



**IMPORTANT**: This library is in development and is not ready for any use
At the moment I'm only making a simple PostgreSQL support 


This library is based on reflections and will **not** work with AOT compilation, **only** JIT is supported. 


## Getting Started

Initialize the library somewhere in the beginning of your program
Basically that's all you need. You don't even have to assign it to any variable 
since internally is is assigned and will be used by the ORM library on its own

**NOTE:** as the library is actively using [Reflect Buddy](https://github.com/caseyryan/reflect_buddy) 
under the hood. The models support all the functionality of the library e.g. 
all ValueConverters, KeyConverters, Validators etc. Read the documentation for the Reflect Buddy library
to learn more about it, it's very powerful

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
final result = await (Dude).select().toListAsync();
```

or select specific fields
```dart
final result = await (Dude).select(['name']).toListAsync();
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
(Car).createTable();
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
```

## UPDATE

To update a record you need to create an instance of your model and set the fields you want to update.
If you wish to add a few `WHERE` clauses to your query you can use the `where` method
with a list of `WhereOperation` objects. You can also specify the way the previous clause will 
be joined with the next one by using the `nextJoiner` parameter of the `WhereOperation` class.
in this case it will be `Joiner.or` which will result in `OR` instead of `AND` (default one)


```dart
final carUpdate = Car()
  ..manufacturer = 'Toyota'
  ..enginePower = 95;

(Car).update(carUpdate).where([
  Equal(
    key: 'id',
    value: 7,
    nextJoiner: Joiner.or,
  ),
  Equal(
    key: 'manufacturer',
    value: 'Toyota',
  ),
]).execute(dryRun: false);
```

## INSERT or UPSERT

To insert a record you need to create an instance of your model and set the fields you want to insert.

```dart
final car = Car()
  ..id = 7
  ..manufacturer = 'Lada'
  ..enginePower = 120;
final result = await car
    .insert(
      conflictResolution: ConflictResolution.update,
    )
    .execute(dryRun: false);
```

You may also specify a conflict resolution strategy by using the `conflictResolution` parameter
of the `insert` method.
That's the generic method. 

But you can also use the `upsert` method which will be a shortcut for the `insert` method
with the `conflictResolution` parameter set to `ConflictResolution.update`
It will update the existing record found by `id` or insert a new one if it doesn't exist

```dart
final car = Car()
  ..id = 7
  ..manufacturer = 'Proton'
  ..enginePower = 100;

final result = await car.upsert().execute(dryRun: false);
```




## SELECT

You can select specific fields by using the `select` method

```dart
final result = await (Dude).select(['name']).toListAsync();
```

The name of the table is retrieved from the class name by making in plural and converting it to snake case.

## DROP TABLE

You can drop a table by using the `dropTable` method

```dart
(Car).dropTable(
  dryRun: false,
  ifExists: true,
  cascade: true,
);
```