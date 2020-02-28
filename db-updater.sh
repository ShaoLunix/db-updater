#!/bin/bash

#==============================================================================#
#
#       DB-UPDATER
#
# This script updates values in the database's tables.
# This is very useful to update values in a database without having
# to connect to it and do it manually.
#
# Versions
# [2020-02-28] [1.0.1] [Stéphane-Hervé] SSH tunnel fixed
# [2019-12-07] [1.0.0] [Stéphane-Hervé] First version
#==============================================================================#
# strict mode
set -o nounset


#=== THIS SCRIPT DETAILS
VER=1.0.1
myscript="db-updater"
myproject="$myscript"
mycontact="https://github.com/ShaoLunix/$myproject/issues"



#*** CHECKING IF THE CURRENT SCRIPT CAN BE EXECUTED
#*** root is forbidden
myidentity=$(whoami)
if [ $myidentity = "root" ]; then
	RED='\033[0;31m'
	GREEN='\033[0m'
	echo -e "${RED}this script cannot be executed as root${GREEN}\n"
	exit
fi



#=== FUNCTIONS FILE
. functions.sh



#===========#
# VARIABLES #
#===========#
# Required commands
requiredcommand[0]="sshpass"
requiredcommand[1]="ssh"
requiredcommand[2]="mysql"
requiredscript="storepass.sh"
missingcommands=""

# Params
script_configfile="db-updater.conf"
list_of_queries="listof-queries-tobe-sent"
backup="off"
isbackup=false
sourcetype=""
iscounteron=false
counter=""
# --> Server
remote_server=""
IP_version=""
# --> SSH connection
ssh_login=""
ssh_pass=""
isssh_pass=false
isssh_crypted=false
decryptedssh_pass=""
# --> Database connection
db_name=""
db_login=""
db_pass=""
isdb_pass=false
isdb_crypted=false
decrypteddb_pass=""
# --> Database query
SQLqueries=""
# Time
currentTime=$(date +"%Y%m%d"_"%H%M%S")
currentTimeStamp=$(date +"%Y-%m-%d %H:%M:%S")
# Verbosity
verbose=0



#=== CONFIGURATION FILE
. "$script_configfile"
# Loading the configuration file
load_configfile



#=== MANAGING EXIT SIGNALS
trap 'abnormalExit' 1 2 3 4 15



#====================#
# TEST PREREQUISITES #
#====================#
# Testing the required commands can be found
for i in ${!requiredcommand[*]}; do
    if ! type ${requiredcommand[$i]} > /dev/null 2>&1; then
        if [[ -z "$missingcommands" ]]; then
            missingcommands="${requiredcommand[$i]}"
        else
            missingcommands="$missingcommands and ${requiredcommand[$i]}"
        fi
    fi
done
# Testing the required script can be found
if [[ ! -x $requiredscript ]]; then
    if [[ -z "$missingcommands" ]]; then
        missingcommands="$requiredscript"
    else
        missingcommands="$missingcommands and $requiredscript"
    fi
fi
# If any required command or script is missing, then display the requirement error
if [[ ! -z "$missingcommands" ]]; then
    prerequisitenotmet $missingcommands
fi



