# Usage on kapsi.fi

- Clone the repository to e.g. `/home/users/johndoe/sites/example.com/weather`

- Execute `nim build` to build binaries for updating database and graphs

- Create your databases with `./bin/create_database DATABASE-NAME`

    - For example `./bin/create_database porch`

- Install the CGI script with `./bin/install_cgi_kapsi SCRIPT_PATH`

    - For example `nim install_cgi_kapsi $HOME/sites/example.com/www/weather/update.cgi`

- Install a cron job for updating graphs `./bin/update_graphs GRAPH_OUTPUT_DIR`

    - For example `$HOME/sites/example.com/weather/bin/update_graphs $HOME/sites/example.com/www/weather`
