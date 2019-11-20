import strformat
import strutils
from os import `/`, parentDir

task build, "build tools":
    mkdir("bin")
    exec("nim c -o:bin/update_graphs src/update_graphs.nim")
    exec("nim c -o:bin/update_database src/update_database.nim")

task createdb, "create a new database":
    hint("QuitCalled", false)

    # This database will store the following data
    # - 1 year worth of samples each 15 minutes
    # - average of each day for 10 years
    # - min of each day for 10 years
    # - max of each day for 10 years

    let
        database = thisDir() / "database" / paramStr(2) & ".rrd"
        step = 15 * 60
        heartbeat = 20 * 60
        secondsInDay = 24 * 60 * 60
        samplesInDay = secondsInDay div step
        secondsInYear = 365 * secondsInDay
        samplesInYear = secondsInYear div step
        daysIn10Years = 365 * 10

    if fileExists(database):
        echo(&"error: database '{database}' exists")
        quit(1)

    echo(&"step = {step} seconds")
    echo(&"heartbeat = {heartbeat} seconds")
    echo(&"samplesInYear = {samplesInYear}")
    echo(&"samplesInDay = {samplesInDay}")
    echo(&"daysIn10Years = {daysIn10Years}")

    let args = [
        "create", database,
        "--start", "now",
        "--step", $step,
        &"DS:temperature:GAUGE:{heartbeat}:-40:40",
        &"DS:humidity:GAUGE:{heartbeat}:0:100",
        &"DS:pressure:GAUGE:{heartbeat}:U:U",
        &"DS:battery:GAUGE:{heartbeat}:0:4",
        &"RRA:AVERAGE:0.5:1:{samplesInYear}",
        &"RRA:MIN:0.5:{samplesInDay}:{daysIn10Years}",
        &"RRA:MAX:0.5:{samplesInDay}:{daysIn10Years}",
        &"RRA:AVERAGE:0.5:{samplesInDay}:{daysIn10Years}",
    ]

    mkdir(database.parentDir())

    echo("rrdtool " & args.join(" "))
    exec("rrdtool " & args.join(" "))

task install_cgi_kapsi, "install cgi script on kapsi.fi":
    proc modifyPath(s: string): string =
        result = s.replace("/home/users", "/var/www/userhome")
    let
        databaseDir = modifyPath(thisDir() / "database")
        updateDatabasePath = modifyPath(thisDir() / "bin" / "update_database")
        scriptPath = paramStr(2)
        script = &"""
#!{updateDatabasePath}
databaseDir = "{databaseDir}"
"""

    writeFile(scriptPath, script)
