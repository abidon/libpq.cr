# pq.cr
A Crystal binding to the native postgres library (libpq)

### Requirements

- libpq

### Usage

* Add the following to your `shards.yml` file:

```yaml
dependencies:
  libpq:
    github: abidon/libpq.cr
    branch: master
```

* Call the `libpq` functions

```crystal
require "libpq"

conn = LibPQ.connect_db("postgres://user:pwd@localhost:5432/dbname")
print "#{LibPQ.status(conn)}\n"
LibPQ.finish conn
```

For more information, check the official Postgres documentation about [libpq](https://www.postgresql.org/docs/current/static/libpq.html).

### Used in...

* [crystal-pq](https://github.com/abidon/crystal-pq): A [crystal-db](https://github.com/crystal-lang/crystal-db) compliant postgres driver

### License

Copyright 2017 Aurélien Bidon (abidon@protonmail.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
