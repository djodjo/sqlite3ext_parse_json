SQLite3 Extension Function parse_json()
=====================
##About
This is a extension of SQLite3 function.
ex. select parse_json(col1,'user.name') from employee;

##Features
* Following Parson (A lighweight json parser. ://github.com/kgabis/parson/)
* Addressing json values with dot notation (similiar to C structs or objects in most OO languages, e.g. "objectA.objectB.value") by Parson
* C89 compatible

##Installation
Run the following code:
```
git clone https://github.com/djodjo/sqlite3ext_parse_json
cd sqlite3ext_parse_json/
```
Get library....Parson (https://github.com/kgabis/parson/)
```
make init
```
and build extension.
Run ``` make ``` to compile.

##Usage
```
sqlite> .load parse_json.so
or
sqlite> select load_extension('parse_json');

Sample data...
{
  vendor:"Kawasaki Heavy Industries, Ltd.",
  model:"ZZR",
  spec:{
    "Engine Volume":"1400cc",
    color:"Metaric Super Black"
  }
}
sqlite> select parse_json(col1,'vendor') from example;
Kawasaki Heavy Industries, Ltd.
sqlite> select parse_json(col1,'spec.Engine Volume') from example;
1400cc
```

##License
[The Apache License, Version 2.0] (http://www.apache.org/licenses/LICENSE-2.0)
