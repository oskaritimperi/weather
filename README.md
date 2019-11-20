# Usage on kapsi.fi

- Clone the repository to e.g. `/home/users/johndoe/sites/example.com/weather`

- Execute `nim build` to build binaries for updating database and graphs

- Create your databases with `nim createdb database/$DATABASE.rrd`

- Install the CGI script with `nim install_cgi_kapsi $CGI_SCRIPT_PATH`

    - For example `nim install_cgi_kapsi $HOME/sites/example.com/www/weather/update.cgi`

- Install a cron job for updating graphs

    - For example `$HOME/sites/example.com/weather/bin/update_graphs $HOME/sites/example.com/www/weather`
