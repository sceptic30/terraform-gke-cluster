#!/bin/bash
export GREEN="\e[32m"
export YELLOW="\e[33m"
export RED="\e[91m"
export CYAN="\e[96m"
export ENDCOLOR="\e[0m"
export ANSIBLE_HOST_KEY_CHECKING=False
export command_warnings=False
export deprecation_warnings=False
export BASE_DOMAIN=$BASE_DOMAIN
export NETDATA_TOKEN=your_netdata_token
export NETDATA_ROOMS=your-netdata-rooms
export STORAGE_CLASS=longhorn
export ACCESSMODE=ReadWriteMany
export PERST_DISK_MNT_NAME=disk1 #Default value (/mnt/disk1). Change it if you want to use a different folder mount to persistent disks.
export CLUSTER_ADMIN_EMAIL=user@$example.com

if ! command -v helm &> /dev/null
then
    echo -e "${RED}helm could not be found${ENDCOLOR}"
    echo -e "${GREEN}Intalling Helm Now...${ENDCOLOR}"
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
fi
terraform init
terraform apply
echo -e "${GREEN}--------Software Rollout Completed--------${ENDCOLOR}"
echo -e "${GREEN}Begining creation of Longhorn Basic Auth Secret To Secure Its UI${ENDCOLOR}"
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
sed -i "s/#//g" longhorn/ingress-router.yaml
kubectl apply -f longhorn/ingress-router.yaml


echo "Begining creation of NetData Basic Auth Secret To Secure Its UI."
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
sed -i "s/#//g" netdata/ingress-router.yaml
kubectl apply -f netdata/ingress-router.yaml
echo -e "${GREEN}#####---Installation Successfully Completed!---#####${ENDCOLOR}"