#!/bin/bash
unset Netdata_Credentials
add_Netdata_credentials='y'
declare -A Netdata_Credentials
while [[ "$add_Netdata_credentials" == y ]]; do
  read -p 'Enter Netdata Username: ' netdata_username
  read -p 'Enter Netdata Password: ' netdata_password
  Netdata_Credentials[$netdata_username]+=$netdata_password
  add_Netdata_credentials='n'
done
echo -e "${CYAN}Your Netdata Username is: ${ENDCOLOR}" ${!Netdata_Credentials[@]}
echo -e "${CYAN}Your Netdata Password is: ${ENDCOLOR}" ${Netdata_Credentials[@]}
htpasswd -bnBC 12 "${!Netdata_Credentials[@]}" ${Netdata_Credentials[@]} | tr -d '\n' | printf "%s" "$(</dev/stdin)" | kubectl create secret generic netdata-basic-auth --from-file=auth=/dev/stdin -n netdata
unset Netdata_Credentials