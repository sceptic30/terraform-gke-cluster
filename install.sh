#!bin/bash
echo "[kubernetes-nodes]" | tee ansible/inventory
sleep 2;
terraform output -json | jq -r '@sh "export project_id=\(.project_id.value)\nexport region=\(.region.value)\nexport zones=\(.zones.value)\nexport cluster_name=\(.cluster_name.value)"' | sed -e "s/'//g" -e "s/ /,/g" -e "s/export,/export /" | tee env.sh && truncate -s -1 env.sh && chmod a+x env.sh && source env.sh
sleep 2;
gcloud container clusters get-credentials $cluster_name --region $region --project $project_id
sleep 2;
gcloud compute instances list | grep $cluster_name | awk '{print $1, "ansible_ssh_host="$5}' | tee -a ansible/inventory
sleep 2;

echo -e "${GREEN}Creating One Disk Per Zone${ENDCOLOR}"
sleep 2;
IFS=', ' read -r -a zones_array <<< "$zones"
sleep 2;
for x in "${!zones_array[@]}"; do
printf "%s\t%s\n" "gcloud compute disks create block-s$x --size=100GB --type pd-balanced --zone=${zones_array[$x]}"; done | tee create_disks.sh && chmod a+x create_disks.sh;
while read disk_creation; do $disk_creation; sleep 5; done < create_disks.sh
sleep 2;


echo -e "${GREEN}Attaching Persistent Disks To Nodes/per Zone${ENDCOLOR}"
##Creation of the begining of the final command file
gcloud compute disks list | grep block | awk '{print "gcloud compute instances attach-disk"}' > base_attach_command
##Lets create a file with our Node Instances
gcloud compute instances list | grep $cluster_name | awk '{print $1}' > node_instances
paste -d ' ' base_attach_command node_instances > pre_final
##Now we need to query GCP to retrieve a list with each disk per zone
gcloud compute disks list | grep block | awk '{print "--disk "$1, "--zone "$2}' > pre_disk_command
##Now we join the content of each files side by side to produce the final command file
paste -d ' ' pre_final pre_disk_command | tee attach_disks.sh
while read disk_creation;
do 
    $disk_creation;
    sleep 10; 
done < attach_disks.sh
rm base_attach_command node_instances pre_final pre_disk_command

echo -e "${GREEN}Enable Role-Based Access Control${ENDCOLOR}"
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$CLUSTER_ADMIN_EMAIL
sleep 5;

echo -e "${GREEN}Persisten Disk Mount Naming${ENDCOLOR}"
sed -i "s/disk1/$PERST_DISK_MNT_NAME/g" ansible/vars/gke.yaml
sed -i "s/disk1/$PERST_DISK_MNT_NAME/g" longhorn/install.yaml

echo -e "${GREEN}Applying given BASE_DOMAIN to related files${ENDCOLOR}"
sed -i "s/example.com/$BASE_DOMAIN/g" external-dns/install.yaml
sleep 1;
sed -i "s/example.com/$BASE_DOMAIN/g" external-dns/values.yaml
sleep 1;
sed -i "s/example.com/$BASE_DOMAIN/g" haproxy/ingress-install.yaml
sleep 1;
sed -i "s/example.com/$BASE_DOMAIN/g" longhorn/ingress-router.yaml
sleep 1;
sed -i "s/example.com/$BASE_DOMAIN/g" netdata/ingress-router.yaml
sleep 1;
sed -i "s/example.com/$BASE_DOMAIN/g" netdata/install.yaml
sleep 1;
sed -i "s/example.com/$BASE_DOMAIN/g" nginx/ingress-router.yaml
sleep 1;
sed -i "s/example.com/$BASE_DOMAIN/g" nginx/webserver-config.yaml
sleep 1;
sed -i "s/example.com/$BASE_DOMAIN/g" jenkins/ingress-router.yaml

echo -e "${GREEN}Applying Provided Email Address To Cluster Issuers${ENDCOLOR}"
sed -i "s/user@example.com/$CLUSTER_ADMIN_EMAIL/g" certmanager/production-issuer.yaml
sed -i "s/user@example.com/$CLUSTER_ADMIN_EMAIL/g" certmanager/staging-issuer.yaml

echo -e "${GREEN}Preparing Servers For Longhorn Installation${ENDCOLOR}"
ansible-playbook -i ansible/inventory -u root --private-key keys/root_id_ed25519 ansible/longhorn-prerequisites.yaml

echo -e "${GREEN}Installing CertManager and configuring ClusterIssuer${ENDCOLOR}"
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml
sleep 30;
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.crds.yaml
sleep 5;
kubectl apply -f certmanager/production-issuer.yaml
sleep 5;
kubectl apply -f certmanager/staging-issuer.yaml

