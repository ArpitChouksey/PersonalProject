
#!/usr/bin/env bash

PROJECT_ID="aws-gcp-migration-lab"

echo "Checking GCP project deletion status..."

if OUTPUT=$(gcloud projects describe "$PROJECT_ID" \
    --format="value(lifecycleState)" 2>&1); then
  echo "Project lifecycle state: $OUTPUT"

  if [[ "$OUTPUT" == "DELETE_REQUESTED" ]]; then
    echo "STATUS: Deletion is still processing."
  else
    echo "STATUS: Project is not in DELETE_REQUESTED state."
  fi
else
  echo "$OUTPUT"
  echo "Project is no longer accessible by this command."
  echo "Verify in Google Cloud Console before concluding cleanup."
fi

