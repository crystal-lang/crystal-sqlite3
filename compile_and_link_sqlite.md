# How to Compile And Link SQLite

There are two main reasons to compile SQLite from source and they are both about getting features that are otherwise unavailable.

- You may need a feature from a release that haven't made it to your distro yet or you want to use the latest code from development.
- Perhaps you want some compile time features enabled that are not commonly enabled by default.

This guide assumes the first reason and goes through how to compile the latest release.


## Install Prerequisites (Ubuntu)

On Ubuntu you will need build-essential installed at a minimum.

```sh
sudo apt update
sudo apt install build-essential
```


## Download And Extract The Source Code

Source code for the latest release can be downloaded from the [SQLite Download Page](https://sqlite.org/download.html).
Look for "C source code as an amalgamation", It should be the first one on the page.

```sh
wget https://sqlite.org/2021/sqlite-amalgamation-3370000.zip
unzip sqlite-amalgamation-3370000.zip
cd sqlite-amalgamation-3370000
```


## Compile SQLite

Compile the sqlite command.

```sh
gcc shell.c sqlite3.c -lpthread -ldl -o sqlite3
./sqlite3 --version
```

Compile libsqlite.

```sh
gcc -lpthread -ldl -shared -o libsqlite3.so.0 -fPIC sqlite3.c
```

## Using The New Version of SQLite

The path to libsqlite can be specified at runtime with "LD_LIBRARY_PATH".

```sh
# directory of your crystal app
cd ../app

# Crystal run
LD_LIBRARY_PATH=../sqlite-amalgamation-3370000 crystal run src/app.cr

# This way will allow specifying the library location at runtime if it is different from the system default.
crystal build --release --link-flags -L"$(realpath ../sqlite-amalgamation-3370000/libsqlite3.so.0)" src/app.cr
LD_LIBRARY_PATH=../sqlite-amalgamation-3370000 ./app

# ldd can be used to see which libsqlite is being linked
LD_LIBRARY_PATH=../sqlite-amalgamation-3370000 ldd ./app
```

Or the absolute path to libsqlite can be specified at compile time.

```sh
crystal run --link-flags "$(realpath ../sqlite-amalgamation-3370000/libsqlite3.so.0)" src/app.cr

# This will create a version that only works if libsqlite in the excact same location as when it was compiled.
crystal build --release --link-flags "$(realpath ../sqlite-amalgamation-3370000/libsqlite3.so.0)" src/app.cr
./app

# Use ldd to see which libsqlite is being linked
ldd ./app
```


## Check SQLite Version From Crystal

To check which version of SQLite is being used from Crystal.

```crystal
# src/app.cr

DB_URI = "sqlite3://:memory:"

DB.open DB_URI do |db|
    db_version = db.scalar "select sqlite_version();"
    puts "SQLite #{db_version}"
end
```