echo -e "${GREEN}Installing External-DNS${ENDCOLOR}"
kubectl create ns external-dns
sleep 1;
sed -i "s/my_google_project/$project_id/g" external-dns/install.yaml
sleep 2;
dns_admin_sa=$(gcloud projects get-iam-policy $project_id --flatten="bindings[].members" --format="table(bindings.members)" --filter="bindings.role:dns.admin" | grep external-dns)
dns_admin_secr_exist=$(kubectl get secret external-dns-secret -n external-dns)
sleep 3;
if [ $dns_admin_sa ] && [ ! $dns_admin_secr_exist ];
    then 
        echo -e "${YELLOW}A service account with DNS.ADMIN Role already Exists. Skipping Creation Of Service Account and Creating Bind-Policy, Credentials and Secret ${ENDCOLOR}"
        gcloud projects add-iam-policy-binding $project_id --role="roles/dns.admin" --member="serviceAccount:external-dns@$project_id.iam.gserviceaccount.com"
        sleep 5;
        gcloud iam service-accounts keys create external-dns-credentials.json --iam-account external-dns@$project_id.iam.gserviceaccount.com
        sleep 5;
        kubectl create secret generic external-dns-secret --from-file=credentials.json=external-dns-credentials.json -n external-dns        
    else 
        echo -e "${GREEN}Creating Service Account, Bind-Policy, Credentials and Secret${ENDCOLOR}"
        gcloud iam service-accounts create external-dns --display-name "Service account for ExternalDNS on GCP"
        sleep 5;
        gcloud projects add-iam-policy-binding $project_id --role="roles/dns.admin" --member="serviceAccount:external-dns@$project_id.iam.gserviceaccount.com"
        sleep 5;
        gcloud iam service-accounts keys create external-dns-credentials.json --iam-account external-dns@$project_id.iam.gserviceaccount.com
        sleep 5;
        kubectl create secret generic external-dns-secret --from-file=credentials.json=external-dns-credentials.json -n external-dns
fi
sleep 2;
kubectl apply -f external-dns/install.yaml
sleep 10;
echo -e "${GREEN}Installing Haproxy Ingress Controller${ENDCOLOR}"
kubectl create ns haproxy-ingress
sleep 5;
kubectl apply -f haproxy/ingress-install.yaml
sleep 30;
kubectl apply -f haproxy/configmap.yaml
sleep 5;

echo -e "${GREEN}Installing NFS Backup Server${ENDCOLOR}"
kubectl apply -f longhorn/nsf-backup-server.yaml
sleep 10;
echo -e "${GREEN}Installing Longhorn${ENDCOLOR}"
kubectl apply -f longhorn/install.yaml
sleep 60;

echo -e "${GREEN}Installing Ingress Routes Object${ENDCOLOR}"
kubectl apply -f longhorn/ingress-router.yaml
sleep 3;

echo -e "${GREEN}Installing NetData Observability-Monitoring Software${ENDCOLOR}"
kubectl create ns netdata
git clone https://github.com/sceptic30/netdata-helmchart.git
sed -i "s/example.com/$BASE_DOMAIN/g" netdata-helmchart/charts/netdata/values.yaml
sed -i "s/token: \"\"/token: \"$NETDATA_TOKEN\"/g" netdata-helmchart/charts/netdata/values.yaml
sed -i "s/rooms: \"\"/rooms: \"$NETDATA_ROOMS\"/g" netdata-helmchart/charts/netdata/values.yaml
sed -i "s/accessmodes: ReadWriteOnce/accessmodes: $ACCESSMODE/g" netdata-helmchart/charts/netdata/values.yaml
sed -i "s/storageclass: \"-\"/storageclass: \"$STORAGE_CLASS\"/g" netdata-helmchart/charts/netdata/values.yaml
helm template netdata -f netdata-helmchart/charts/netdata/values.yaml netdata-helmchart/charts/netdata --namespace netdata > netdata/install.yaml
kubectl apply -f netdata/install.yaml

echo -e "${GREEN}Creating Persisten Volume Clain For Nginx, and Initiate Containers${ENDCOLOR}"
kubectl create ns production
kubectl apply -f nginx/nginx-pvc.yaml
kubectl apply -f nginx/webserver-config.yaml
kubectl apply -f nginx/nginx-stateful.yaml
echo -e "${YELLOW}Waiting 60 Seconds For Nginx Pods To Fire Up...${ENDCOLOR}"
kubectl wait --for=condition=Ready pod/nginx-0 -n production --timeout=120s
kubectl apply -f nginx/ingress-router.yaml
echo -e "${GREEN}Uploading Demo HTML Content For Nginx To Serve${ENDCOLOR}"
cd nginx/html_public && tar -cf - * | kubectl exec -i -n production nginx-0 -- tar xf - -C /var/www/html
cd ../../
echo -e "${GREEN}Installing Jenkins CI/CD Server${ENDCOLOR}"
kubectl create ns jenkins
kubectl apply -f jenkins/rbac.yaml
kubectl apply -f jenkins/service.yaml
kubectl apply -f jenkins/statefulset.yaml
kubectl wait --for=condition=Ready pod/jenkins-master-0 -n jenkins --timeout=300s
kubectl apply -f jenkins/ingress-router.yaml