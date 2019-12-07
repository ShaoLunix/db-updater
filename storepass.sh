#!/bin/bash

#==============================================================================#
#
#       STOREPASS
#
# This script encrypts/decrypts the password passed as an argument.
# It also stores it, after encryption, into the server configuration file
# declared in the main script's general configuration file.
#
# Versions
# [2019-12-07] [1.0.1] [Stéphane-Hervé] Updated version
# [2019-09-02] [1.0] [Stéphane-Hervé] First version
#==============================================================================#
# strict mode
set -o nounset


#=== CONFIGURATION FILE
. db-uploader.conf
. "$configuration_file"

#=== THIS SCRIPT DETAILS
VER=1.0.0
myscript="storepass"
myproject="db-uploader"
mycontact="https://github.com/ShaoLunix/$myproject/issues"



#===========#
# VARIABLES #
#===========#
# Required commands
requiredcommand="openssl"
lastargument=""
password=""
passphrase="]MK0U3;Rm;U}1Nw"
encryptedpass=""
decryptedpass=""
display_pass="off"
isdisplayed=false
isinteractive=false
isservice=false
declare -a service
services=( "ftp" "ssh" "db" )
# Verbosity
verbose=0



#===========#
# FUNCTIONS #
#===========#
# Abnormal exit
abnormalExit()
{
    echo "$myscript -- End -- Failed"
    exit 2
}

# Prerequisite not met
prerequisitenotmet()
{
    echo "$requiredcommand : missing"
    echo "Please, install it first and check you can access '$requiredcommand'."
    echo "Programm aborted."
    exit 1
}

# Aborting the script because of a wrong or missing parameter
usage()
{
    echo "Usage: $myscript [-d PASSWORD_STATUS] [-s SERVICE] PASSWORD"
    echo "For more information on how to use the script, type : < $myscript -h >"
    echo "$myscript -- End -- failed"
    exit 1
}

# Show the help of this script
showhelp()
{
    echo "Syntax : $myscript [OPTION ...]"
    echo "$myscript encrypts the password passed in argument."
    echo "With no option, the command returns an error"
    echo
    echo "$myscript [-i|--interactive] [-s|--service SERVICE] PASSWORD"
    echo "$myscript [-d|--display PASSWORD_STATUS] PASSWORD"
    echo "$myscript [-v|--verbose]"
    echo "$myscript [-h|--help]"
    echo "$myscript [-V|--version]"
    echo
    echo "  -d|--display        :        display the encrypted or decrypted password. The PASSWORD_STATUS can be 'encrypted' or 'decrypted'. By default, it is 'off' which means the password will not be displayed."
    echo "  -h|--help|-?        :        display the help."
    echo "  -i|--interactive    :        interactive mode for the password. The password is typed and confirmed at the prompt in a hidden way."
    echo "  -s|--service        :        service the password is required for. The SERVICE argument can be 'FTP' or 'SSH' (insensitive case)."
    echo "  -v|--verbose        :        this script version."
    echo "  -V|--version        :        this script version."
    echo
    echo "Exit status : "
    echo " 0 = success"
    echo " 1 = failure due to wrong parameters"
    echo " 2 = abnormal exit"
    echo
    echo "To inform about the problems : $mycontact."
    exit
}

# Getting the password
# It can be an argument on the command line
# or typed at the prompt in an interactive mode
getPassword()
{
    # If the interactive mode is on
    # Then the password is asked by the script after execution and in a hidden way
    if [ "$isinteractive" == true ]
        then
            pass_1=true
            pass_2=false
            while [ "$pass_1" != "$pass_2" ]
            do
                read -p "Enter password :" -s pass_1
                echo
                read -p "Confirm password :" -s pass_2
                echo
                if [ "$pass_1" == "$pass_2" ]
                    then password="$pass_1"
                    else echo "Passwords do not match. Do it again."
                fi
            done
        else
            password="$lastargument"
    fi
}

#=== MANAGING EXIT SIGNALS
trap 'abnormalExit' 1 2 3 4 15



