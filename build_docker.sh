#!/usr/bin/env bash
set -e
AWS_PROFILE=egdp-dev
AWS_REGION=${AWS_DEFAULT_REGION:-us-east-1}
AWS_ACCOUNT=`aws sts get-caller-identity|jq -r .Account`
IMAGE="apiary-metastore"

docker build -t ${IMAGE} .
$(aws ecr get-login --region ${AWS_REGION} --no-include-email)
docker tag ${IMAGE}:latest ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE}:latest
docker push ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE}:latest
AKTAGVER=1.1.1.8
docker tag ${IMAGE}:latest ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE}:${AKTAGVER}
docker push ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE}:${AKTAGVER}