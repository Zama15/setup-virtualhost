#!/bin/bash

# ========== DEFINE THE VARIABLES ==========

# apache conf to change
FILE=zapache.conf
APACHE_CONF_FILE="apache2"

# use the current directory as the project path
PROJECT_PATH_DEFAULT="$(pwd)"

# Ip address and port
IP_DEFAULT="127.0.0.1"
PORT_DEFAULT="2000"
IP_REGEX="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"

# Posibles values for the options
OPTIONS=("Indexes" "FollowSymLinks" "ExecCGI" "Includes" "MultiViews" "SymLinksIfOwnerMatch")
ALLOW_OVERRIDE=("None" "All")
REQUIRE=("All" "Denied" "Granted")

# Configs Modifiable
overwrite=true
ip=""
port=""
project_path=""
server_alias=""
directory_options=()
directory_allow_override=()
directory_require=()
error_log=""
custom_log=""
conf_path=""
conf_file_path=""

# ========== DEFINE THE FUNCTIONS ==========

function echo_error {
  echo -e "\e[31m$1\e[0m" >&2
  exit 1
}

function usage {
  echo "Usage: bash $0 [options]"
  echo "Options:"
  echo "  -w  --overwrite"
  echo -e "      Overwrite the $APACHE_CONF_FILE.conf file. Default is true\n"
  echo "  -i  --ip <ip>"
  echo -e "      The ip address to listen to. Default is $IP_DEFAULT\n"
  echo "  -p  --project-path <path>"
  echo -e "      The path to the project. Default is the current directory\n"
  echo "  -po --port <port>"
  echo -e "      The port to listen to. Default is $PORT_DEFAULT\n"
  echo "  -a  --server-alias <alias>"
  echo -e "      The server alias.\n"
  echo "  -o  --options <options1> <options2> <options3>..."
  echo -e "      The directory options. Default is \"Indexes FollowSymLinks Includes ExecCGI\"\n"
  echo "  -l  --allow-override <options1> <options2>..."
  echo -e "      The directory allow override. Default is \"All\"\n"
  echo "  -r  --require <options1> <options2>..."
  echo -e "      The directory require. Default is \"All Granted\"\n"
  echo "  -e  --error-log <path>"
  echo -e "      The path to the error log. Default is \"\${APACHE_LOG_DIR}/error.log\"\n"
  echo "  -c  --custom-log <path>"
  echo -e "      The path to the custom log. Default is \"\${APACHE_LOG_DIR}/access.log\"\n"
  echo "  -cp --conf-path <path>"
  echo "      The path to the $APACHE_CONF_FILE configuration file. Default is the following:"
  echo "           Linux(linux-gnu): /etc/apache2/$APACHE_CONF_FILE"
  echo "           MacOS(darwin): /usr/local/etc/apache2/$APACHE_CONF_FILE"
  exit 0
}

function validate_log {
  if [[ -z "$2" ]]; then
    echo_error "TypeError: option $1 requires an argument"
  elif ! [[ $2 == *.log ]]; then
    echo_error "Invalid argument: $2 must be a log file"
  elif ! [[ -f "$2" ]]; then
    echo_error "Invalid argument: $2 must exist"
  else
    echo "$2"
  fi
}