#=======#
# Flags #
#=======#
# -d : display the encrypted/decrypted password
# -h : show the help
# -i : interactive mode
# -s : service the password is required for
# -v : verbosity level to apply during this script execution
# -V : this script version
while :; do
    case ${1-default} in
        # Showing an usage synopsis.
        -h|-\?|--help)
            showhelp
            exit
            ;;
        # Deciding whether the password must be displayed or not
        -d|--display)
            if [ "${2-default}" ]; then
                display_pass=${2-default}
                isdisplayed=true
                shift
            else
                die 'ERROR: "-d|--display" requires a non-empty option argument.'
            fi
            if [ "$display_pass" != "encrypted" ] && [ "$display_pass" != "decrypted" ] && [ "$display_pass" != "off" ]; then
                usage
            fi
            ;;
        # Deciding whether the password must be asked at a prompt
        -i|--interactive)
            isinteractive=true
            ;;
        # Which service the password concerns
        -s|--service)
            if [ "${2-default}" ]; then
                service=$(echo "${2-default}" | awk '{print tolower($0)}')
                isservice=true
                shift
            else
                die 'ERROR: "-s|--service" requires a non-empty option argument.'
            fi
            #if [ "$service" != "ftp" ] && [ "$service" != "ssh" ] && [ "$service" != "db" ]; then
            if [[ " ${services[*]} " != *" $service "* ]]; then
                usage
            fi
            ;;
        # Definition of the verbosity level
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



#===============#
# PREREQUISITES #
#===============#
#=== Required command
if ! type "$requiredcommand" > /dev/null 2>&1
    then prerequisitenotmet
fi
#=== Required password
lastargument="${@: -1}"
getPassword
if [ -z "$password" ]
    then usage
fi



#======#
# MAIN #
#======#
#=== ENCRYPTION/DECRYPTION OF THE PASSWORD
#=== AND WRITING OF THE PASSWORD INTO THE CONFIGURATION FILE ONLY IF 'OFF' argument is on
case "$display_pass" in
    "encrypted")
                # Encrypting the password
                encryptedpass=$(echo "$password" | openssl enc -e -pbkdf2 -md SHA256 -base64) # -nosalt -pass pass:"$passphrase")
                echo "$encryptedpass"
                exit
                ;;

    "decrypted")
                # Decrypting the password
                decryptedpass=$(echo "$password" | openssl enc -d -pbkdf2 -md SHA256 -base64) # -nosalt -pass pass:"$passphrase" -base64)
                echo "$decryptedpass"
                exit
                ;;

    "off")
                # Encrypting the password
                encryptedpass=$(echo "$password" | openssl enc -e -pbkdf2 -md SHA256 -base64) # -nosalt -pass pass:"$passphrase")
                # Decrypting the password
                decryptedpass=$(echo "$encryptedpass" | openssl enc -d -pbkdf2 -md SHA256 -base64) # -nosalt -pass pass:"$passphrase" -base64)

                #=== WRITING OF THE PASSWORD INTO THE CONFIGURATION FILE
                # Testing if the given password is identical to the dehashed password
                # If YES, then the hashed password is written to the configuration file
                if [ "$decryptedpass" == "$password" ]
                    then
                        for serv in "${service[@]}"
                        do
                            # If the ssh_pass variable can be found in the configuration file
                            # Then the password replaces the one in the file
                            # Else the line is created at its place
                            if grep -Eq "^$serv"_pass "$configuration_file"
                                then
                                    sed -i -E 's/'"$serv""_pass=\".*\""'/'"$serv""_pass=\"$encryptedpass\""'/g' "$configuration_file"
                                else
                                    sed -i '/'"$serv"'_user/a '"$serv""_pass=\"$encryptedpass\"" "$configuration_file"
                            fi
                        done
                    else
                        echo "Something went wrong with the encryption of the password."
                        abnormalExit
                fi
                ;;

    \?) # For invalid option
                usage
                ;;
esac

exit

