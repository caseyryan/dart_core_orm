## 0.0.4
- Added support for double quotes in Where operations to make them compatible with PostgreSQL case sensitive names
- added `tryConvertValueToDatabaseCompatible` method to `Object` extension 
This method converts a value to a database query compatible value
- Added `DateColumn` annotation for `DateTime` type to make the work with dates more flexible
## 0.0.2
- Added support for case sensitive names in PostgreSQL
- Added support for triggers in a `createTable` method for PostgreSQL
## 0.0.1
- The ORM based on mirrors. Works with JIT compilation only