function loading_animation {
  local chars="/-\|"
  while :; do
    for (( i=0; i<${#chars}; i++ )); do
      echo -en "$1 ${chars:$i:1}" "\r"
      sleep 0.1
    done
  done
}
# ========== PARSE THE ARGUMENTS ==========

while [[ $# > 0 ]]; do
  key="$1"
  case $key in
    -i|--ip)
      if [[ -z "$2" ]]; then
        echo_error "TypeError: option $key requires an argument"
      elif ! [[ "$2" =~ $IP_REGEX ]]; then
        echo_error "Invalid argument: $2 must be a valid ip address"
      else
        ip="$2"
      fi
      shift
      ;;
    -p|--project-path)
      if [[ -z "$2" ]]; then
        echo_error "TypeError: option $key requires an argument"
      else
        project_path=$(realpath -m "$2")
        if [[ ! -d "$project_path" ]]; then
          echo_error "Invalid argument: $project_path must be a valid directory"
        fi
      fi
      shift
      ;;
    -po|--port)
      if [[ -z "$2" ]]; then
        echo_error "TypeError: option $key requires an argument"
      elif ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo_error "Invalid argument: $2 must be a number"
      else
        port="$2"
      fi
      shift
      ;;
    -a|--server-alias)
      temp="$2"
      if [[ -z "$temp" ]]; then
        echo_error "TypeError: option $key requires an argument"
      elif ! [[ "$temp" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo_error "Invalid argument: $temp must have lowercase, uppercase, numbers, hyphens and underscores"
      else
        server_alias="${temp,,}"
      fi
      shift
      ;;
    -o|--directory-options)
      while ! [[ "$2" =~ -.* ]] && [[ $# > 1 ]]; do
        directory_options+=("$2")
        shift && [[ "$2" =~ ^-.\* ]] && break
      done
      ;;
    -l|--directory-allow-override)
      while ! [[ "$2" =~ -.* ]] && [[ $# > 1 ]]; do
        directory_allow_override+=("$2")
        shift && [[ "$2" =~ ^-.\* ]] && break
      done
      ;;
    -r|--directory-require)
      while ! [[ "$2" =~ -.* ]] && [[ $# > 1 ]]; do
        directory_require+=("$2")
        shift && [[ "$2" =~ ^-.\* ]] && break
      done
      ;;
    -e|--error-log)
      error_log=$(validate_log "$key" "$2")
      shift
      ;;
    -c|--custom-log)
      custom_log=$(validate_log "$key" "$2")
      shift
      ;;
    -cp|--conf-path)
      if [[ -z "$2" ]]; then
        echo_error "TypeError: option $key requires an argument"
        exit 1
      fi

      resolved_path=$(realpath -m "$2") || {
        echo_error "Invalid argument: $2 cannot be resolved"
        exit 1
      }

      if [[ -d "$resolved_path" ]]; then
        # It is a directory
        conf_path="$resolved_path"
      elif [[ "$resolved_path" =~ /[^/]+$ ]]; then
        # It is a file
        if [[ "$resolved_path" =~ \.conf$ ]]; then
          # It is a conf file
          APACHE_CONF_FILE=$(basename "$resolved_path" .conf)
          conf_path=$(dirname "$resolved_path")
        else
          # It is a file without extension
          APACHE_CONF_FILE="${resolved_path##*/}"
          conf_path="${resolved_path%/*}"
        fi

        if ! conf_path=$(realpath -m "$conf_path"); then
          echo_error "Invalid directory in path: ${conf_path:-$2}"
          exit 1
        fi
      else
        echo_error "Invalid argument: $conf_path must be a valid directory or file"
        exit 1
      fi
      shift
      ;;
    -w|--overwrite)
      overwrite=false
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo_error "Invalid option: $key"
      ;;
  esac
  shift
done

# ========== VALIDATE THE ARGUMENTS ==========

# check if the ip is empty
if [[ -z "$ip" ]]; then
  ip="$IP_DEFAULT"
fi

# check if the port is empty
if [[ -z "$port" ]]; then
  port="$PORT_DEFAULT"
fi

# check if the project path is empty
if [[ -z "$project_path" ]]; then
  project_path="$PROJECT_PATH_DEFAULT"
fi

# check if options were set and if they are valid
if ! [[ ${#directory_options[@]} -eq 0 ]]; then
  for value in ${directory_options[@]}; do
    if ! [[ " ${OPTIONS[@],,} " =~ " ${value,,} " ]]; then
      echo_error "Invalid option: \"${value,,}\" must be one of \"${OPTIONS[*],,}\""
    fi
  done
else
  directory_options=("Indexes" "FollowSymLinks" "Includes" "ExecCGI")
fi

# check if allow override were set and if they are valid
if ! [[ ${#directory_allow_override[@]} -eq 0 ]]; then
  for value in ${directory_allow_override[@]}; do
    if ! [[ " ${ALLOW_OVERRIDE[@],,} " =~ " ${value,,} " ]]; then
      echo_error "Invalid option: \"${value,,}\" must be one of \"${ALLOW_OVERRIDE[*],,}\""
    fi
  done
else
  directory_allow_override=("All")
fi

# check if require were set and if they are valid
if ! [[ ${#directory_require[@]} -eq 0 ]]; then
  for value in ${directory_require[@]}; do
    if ! [[ " ${REQUIRE[@],,} " =~ " ${value,,} " ]]; then
      echo_error "Invalid option: \"${value,,}\" must be one of \"${REQUIRE[*],,}\""
    fi
  done
else
  directory_require=("All" "Granted")
fi

# check if the error log is set
if [[ -z "$error_log" ]]; then
  error_log="\${APACHE_LOG_DIR}/error.log"
fi

# check if the custom log is set
if [[ -z "$custom_log" ]]; then
  custom_log="\${APACHE_LOG_DIR}/access.log"
fi

# check if the conf file exists
if [ ! -f "$FILE" ]; then
  touch "$FILE"
fi

# ========== CONSTRUCT THE VIRTUAL HOST CONFIGURATION ==========
CONF=()

CONF+=("Listen $port")
CONF+=("")
CONF+=("<VirtualHost $ip:$port>")
if [[ -n "$server_alias" ]]; then
  CONF+=("\\tServerName $server_alias.zdev")
  CONF+=("\\tServerAlias www.$server_alias.zdev")
fi
CONF+=("\\tDocumentRoot $project_path")
CONF+=("")
CONF+=("\\t<Directory $project_path>")
CONF+=("\\t\\tOptions ${directory_options[*],,}")
CONF+=("\\t\\tAllowOverride ${directory_allow_override[*],,}")
CONF+=("\\t\\tRequire ${directory_require[*],,}")
CONF+=("\\t</Directory>")
CONF+=("")
CONF+=("\\tErrorLog $error_log")
CONF+=("\\tCustomLog $custom_log combined")
CONF+=("</VirtualHost>")

CONF_STR="$(printf '%s\\n' "${CONF[@]}")"

# temp=$(bash check_conf.sh "$CONF_STR")
# ========== CONSTRUCT THE CONFIRMATION MESSAGE ==========
INFO=()

function echo_info {
  echo -e "\e[34m$1\e[0m"
}
INFO+=("\nApache Configuration:")
INFO+=("  Listening on: \e[34mhttp://$ip:$port\e[0m\n")
if [[ -n "$server_alias" ]]; then
  INFO+=("  Server Alias: \e[34mhttp://$server_alias.zdev\e[0m")
  INFO+=("  Server Alias: \e[34mhttp://www.$server_alias.zdev\e[0m\n")
fi
INFO+=("  Project Path: $project_path\n")
INFO+=("  Directory Options: ${directory_options[*],,}")
INFO+=("  Directory Allow Override: ${directory_allow_override[*],,}")
INFO+=("  Directory Require: ${directory_require[*],,}")

INFO_STR="$(printf '%s\\n' "${INFO[@]}")"

# ========== SEARCH FOR THE APACHE CONF FILE ==========

# Initialize the loading animation
loading_animation "Configuring Apache..." &
loading_pid=$!

# call search_apache_conf.sh to verify the conf path
error_search_apache_conf=0
if [[ -n "$conf_path" ]]; then
  conf_file_path=$(bash search_apache_conf.sh "$APACHE_CONF_FILE" -cp "$conf_path")
  error_search_apache_conf=$?
else
  conf_file_path=$(bash search_apache_conf.sh "$APACHE_CONF_FILE")
  error_search_apache_conf=$?
fi

# Stop the loading animation
kill $loading_pid
wait $loading_pid 2>/dev/null

# Clean the loading animation
echo -en "\r\033[K"

# Stop the script if an error occurred
if [ $error_search_apache_conf -ne 0 ]; then
  exit 1
fi
# ========== ADD CONFIGURATION TO THE APACHE CONF FILE ==========
# Check if overwrite is true and add or overwrite zapache.conf
if [[ "$overwrite" == true ]]; then
  echo -e "$CONF_STR" > "$FILE"
else
  echo -e "$CONF_STR" >> "$FILE"
fi

# Run the script as root to modify the apache conf file
#   1. Include the zapache.conf file in the apache2.conf file
#   2. Skip if the include already exists
#   3. Restart Apache
sudo -s <<EOF

echo "Including the $FILE file in the $APACHE_CONF_FILE.conf file..."
if [[ -n "$conf_file_path" ]]; then
  if ! grep -q "Include $PROJECT_PATH_DEFAULT/$FILE" "$conf_file_path"; then
    echo "Include $PROJECT_PATH_DEFAULT/$FILE" >> "$conf_file_path"
  else
    echo "Include already exists, skipping..."
  fi
else
  echo_error "Error: $APACHE_CONF_FILE.conf file not found. Check your apache installation"
fi

echo "Restarting Apache..."
if ! service apache2 restart > /dev/null 2>&1; then
  echo -e "\e[31mError: apache2 could not be restarted, restart it manually\e[0m"
  service apache2 restart
else
  echo -e "\e[32mApache has been configured successfully\e[0m"
fi

echo -e "$INFO_STR"

exit 0
EOF
