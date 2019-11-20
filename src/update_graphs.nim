import os
import osproc
import strformat

let
    databaseDir = getAppDir().parentDir() / "database"
    outputDir = paramStr(2)
    width = 800
    height = 600

proc graph(filename, title, vlabel: string, args: varargs[string, `$`]) =
    var cmdline: seq[string] = @[
        "graph", joinPath(outputDir, filename),
        "--width", $width,
        "--height", $height,
        "--title", title,
        "--vertical-label", vlabel,
    ] & @args

    echo(&"Generating {joinPath(outputDir, filename)} ...")

    let p = startProcess("rrdtool", args=cmdline,
        options={poStdErrToStdOut, poUsePath, poParentStreams})

    if p.waitForExit() != 0:
        quit(1)


for database in walkFiles(joinPath(databaseDir, "*.rrd")):
    let (_, base, _) = splitFile(database)

    graph(&"{base}-temperature-today.png", "Temperature", "Celcius",
        "--end", "23:59 today",
        "--start", "00:00 today",
        "--alt-autoscale",
        "--left-axis-format", "%.1lf",
        &"DEF:temp1={database}:temperature:AVERAGE",
        &"DEF:temp2={database}:temperature:AVERAGE:end=00\\:00 today:start=end-24h",
        "LINE1:temp1#000000:today",
        "LINE1:temp2#FF0000:yesterday",
        "SHIFT:temp2:86400",
    )

    graph(&"{base}-temperature-month.png", "Temperature", "Celcius",
        "--end", "23:59 today",
        "--start", "end-1month",
        "--step", "86400",
        "--alt-autoscale",
        "--x-grid", "DAY:1:DAY:1:DAY:1:86400:%d",
        &"DEF:avg={database}:temperature:AVERAGE",
        &"DEF:min={database}:temperature:MIN",
        &"DEF:max={database}:temperature:MAX",
        "LINE1:avg#000000:average",
        "LINE2:min#FF0000:min",
        "LINE3:max#00FF00:max"
    )

    graph(&"{base}-humidity-today.png", "Relative humidity", "%",
        "--end", "23:59 today",
        "--start", "00:00 today",
        &"DEF:humi1={database}:humidity:AVERAGE",
        &"DEF:humi2={database}:humidity:AVERAGE:end=00\\:00 today:start=end-24h",
        "LINE1:humi1#000000:today",
        "LINE1:humi2#FF0000:yesterday",
        "SHIFT:humi2:86400",
    )

    graph(&"{base}-humidity-month.png", "Relative humidity", "%",
        "--end", "23:59 today",
        "--start", "end-1month",
        "--step", "86400",
        "--alt-autoscale",
        "--x-grid", "DAY:1:DAY:1:DAY:1:86400:%d",
        &"DEF:avg={database}:humidity:AVERAGE",
        &"DEF:min={database}:humidity:MIN",
        &"DEF:max={database}:humidity:MAX",
        "LINE1:avg#000000:average",
        "LINE2:min#FF0000:min",
        "LINE3:max#00FF00:max",
    )

    graph(&"{base}-pressure-today.png", "Pressure", "Pascal",
        "--end", "23:59 today",
        "--start", "00:00 today",
        "--alt-autoscale",
        "--left-axis-format", "%.1lf",
        &"DEF:pres1={database}:pressure:AVERAGE",
        &"DEF:pres2={database}:pressure:AVERAGE:end=00\\:00 today:start=end-24h",
        "LINE1:pres1#000000:today",
        "LINE1:pres2#FF0000:yesterday",
        "SHIFT:pres2:86400",
    )

    graph(&"{base}-pressure-month.png", "Pressure", "Pascal",
        "--end", "23:59 today",
        "--start", "end-1month",
        "--step", "86400",
        "--alt-autoscale",
        "--x-grid", "DAY:1:DAY:1:DAY:1:86400:%d",
        "--left-axis-format", "%.1lf",
        &"DEF:avg={database}:pressure:AVERAGE",
        &"DEF:min={database}:pressure:MIN",
        &"DEF:max={database}:pressure:MAX",
        "LINE1:avg#000000:average",
        "LINE2:min#FF0000:min",
        "LINE3:max#00FF00:max",
    )