#=======#
# FLAGS #
#=======#
# -c|--config                       : the configuration file to consider
# -d|--decrypt                      : if this option is present then the password following the option '-p|--password' must be decrypted
# --dbname|--database_name          : name of the database to be used.
# --dblogin|--database_login        : login to use to connect to the database
# --dbpassword|--database_password  : login's password to use to connect to the database
# --dbport|--database_listening_port : port the database server is listening on (server side)
# -h|-?|--help                      : show the help
# -i|--ipversion                    : the IP version to be used.
# -l|--localhost                    : the local host (client) to be used.
# -q|--queries                      : the list of queries to send to the remote server
# -s|--server                       : remote server name or IP address
# --sshlogin                        : the login to be used to connect to the SSH server.
# --sshpassword                     : the SSH login's password. With the option '-d', the password must be decrypted.
# --sshport                         : the server SSH port to be used.
# --tunnel_port|--tunnel_listening_port : local port the SSH tunnel is listening on (client side)
# -v|--verbose                      : verbosity level to apply during this script execution
# -V|--version                      : this script version
while :; do
    case ${1-default} in
        -h|-\?|--help)
            showhelp    # Display a usage synopsis.
            exit
            ;;

        # Configuration filename
        -c|--config)
            if [ "${2-default}" ]; then
                configuration_file="${2-default}"
                shift
            else
                die 'ERROR: "-c|--config" requires a non-empty option argument.'
            fi
            ;;

        # Status of the decryption option
        -d|--decrypt)
            isssh_crypted=true
            isdb_crypted=true
            ;;

        # Database name
        --dbname|--database_name)
            if [ "${2-default}" ]; then
                db_name="${2-default}"
                shift
            else
                die 'ERROR: "--dbname|--database_name" requires a non-empty option argument.'
            fi
            ;;

        # Database login
        --dblogin|--database_login)
            if [ "${2-default}" ]; then
                db_login="${2-default}"
                shift
            else
                die 'ERROR: "--dblogin|--database_login" requires a non-empty option argument.'
            fi
            ;;

        # Database password
        --dbpassword|--database_password)
            if [ "${2-default}" ]; then
                db_pass="${2-default}"
                isdb_pass=true
                shift
            else
                die 'ERROR: "--dbpassword|--database_password" requires a non-empty option argument.'
            fi
            ;;

        # Database listening port
        --dbport|--database_listening_port)
            if [ "${2-default}" ]; then
                db_listening_port="${2-default}"
                shift
            else
                die 'ERROR: "--dbport|--database_listening_port" requires a non-empty option argument.'
            fi
            ;;

        # The IP version to be used
        -i|--ipversion)
            if [ "${2-default}" ]; then
                IP_version="${2-default}"
                shift
            else
                die 'ERROR: "-i|--ipversion" requires a non-empty option argument.'
            fi
            ;;

        # The local host (client) to be used
        -l|--localhost)
            if [ "${2-default}" ]; then
                localhost="${2-default}"
                shift
            else
                die 'ERROR: "-L|--localhost" requires a non-empty option argument.'
            fi
            ;;

        # The list of queries to be used
        -q|--queries)
            if [ "${2-default}" ]; then
                list_of_queries="${2-default}"
                shift
            else
                die 'ERROR: "-q|--queries" requires a non-empty option argument.'
            fi
            ;;

        # Remote server name or IP address
        -s|--server)
            if [ "${2-default}" ]; then
                remote_server="${2-default}"
                shift
            else
                die 'ERROR: "-S|--server" requires a non-empty option argument.'
            fi
            ;;

        # SSH login
        --sshlogin)
            if [ "${2-default}" ]; then
                ssh_login="${2-default}"
                shift
            else
                die 'ERROR: "--sshlogin" requires a non-empty option argument.'
            fi
            ;;

        # SSH login's password
        --sshpassword)
            if [ "${2-default}" ]; then
                ssh_pass="${2-default}"
                isssh_pass=true
                shift
            else
                die 'ERROR: "--sshpassword" requires a non-empty option argument.'
            fi
            ;;

        # SSH port
        --sshport)
            if [ "${2-default}" ]; then
                ssh_port="${2-default}"
                shift
            else
                die 'ERROR: "--sshport" requires a non-empty option argument.'
            fi
            ;;

        # SSH tunnel listening port
        --tunnel_port|--tunnel_listening_port)
            if [ "${2-default}" ]; then
                tunnel_listening_port="${2-default}"
                shift
            else
                die 'ERROR: "--tunnel_port|--tunnel_listening_port" requires a non-empty option argument.'
            fi
            ;;

        # Verbosity level
        -v|--verbose)
            verbose=$((verbose + 1))  # Each -v adds 1 to verbosity.
            ;;
        # Showing this script version
        -V|--version)
            echo "$myscript -- Version $VER -- Start"
            date
            exit "$exitstatus"
            ;;
        # End of all options
        --)
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        # Default case: no more option
        *)
            break
            ;;
    esac

    shift
done



#=============#
# PREPARATION #
#=============#
# If the password must be decrypted
# Then execute the decrypt function
# Else the decrypted password is as it was passed
#--> SSH
if [ ! -z "$ssh_pass" ]; then
    if [ "$isssh_crypted" == true ]; then
        decrypt_password "$ssh_pass"
        decryptedssh_pass="$decryptedpass"
    elif [ "$isssh_crypted" == false ]; then
        decryptedssh_pass="$ssh_pass"
    fi
