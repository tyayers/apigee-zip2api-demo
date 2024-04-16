echo "Setting project to $PROJECT"
gcloud config set project $PROJECT
TOKEN=$(gcloud auth print-access-token)

echo "Enabling APIs..."
gcloud services enable integrations.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable connectors.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable cloudkms.googleapis.com

echo "Installing application integration CLI..."
curl -L https://raw.githubusercontent.com/GoogleCloudPlatform/application-integration-management-toolkit/main/downloadLatest.sh | sh -
export PATH=$PATH:$HOME/.integrationcli/bin

# Sleep 5 seconds to let the API be initialized...
sleep 5

echo "Provision Cloud KMS..."
gcloud kms keyrings create "integration-keys" \
    --location "$REGION"
gcloud kms keys create "integration-key" \
    --location "$REGION" \
    --keyring "integration-keys" \
    --purpose "encryption"

echo "Provision Application Integration..."
integrationcli provision -t $TOKEN -p $PROJECT -r $REGION -k projects/$PROJECT/locations/$REGION/keyRings/integration-keys/cryptoKeys/integration-key/cryptoKeyVersions/1

echo "Create service account..."
gcloud iam service-accounts create zipservice \
    --description="Service account to manage zip resources" \
    --display-name="Zip Service"

echo "Add service account roles..."
gcloud projects add-iam-policy-binding $PROJECT \
    --member="serviceAccount:zipservice@$PROJECT.iam.gserviceaccount.com" \
    --role="roles/integrations.integrationInvoker"
gcloud projects add-iam-policy-binding $PROJECT \
    --member="serviceAccount:zipservice@$PROJECT.iam.gserviceaccount.com" \
    --role="roles/run.invoker"
gcloud projects add-iam-policy-binding $PROJECT \
    --member="serviceAccount:zipservice@$PROJECT.iam.gserviceaccount.com" \
    --role="roles/cloudfunctions.invoker"

echo "Create integration auth profile..."
curl -X POST "https://integrations.googleapis.com/v1/projects/$PROJECT/locations/$REGION/authConfigs" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json; charset=utf-8' \
  --data-binary @- << EOF

{
  "displayName": "Zip Auth Profile",
  "decryptedCredential": {
    "credentialType": "SERVICE_ACCOUNT",
    "serviceAccountCredentials": {
      "serviceAccount": "zipservice@$PROJECT.iam.gserviceaccount.com",
      "scope": "https://www.googleapis.com/auth/cloud-platform"
    }
  }
}
EOF

echo "Replace variables in integartion flow..."
cp ./integrations/ZipFlow-v1.json ./integrations/ZipFlow-v1.dev.json
sed -i "s@FUNCTIONS_REGION@$REGION@" ./integrations/ZipFlow-v1.dev.json
sed -i "s@FUNCTIONS_PROJECT@$PROJECT@" ./integrations/ZipFlow-v1.dev.json
