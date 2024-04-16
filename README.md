# Apigee Zip-2-API Demo
This demo shows how an Application Integration flow with Cloud Functions can serve zip files with JSON files as a RESTful API to clients.

## Deploy
```sh
# First copy the env file and fill with your own values
cp 1_env.sh 1_env.dev.sh
# Set your project and region in the 1_env.dev.file, then we will source it
source 1_env.dev.sh

# Now let's prepare our GCP project by creating needed resources.
./2_prepare.sh

# Deploy function and integration flow
./3_deploy.sh
```
