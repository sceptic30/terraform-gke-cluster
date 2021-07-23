#!/bin/bash
unset Longhorn_Credentials
add_Longhorn_credentials='y'
declare -A Longhorn_Credentials
while [[ "$add_Longhorn_credentials" == y ]]; do
  read -p 'Enter Longhorn Username: ' longhorn_username
  read -p 'Enter Longhorn Password: ' longhorn_password
  Longhorn_Credentials[$longhorn_username]+=$longhorn_password
  add_Longhorn_credentials='n'
done
echo -e "${CYAN}Your Longhorn Username is: ${ENDCOLOR}" ${!Longhorn_Credentials[@]}
echo -e "${CYAN}Your Longhorn Password is: ${ENDCOLOR}" ${Longhorn_Credentials[@]}
htpasswd -bnBC 12 "${!Longhorn_Credentials[@]}" ${Longhorn_Credentials[@]} | tr -d '\n' | printf "%s" "$(</dev/stdin)" | kubectl create secret generic longhorn-basic-auth --from-file=auth=/dev/stdin -n longhorn-system
unset Longhorn_Credentials