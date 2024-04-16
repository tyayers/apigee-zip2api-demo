echo "Deploy cloud function..."
cd function
gcloud functions deploy zip-function \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=. \
  --entry-point=zip-ops-handler \
  --trigger-http \
  --no-allow-unauthenticated
cd ..

echo "Deploy and publish integration flow..."
curl -X POST "https://integrations.googleapis.com/v1/projects/$PROJECT/locations/$REGION/integrations/ZipFlow-v1/versions" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json; charset=utf-8' \
  --data-binary @./integrations/ZipFlow-v1.dev.json

integrationcli integrations versions publish -t $TOKEN -n ZipFlow-v1 -p $PROJECT -r $REGION -s 1