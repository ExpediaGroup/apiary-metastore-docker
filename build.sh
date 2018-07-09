#!/bin/sh
#export AWS_PROFILE=test
export AWS_ACCOUNT=`aws sts get-caller-identity|jq -r .Account`
export IMAGE="apiary-metastore"

docker build -t ${IMAGE} .
$(aws ecr get-login --region us-west-2)
docker tag ${IMAGE}:latest ${AWS_ACCOUNT}.dkr.ecr.us-west-2.amazonaws.com/${IMAGE}:latest
docker push ${AWS_ACCOUNT}.dkr.ecr.us-west-2.amazonaws.com/${IMAGE}:latest
