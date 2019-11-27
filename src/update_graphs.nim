## RRD database graphing tool. Reads all databases from a directory and generates graphs from each
## of them.
##
## The generated graphs include
##
## - Temperature for today and yesterday
## - Temperature for current month and previous month
## - Relative humidity for today and yesterday
## - Relative humidity for current month and previous month
## - Pressure for today and yesterday
## - Pressure for current month and previous month
##
## The database directory is constructed from the path to this executable, by using the relative
## path ``../database``.
##
## The graphs are output to directory specified on the command line.

import os
import osproc
import strformat
import times

proc getLastDayOfCurrentMonth(): string =
    let now = times.now()
    let days = getDaysInMonth(now.month, now.year)
    result = &"{now.year}{ord(now.month):02}{days:02}"

proc getFirstDayOfCurrentMonth(): string =
    let now = times.now()
    result = &"{now.year}{ord(now.month):02}01"

proc getFirstDayOfPreviousMonth(): string =
    let now = times.now()
    let beginningOfMonth = initDateTime(1, now.month, now.year, 0, 0, 0)
    let endOfPrevMonth = beginningOfMonth - 1.days
    result = &"{endOfPrevMonth.year}{ord(endOfPrevMonth.month):02}01"

proc secondsInPrevMonth(): int =
    let beginningOfMonth = initDateTime(1, times.now().month, times.now().year, 0, 0, 0)
    let endOfPrevMonth = beginningOfMonth - 1.days
    let days = getDaysInMonth(endOfPrevMonth.month, endOfPrevMonth.year)
    result = days * 24 * 60 * 60

proc getDaysForMonthGraph(): int =
    let now = times.now()
    let beginningOfMonth = initDateTime(1, now.month, now.year, 0, 0, 0)
    let endOfPrevMonth = beginningOfMonth - 1.days
    result = max(getDaysInMonth(beginningOfMonth.month, beginningOfMonth.year),
        getDaysInMonth(endOfPrevMonth.month, endOfPrevMonth.year))

let
    databaseDir = getAppDir().parentDir() / "database"
    outputDir = paramStr(1)
    width = 800
    height = 600
    lastDayOfCurrentMonth = getLastDayOfCurrentMonth()
    firstDayOfCurrentMonth = getFirstDayOfCurrentMonth()
    firstDayOfPreviousMonth = getFirstDayOfPreviousMonth()

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
        echo("failed")
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
        "--start", &"00:00 {firstDayOfCurrentMonth}",
        "--end", &"start+{getDaysForMonthGraph()}days",
        "--step", "3600",
        "--alt-autoscale",
        "--x-grid", "DAY:1:DAY:1:DAY:1:86400:%d",
        &"DEF:curr={database}:temperature:AVERAGE",
        &"DEF:prev={database}:temperature:AVERAGE:end=00\\:00 {firstDayOfCurrentMonth}:start=00\\:00 {firstDayOfPreviousMonth}",
        "LINE1:curr#000000:current month",
        "LINE1:prev#FF0000:previous month",
        &"SHIFT:prev:{secondsInPrevMonth()}",
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
        "--start", &"00:00 {firstDayOfCurrentMonth}",
        "--end", &"start+{getDaysForMonthGraph()}days",
        "--step", "3600",
        "--alt-autoscale",
        "--x-grid", "DAY:1:DAY:1:DAY:1:86400:%d",
        &"DEF:curr={database}:humidity:AVERAGE",
        &"DEF:prev={database}:humidity:AVERAGE:end=00\\:00 {firstDayOfCurrentMonth}:start=00\\:00 {firstDayOfPreviousMonth}",
        "LINE1:curr#000000:current month",
        "LINE1:prev#FF0000:previous month",
        &"SHIFT:prev:{secondsInPrevMonth()}",
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
        "--start", &"00:00 {firstDayOfCurrentMonth}",
        "--end", &"start+{getDaysForMonthGraph()}days",
        "--step", "3600",
        "--alt-autoscale",
        "--left-axis-format", "%.1lf",
        "--x-grid", "DAY:1:DAY:1:DAY:1:86400:%d",
        &"DEF:curr={database}:pressure:AVERAGE",
        &"DEF:prev={database}:pressure:AVERAGE:end=00\\:00 {firstDayOfCurrentMonth}:start=00\\:00 {firstDayOfPreviousMonth}",
        "LINE1:curr#000000:current month",
        "LINE1:prev#FF0000:previous month",
        &"SHIFT:prev:{secondsInPrevMonth()}",
    )
