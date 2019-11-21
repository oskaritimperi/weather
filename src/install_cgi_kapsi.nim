## CGI script installation tool for kapsi.fi.

import os
import strformat
import strutils

proc modifyPath(s: string): string =
    result = s.replace("/home/users", "/var/www/userhome")

let
    updateDatabasePath = modifyPath(getAppDir() / "update_database")
    scriptPath = paramStr(1)
    script = &"""
#!/bin/sh
{updateDatabasePath}
"""

writeFile(scriptPath, script)

let fpExec = {fpUserExec, fpGroupExec, fpOthersExec}

setFilePermissions(scriptPath, getFilePermissions(scriptPath) + fpExec)
