#!/bin/bash

# ========== DEFINE THE VARIABLES ==========
# The virtual host block to add
VH_STR="$1"

echo "VH_ARR: $VH_STR" >&2

placeholder=";"
placeholder2=""

new_string="${VH_STR//\\n/$placeholder}"
new_string="${new_string//\\t/$placeholder2}"

echo "new_string: $new_string" >&2

IFS="$placeholder"
read -r -a new_arr <<< "$new_string"

# main_arr=()
# for e in "${new_arr[@]}"; do
#   if [[ -n "$e" ]]; then
#     main_arr+=("$e")
#   fi
# done
main_arr=($(printf "%s\n" "${main_arr[@]}" | grep -v '^$'))

for((i=0; i<${#main_arr[@]}; i++)); do
  echo "VH_ARR[$i]: ${main_arr[$i]}" >&2
done
