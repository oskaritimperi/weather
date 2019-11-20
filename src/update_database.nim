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
    if readBuffer(stdin, addr result[0], size) != 0:
        raise newCgiError(400, "not enough data")

proc main() =
    if paramCount() != 2:
        raise newCgiError(500, "one argument required")

    let config = loadConfig(paramStr(1))
    let databaseDir = config.getSectionValue("", "databaseDir")
    if databaseDir == "":
        raise newCgiError(500, "databaseDir is empty")

    if getEnv("REQUEST_METHOD") != "POST":
        raise newCgiError(400, "request method must be POST")

    let j = parseJson(readData())

    for alias, measurement in j:
        let filename = normalizedPath(joinPath(databaseDir, alias & ".rrd"))

        if not filename.startsWith(databaseDir):
            raise newCgiError(400, "invalid database")
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
