task build, "build tools":
    mkdir("bin")
    exec("nim c -o:bin/update_graphs src/update_graphs.nim")
    exec("nim c -o:bin/update_database src/update_database.nim")
    exec("nim c -o:bin/install_cgi_kapsi src/install_cgi_kapsi.nim")
    exec("nim c -o:bin/create_database src/create_database.nim")
