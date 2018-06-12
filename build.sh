#!/bin/sh
export PATH=$PATH:/opt/anaconda/bin
#export AWS_PROFILE=test
export AWS_ACCOUNT=`aws sts get-caller-identity|jq -r .Account`
export IMAGE="apiary-metastore"
export VERSION="0.1.3"

docker build -t ${IMAGE} .
$(aws ecr get-login --region us-west-2)
docker tag ${IMAGE}:latest ${AWS_ACCOUNT}.dkr.ecr.us-west-2.amazonaws.com/${IMAGE}:latest
docker push ${AWS_ACCOUNT}.dkr.ecr.us-west-2.amazonaws.com/${IMAGE}:latest
docker tag ${IMAGE}:latest ${AWS_ACCOUNT}.dkr.ecr.us-west-2.amazonaws.com/${IMAGE}:${VERSION}
docker push ${AWS_ACCOUNT}.dkr.ecr.us-west-2.amazonaws.com/${IMAGE}:${VERSION}
