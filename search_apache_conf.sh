#!/bin/bash

# ========== DEFINE THE VARIABLES ==========
# The apache configuration file to search
CONF_FILE="$1.conf"

# Possible paths for the apache configuration file
LINUX_CONF_PATH="/etc/apache2"
MACOS_CONF_PATH="/usr/local/etc/apache2"
CUSTOM_CONF_PATH=""

# case variable
os_case=""

# ========== DEFINE THE FUNCTIONS ==========

function echo_error {
  echo -e "\e[31m$1\e[0m" >&2
  exit 1
}

function echo_error_no_exit {
  echo -e "\e[31m$1\e[0m" >&2
}

function conf_file_exists {
  if [ -f "$1" ]; then
    echo "$1"
    exit 0
  fi
}

function find_conf_stdout {
  local temp=$(find "$1" -name "$2" -type f 2>/dev/null)
  echo "$temp"
}

function find_conf_stderr {
  local temp=$(find "$1" -name "$2" -type f 2>&1 >/dev/null)
  echo "$temp"
}

# ========== PARSE THE ARGUMENTS ==========

if [[ -z "$1" ]]; then
  echo_error "TypeError: missing conf file argument"
fi

while [[ $# > 1 ]]; do
  key="$2"
  case $key in
    -cp|--conf-path)
      temp="$3"
      if [[ -z "$temp" ]]; then
        echo_error "TypeError: option $key requires an argument"
      else
        CUSTOM_CONF_PATH=$(realpath -m "$temp")
        if [[ ! -d "$CUSTOM_CONF_PATH" ]]; then
          echo_error "Invalid argument: $CUSTOM_CONF_PATH must be a valid directory"
        fi
      fi
      shift
      ;;
    *)
      echo_error "Invalid option: $key"
      ;;
  esac
  shift
done

# ========== DETERMINE THE OPERATING SYSTEM ==========
if [[ -n "$CUSTOM_CONF_PATH" ]]; then
  os_case="custom"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  os_case="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  os_case="macos"
else
  echo_error "Error: Unsupported operating system"
fi

# ========== VERIFY CONF FILE ==========
case $os_case in
  "linux")
    conf_file_exists "$LINUX_CONF_PATH/$CONF_FILE"
    ;;
  "macos")
    conf_file_exists "$MACOS_CONF_PATH/$CONF_FILE"
    ;;
  "custom")
    conf_file_exists "$CUSTOM_CONF_PATH/$CONF_FILE"
    ;;
esac

# ========== SEARCH FOR THE CONF FILE ==========
temp_conf_path=""
output_error=""

# Search the file in the parent directory
# output error get the stderr(2) messages to avoid echoing it and send stdout(1) to /dev/null
# temp_conf_path get the stdout(1) messages and send stderr(2) to /dev/null to avoid echoing it
case $os_case in
  "linux")
    output_error=$(find_conf_stderr "$LINUX_CONF_PATH/.." "$CONF_FILE")
    temp_conf_path=$(find_conf_stdout "$LINUX_CONF_PATH/.." "$CONF_FILE")
    ;;
  "macos")
    output_error=$(find_conf_stderr "$MACOS_CONF_PATH/.." "$CONF_FILE")
    temp_conf_path=$(find_conf_stdout "$MACOS_CONF_PATH/.." "$CONF_FILE")
    ;;
  "custom")
    output_error=$(find_conf_stderr "$CUSTOM_CONF_PATH" "$CONF_FILE")
    temp_conf_path=$(find_conf_stdout "$CUSTOM_CONF_PATH" "$CONF_FILE")
    ;;
esac

# Check if the conf file exists
conf_file_exists "$temp_conf_path"

# ========== OUTPUT THE ERROR ==========
echo_error_no_exit "Error: Unable to find the $CONF_FILE file"
echo "$output_error" >&2

if [[ "$output_error" == *"Permission denied"* ]]; then
  echo_error_no_exit "Permission denied: Unable to access the specified path"
else
  echo_error_no_exit "Unknown error occurred while searching for the conf file"
fi

echo -e "\e[33mUse -cp or --conf-path option to specify the path to search the conf file\e[0m" >&2
exit 1
