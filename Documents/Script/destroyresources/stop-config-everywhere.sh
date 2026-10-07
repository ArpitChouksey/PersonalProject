#!/bin/bash

set +e

ACCOUNTS=(
211811255273
360734036001
070977799818
025775692925
325909447008
152500409784
038269111064
)

REGIONS=$(aws account list-regions \
  --region us-east-1 \
  --query 'Regions[?RegionOptStatus==`ENABLED`].RegionName' \
  --output text 2>/dev/null)

for ACCOUNT in "${ACCOUNTS[@]}"; do

    echo
    echo "=================================================="
    echo "ACCOUNT: $ACCOUNT"
    echo "=================================================="

    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN

    if [ "$ACCOUNT" != "211811255273" ]; then

        CREDS=$(aws sts assume-role \
          --role-arn arn:aws:iam::$ACCOUNT:role/OrganizationAccountAccessRole \
          --role-session-name config-cleanup \
          --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
          --output text 2>/dev/null)

        if [ -z "$CREDS" ] || [ "$CREDS" = "None" ]; then

            echo "OrganizationAccountAccessRole unavailable."
            echo "Trying AWSControlTowerExecution..."

            CREDS=$(aws sts assume-role \
              --role-arn arn:aws:iam::$ACCOUNT:role/AWSControlTowerExecution \
              --role-session-name config-cleanup \
              --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
              --output text 2>/dev/null)
        fi

        if [ -z "$CREDS" ] || [ "$CREDS" = "None" ]; then
            echo "ERROR: Cannot assume cleanup role in $ACCOUNT"
            continue
        fi

        read AK SK ST <<< "$CREDS"

        export AWS_ACCESS_KEY_ID="$AK"
        export AWS_SECRET_ACCESS_KEY="$SK"
        export AWS_SESSION_TOKEN="$ST"
    fi

    echo "Identity:"
    aws sts get-caller-identity \
      --query '{Account:Account,Arn:Arn}' \
      --output table

    for REGION in $REGIONS; do

        RECORDERS=$(aws configservice describe-configuration-recorders \
          --region "$REGION" \
          --query 'ConfigurationRecorders[].name' \
          --output text 2>/dev/null)

        if [ -z "$RECORDERS" ] || [ "$RECORDERS" = "None" ]; then
            continue
        fi

        echo
        echo "[$ACCOUNT][$REGION]"
        echo "Config recorder(s): $RECORDERS"

        for RECORDER in $RECORDERS; do

            echo "Stopping recorder: $RECORDER"

            aws configservice stop-configuration-recorder \
              --region "$REGION" \
              --configuration-recorder-name "$RECORDER" \
              2>/dev/null

            echo "Deleting recorder: $RECORDER"

            aws configservice delete-configuration-recorder \
              --region "$REGION" \
              --configuration-recorder-name "$RECORDER" \
              2>/dev/null
        done

        CHANNELS=$(aws configservice describe-delivery-channels \
          --region "$REGION" \
          --query 'DeliveryChannels[].name' \
          --output text 2>/dev/null)

        if [ -n "$CHANNELS" ] && [ "$CHANNELS" != "None" ]; then

            for CHANNEL in $CHANNELS; do

                echo "Deleting delivery channel: $CHANNEL"

                aws configservice delete-delivery-channel \
                  --region "$REGION" \
                  --delivery-channel-name "$CHANNEL" \
                  2>/dev/null
            done
        fi

    done
done

echo
echo "=================================================="
echo "CONFIG CLEANUP FINISHED"
echo "=================================================="
