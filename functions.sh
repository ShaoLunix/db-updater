#!/bin/bash

#============#
# FUNCTIONS  #
#============#

# Abnormal exit
abnormalExit()
{
    echo "$myscript -- End -- Failed"
    exit 2
}

# Prerequisite not met
prerequisitenotmet()
{
    echo "$missingcommands : missing"
    echo "Please, install it first and check you can access '$missingcommands'."
    echo "Programm aborted."
    exit 1
}

# Aborting the script because of a wrong or missing parameter
usage()
{
    echo "Usage: $myscript " \
                "[-c|--config CONFIG_FILE] [-d|--decrypt] " \
                "[--dblogin|--database_login DATABASE_LOGIN] " \
                "[--dbname|--database_name DATABASE_NAME] " \
                "[--dbpassword|--database_password DATABASE_PASSWORD] " \
                "[--dbport|--database_listening_port DATABASE_PORT] " \
                "[-h|-?|--help] [-i|--ipversion IP_VERSION] [-l LOCALHOST] " \
                "[-q|--queries FILE_OF_QUERIES] [-s|--server SERVER_NAME]" \
                "[--sshlogin SSH_LOGIN] [--sshpassword SSH_PASSWORD] [--sshport SSH_PORT] " \
                "[--tunnel_port|--tunnel_listening_port PORT] " \
                "[-v|--verbose] [-V|--version]"
    echo "For more information on how to use the script, type : < $myscript -h >"
    echo "$myscript -- End -- failed"
    exit 1
}

# Show the help of this script
showhelp()
{
    echo "${myscript^^}"
    echo
    echo "Syntax : $myscript [OPTION ...]"
    echo "This script updates a database's entries according to the values passed with the arguments." \
         "This is very useful to update entries in a database without having to connect to it and do it manually."
    echo
    echo "With no option, the command loads the default configuration file declared in the '$myscript.conf' file."
    echo
    echo "The general configuration file is firstly loaded ('$myscript.conf')."
    echo "Then the configuration file declared in that general configuration file" \
         "which contains the values specific to the server you send the queries to."
    echo "At last, the options are read from the command line."
    echo "That means, the command line options overwrite the variables used by the script." \
         "This can be very useful when exceptionally the entries are uploaded to a database with some unusual options."
    echo "For example to update entries to a preprod database which is identical to a production one but its hostname." \
         "Then the same configuration file can be included and the option '-s' specified with a different SERVER_NAME."
    echo

    echo "$myscript " \
                "[-c|--config CONFIG_FILE] [-d|--decrypt] " \
                "[--dblogin|--database_login DATABASE_LOGIN] " \
                "[--dbname|--database_name DATABASE_NAME] " \
                "[--dbpassword|--database_password DATABASE_PASSWORD] " \
                "[--dbport|--database_listening_port DATABASE_PORT] " \
                "[-i|--ipversion IP_VERSION] [-l LOCALHOST] " \
                "[-q|--queries FILE_OF_QUERIES] [-s|--server SERVER_NAME]" \
                "[--sshlogin SSH_LOGIN] [--sshpassword SSH_PASSWORD] [--sshport SSH_PORT] " \
                "[--tunnel_port|--tunnel_listening_port PORT] "
    echo "$myscript [-h|-?|--help]"
    echo "$myscript [-v|--verbose] [-V|--version]"
    echo
    echo " OPTIONS"
    echo
    echo "  -c|--config                           :         the configuration file to include."
    echo "  -d|--decrypt                          :         if this option is present then the password following the option '-p|--password' must be decrypted."
    echo "  --dbname|--database_name              :         name of the database to be used."
    echo "  --dblogin|--database_login            :         login to use to connect to the database."
    echo "  --dbpassword|--database_password      :         login's password to use to connect to the database."
    echo "  --dbport|--database_listening_port    :         port the database server is listening on (server side)."
    echo "  -h|-?|--help                          :         show the help."
    echo "  -i|--ipversion                        :         the IP version to be used."
    echo "  -l|--localhost                        :         the local host (client) to be used."
    echo "  -q|--queries                          :         the list of queries to send to the remote server"
    echo "  -s|--server                           :         remote server name or IP address"
    echo "  --sshlogin                            :         the login to be used to connect to the SSH server."
    echo "  --sshpassword                         :         the SSH login's password. With the option '-d', the password must be decrypted."
    echo "  --sshport                             :         the server SSH port to be used."
    echo "  --tunnel_port|--tunnel_listening_port :         local port the SSH tunnel is listening on (client side)."
    echo "  -v|--verbose                          :         verbosity level to apply during this script execution."
    echo "  -V|--version                          :         this script version."
    echo
    echo "Exit status : "
    echo " 0 = success"
    echo " 1 = failure due to wrong parameters"
    echo " 2 = abnormal exit"
    echo
    echo "To inform about any problem : $mycontact."
    exit
}

# Loading the configuration file
load_configfile()
{
    # If the configuration file is set with a relative path
    # Then it is converted to absolute
    if [[ "$configuration_file" != /* ]]; then
        script_dir="$( cd "$( dirname "$0" )" && pwd )"
        configuration_file="$script_dir/$configuration_file"
    fi

    # Loading the configuration file only if it exists
    # Else exit with an error
    if [ ! -f "$configuration_file" ]; then
        echo "$configuration_file could not be found."
        exit 1
    else
        . "$configuration_file"
        if [ ! -z "$ssh_pass" ]; then
            isssh_pass=true
        fi
    fi
}

# Password decryption
decrypt_password()
{
    decryptedpass=$(./storepass.sh -d "decrypted" "$1")
    # Exiting if the decrypted password is wrong
    if [ -z "$decryptedpass" ]; then
        echo "Something went wrong with the decryption of the password."
        usage
    fi
}

