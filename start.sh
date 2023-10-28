#!/bin/bash

echo "Before export:"

export YC_TOKEN=$(yc iam create-token)
echo "YC_TOKEN: $YC_TOKEN"

export YC_CLOUD_ID=$(yc config get cloud-id)
echo "YC_CLOUD_ID: $YC_CLOUD_ID"

export YC_FOLDER_ID=$(yc config get folder-id)
echo "YC_FOLDER_ID: $YC_FOLDER_ID"

echo "After export:"
