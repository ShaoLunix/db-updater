# DB-UPDATER

*** README ***

This script was written in bash and so, it must be run on a GNU/Linux system.
This script establishes a connection through a secured tunnel with the database server so as to update its tables with no need to connect manually and to type code lines.

Before running this script, the configuration file (conf/server.conf) must be updated with the appropriate server's configuration (Server's address, details of SSH connection, database). Then just write the actions to run (INSERT, UPDATE, DELETE, SELECT) in the list of queries (listof-queries). This list contains explanations and examples to help write the lines properly.

This scripts can be particularly useful to replicate queries onto many servers. Just run the script with a configuration file specific to each server (in a loop for example).
