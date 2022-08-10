echo "#Go to https://hub.docker.com/ #Register an account an verify your email"

echo "What is your docker username?: "
read YOURDOCKERUSERNAME

echo "What is your docker password?: "
read YOURDOCKERPASSWORD

docker login -u $YOURDOCKERUSERNAME -p $YOURDOCKERPASSWORD docker.io/$YOURDOCKERUSERNAME

crc config set cpus 8
crc config set memory 14366
crc setup
echo "Go to https://console.redhat.com/openshift/create/local and copy the pull secret. You will need to enter this in the next step (Enter to continue): "
read CONTINUE
crc start
eval $(crc oc-env)
echo "Were about to open the browser! Log in with kubeadmin (the password is printed in the terminal output) and navigate to the top right corner and click copy Login command"
sleep 10
crc console
echo "Click on display token and copy the OC login command entirly and paste it here: "
read OC_LOGIN_COMMAND
${OC_LOGIN_COMMAND}

oc new-project forgerockopenshift --display-name 'Forgerock'
oc project forgerockopenshift

echo "Sleeping for a 120s so that the macbook can run background processes"
sleep 120


kubectl apply -f kustomize/base/openshift/scc.yaml
kubectl apply -f kustomize/base/openshift/ds-operator-role.yaml
kubectl apply -f kustomize/base/openshift/standard.yml
kubectl apply -f kustomize/base/openshift/fast.yml
kubectl patch pv pv0014 pv0015 pv0016 pv0017 --type merge -p '{"spec":{"storageClassName": "fast"}}'

echo "Sleeping before certdeploy"
sleep 120

bin/certmanager-deploy.sh
echo "Sleeping for a 60s so that the macbook can run background processes"
sleep 60
bin/ds-operator install
kubectl apply -f https://github.com/ForgeRock/secret-agent/releases/latest/download/secret-agent.yaml
sleep 30
kubectl apply -k kustomize/base/secrets/
sleep 10
kubectl get sac
sleep 10
kubectl apply -k kustomize/base/secrets/
skaffold config set default-repo docker.io/$YOURDOCKERUSERNAME  -k forgerockopenshift/api-crc-testing:6443/kubeadmin
skaffold run --profile small
bin/forgeops info

echo "edit /etc/hosts as ROOT and prod.iam.example.com to the list of openshift aliases"
echo "Open your browser and go to: https://prod.iam.example.com/platform/"
echo "log in with credentials posted by the bin/forgeops info command"