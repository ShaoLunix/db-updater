# db-updater
This script updates values in the database's tables.

Syntax : db-updater [OPTION ...]
This script updates a database's entries according to the values passed with the arguments. This is very useful to update entries in a database without having to connect to it and do it manually.

With no option, the command loads the default configuration file declared in the 'db-updater.conf' file.

The general configuration file is firstly loaded ('db-updater.conf').
Then the configuration file declared in that general configuration file which contains the values specific to the server you send the queries to.
At last, the options are read from the command line.
That means, the command line options overwrite the variables used by the script. This can be very useful when exceptionally the entries are uploaded to a database with some unusual options.
For example to update entries to a preprod database which is identical to a production one but its hostname. Then the same configuration file can be included and the option '-s' specified with a different SERVER_NAME.

db-updater  [-c|--config CONFIG_FILE] [-d|--decrypt]  [--dblogin|--database_login DATABASE_LOGIN]  [--dbname|--database_name DATABASE_NAME]  [--dbpassword|--database_password DATABASE_PASSWORD]  [--dbport|--database_listening_port DATABASE_PORT]  [-i|--ipversion IP_VERSION] [-l LOCALHOST]  [-q|--queries FILE_OF_QUERIES] [-s|--server SERVER_NAME] [--sshlogin SSH_LOGIN] [--sshpassword SSH_PASSWORD] [--sshport SSH_PORT]  [--tunnel_port|--tunnel_listening_port PORT]

db-updater [-h|-?|--help]

db-updater [-v|--verbose] [-V|--version]


 OPTIONS

  -c|--config                           :         the configuration file to include.

  -d|--decrypt                          :         if this option is present then the password following the option '-p|--password' must be decrypted.

  --dbname|--database_name              :         name of the database to be used.

  --dblogin|--database_login            :         login to use to connect to the database.

  --dbpassword|--database_password      :         login's password to use to connect to the database.

  --dbport|--database_listening_port    :         port the database server is listening on (server side).

  -h|-?|--help                          :         show the help.

  -i|--ipversion                        :         the IP version to be used.

  -l|--localhost                        :         the local host (client) to be used.

  -q|--queries                          :         the list of queries to send to the remote server

  -s|--server                           :         remote server name or IP address

  --sshlogin                            :         the login to be used to connect to the SSH server.

  --sshpassword                         :         the SSH login's password. With the option '-d', the password must be decrypted.

  --sshport                             :         the server SSH port to be used.

  --tunnel_port|--tunnel_listening_port :         local port the SSH tunnel is listening on (client side).

  -v|--verbose                          :         verbosity level to apply during this script execution.

  -V|--version                          :         this script version.


Exit status :

 0 = success

 1 = failure due to wrong parameters

 2 = abnormal exit


To inform about any problem : https://github.com/ShaoLunix/db-updater/issues.
