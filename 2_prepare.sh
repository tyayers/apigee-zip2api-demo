echo "Setting project to $PROJECT"
gcloud config set project $PROJECT
TOKEN=$(gcloud auth print-access-token)

echo "Enabling APIs..."
gcloud services enable integrations.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable connectors.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable run.googleapis.com

echo "Installing application integration CLI..."
curl -L https://raw.githubusercontent.com/GoogleCloudPlatform/application-integration-management-toolkit/main/downloadLatest.sh | sh -
export PATH=$PATH:$HOME/.integrationcli/bin

echo "Provision Application Integration..."
curl -X POST "https://integrations.googleapis.com/v1/projects/$PROJECT/locations/$REGION/clients:provision" \
  -H "Authorization: Bearer $TOKEN"

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
  --data-binary @./integrations/AuthProfile.json

echo "Deploy integration flow..."
curl -X POST "https://integrations.googleapis.com/v1/projects/$PROJECT/locations/$REGION/integrations/ZipFlow-v1/versions" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json; charset=utf-8' \
  --data-binary @./integrations/ZipFlow-v1.json

curl -X POST "https://integrations.googleapis.com/v1/projects/$PROJECT/locations/$REGION/integrations/ZipFlow-v1/versions/18a8f083-b5a9-4b10-8490-52a7f22b3de4:publish" \
  -H "Authorization: Bearer $TOKEN"