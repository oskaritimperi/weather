## RRD database update CGI program. Takes JSON measurements from ruuvitag-upload
## (https://github.com/oswjk/ruuvitag-upload) as input and stores them in the correct RRD database.
##
## The JSON format is as follows:
##
##    {
##        "alias": {
##            "timestamp": <seconds since unix epoch>,
##            "temperature": <temperature in degrees celcius>,
##            "humidity": <relative humidity (0% - 100%)>,
##            "pressure": <pressure in kilopascals>,
##            "battery_potential": <ruuvitag battery potential in volts>
##        },
##        "another_alias": {
##            ...
##        }
##    }
##
## The program should be run with an accompanying CGI script as the main driver. The web server will
## execute the script which looks like this:
##
##    #!/path/to/update_database
##    databaseDir = /path/to/where/databases/are
##
## This will execute update_database with one argument: the path to this script file.
## update_database will read this script and parse it as a configuration file. The databaseDir
## option should point to where the .rrd databases are stored.
##
## The update_database program will use the ``alias`` from measurements as the database name (with
## ``.rrd`` extension).

import json
import os
import osproc
import parsecfg
import strformat
import strutils

type
    CgiError = object of CatchableError
        code: int

proc newCgiError(code: int, message: string): ref CgiError =
    result = newException(CgiError, message)
    result.code = code

proc readData(): string =
    var size = parseInt(getEnv("CONTENT_LENGTH").string)
    if size == 0:
        return ""
    result = newString(size)
    if readBuffer(stdin, addr result[0], size) != size:
        raise newCgiError(400, "not enough data")

proc main() =
    let databaseDir = getAppDir().parentDir() / "database"

    if getEnv("REQUEST_METHOD") != "POST":
        raise newCgiError(400, "request method must be POST")

    let j = parseJson(readData())

    for alias, measurement in j:
        let filename = normalizedPath(joinPath(databaseDir, alias & ".rrd"))

        if not filename.startsWith(databaseDir):
            raise newCgiError(400, "invalid database")

        if not fileExists(filename):
            raise newCgiError(400, "unknown database")

        let
            timestamp = measurement["timestamp"].getBiggestInt()
            temperature = measurement["temperature"].getFloat()
            humidity = measurement["humidity"].getFloat()
            pressure = measurement["pressure"].getFloat()
            battery = measurement["battery_potential"].getFloat()
            data = &"{timestamp}:{temperature}:{humidity}:{pressure}:{battery}"
            (_, ec) = execCmdEx(&"rrdtool update {filename} {data}")

        if ec != 0:
            raise newCgiError(500, "rrdtool failed")

try:
    main()
    echo("Content-Type: text/plain")
    echo("")
except CgiError as e:
    echo(&"Status: {e.code}")
    echo("Content-Type: text/plain")
    echo("")
    echo(e.msg)
    quit(0)
except JsonParsingError as e:
    echo(&"Status: 400 Bad Request")
    echo("Content-Type: text/plain")
    echo("")
    echo(&"invalid json: {e.msg}")
    quit(0)
except Exception as e:
    echo(&"Status: 500 Internal Server Error")
    echo("Content-Type: text/plain")
    echo("")
    echo(e.msg)
    quit(0)
