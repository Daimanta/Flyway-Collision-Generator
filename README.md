== Flyway collision generator ==

Generates a valid SQL file with the same CRC32 checksum as a target file

== Usage ==

```
Usage: crc-collision [OPTION] FILE 
 Generates an SQL file with the same CRC32 checksum as the target file.

 If arguments are possible, they are mandatory unless specified otherwise.
        -h, --help              Display this help and exit.
        -c, --comment           Produces a single commented line (default)
        -f, --file <SRC>        The resulting string, when appended to SRC matches the same hash as the target FILE
```