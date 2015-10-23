#/bin/bash

BUCKET=mini-project-$(date | md5)

aws s3 mb s3://$BUCKET
aws s3 cp ../index.html s3://$BUCKET/ --acl public-read
aws s3 website s3://$BUCKET --index-document index.html

open "http://${BUCKET}.s3-website-us-east-1.amazonaws.com/"