fi
#--> DATABASE
if [ ! -z "$db_pass" ]; then
    if [ "$isdb_crypted" == true ]; then
        decrypt_password "$db_pass"
        decrypteddb_pass="$decryptedpass"
    elif [ "$isdb_crypted" == false ]; then
        decrypteddb_pass="$db_pass"
    fi
fi



#===========#
# EXECUTION #
#===========#
#*** READING QUERIES TO BE SENT
while read line
do
	# Checking if current line is not empty
	if [[ ! -z "$line" ]] && [[ "$line" != \#* ]]; then

        # Counting each query
        (( counter++ ))

        action=$(echo "$line" | cut -d";" -f1)
        tablename=$(echo "$line" | cut -d";" -f2)

        case "$action" in
            "SELECT")
                condition=$(echo "$line" | cut -d";" -f3)
                columns=$(echo "$line" | cut -d";" -f4)
                criteria=$(echo "$line" | cut -d";" -f5)
                limit=$(echo $line | cut -d";" -f)
                [ -z "$columns" ] && columns="*"
                [ ! -z "$condition" ] && [ "$condition" != "\"\"" ] && [ "$condition" != "''" ] && condition="WHERE $condition" || condition=""
                [ ! -z "$criteria" ] && [ "$criteria" != "\"\"" ] && [ "$criteria" != "''" ] && criteria="ORDER BY $criteria" || criteria=""
                [ ! -z "$limit" ] && [ "$limit" != "\"\"" ] && [ "$limit" != "''" ] && limit="LIMIT $limit" || limit=""
                if [ ! -z "$action" ] && [ ! -z "$tablename" ]; then
            		SQLqueries="$SQLqueries""$action $columns FROM \`$tablename\` $condition $criteria $limit;"
        		fi
                ;;
            "INSERT")
                values=$(echo "$line" | cut -d";" -f3)
                if [ ! -z "$action" ] && [ ! -z "$tablename" ] && [ ! -z "$values" ]; then
        		    SQLqueries="$SQLqueries""$action INTO \`$tablename\` VALUES ($values);"
    		    fi
                ;;
            "UPDATE")
                condition=$(echo "$line" | cut -d";" -f3)
                newValues=$(echo "$line" | cut -d";" -f4)
                limit=$(echo $line | cut -d";" -f5)
                [ ! -z "$condition" ] && [ "$condition" != "\"\"" ] && [ "$condition" != "''" ] && condition="WHERE $condition" || condition=""
                [ ! -z "$limit" ] && [ "$limit" != "\"\"" ] && [ "$limit" != "''" ] && limit="LIMIT $limit" || limit=""
                if [ ! -z "$action" ] && [ ! -z "$tablename" ] && [ ! -z "$newValues" ]; then
            		SQLqueries="$SQLqueries""$action \`$tablename\` SET $newValues $condition $limit;"
        		fi
                ;;
            "DELETE")
                condition=$(echo "$line" | cut -d";" -f3)
                limit=$(echo $line | cut -d";" -f4)
                [ ! -z "$condition" ] && [ "$condition" != "\"\"" ] && [ "$condition" != "''" ] && condition="WHERE $condition" || condition=""
                [ ! -z "$limit" ] && [ "$limit" != "\"\"" ] && [ "$limit" != "''" ] && limit="LIMIT $limit" || limit=""
                if [ ! -z "$action" ] && [ ! -z "$tablename" ]; then
            		SQLqueries="$SQLqueries""$action FROM \`$tablename\` $condition $limit;"
        		fi
                ;;
        esac
	fi
done < "$list_of_queries"

clear

# Establishing a SSH tunnel
sshpass -p"${decryptedssh_pass}" \
        ssh -f -N -L "${tunnel_listening_port}":"${localhost}":"${db_listening_port}" \
            -p "${ssh_port}" \
            -${IP_version} \
            "${ssh_login}"@"${remote_server}" \
            -o 'ControlMaster=no' -o 'ControlPath=no' &

sleep 3

# Connecting and querying to the database
mysql -v -v -v \
        --protocol=TCP --host="${localhost}" --port="${tunnel_listening_port}" \
        -u "${db_login}" -p${decrypteddb_pass} \
        -D "${db_name}" \
        -e "${SQLqueries}"

# Print the total number of queries
echo "$counter queries were sent."

# Unbinding the SSH connection
ssh -O cancel -L "${tunnel_listening_port}":"${localhost}":"${db_listening_port}" "${remote_server}"

exit 0
