#!/bin/bash
set -e

if [ -z $DOCKERHUB_ACCOUNT ]; then
  echo 'Must set $DOCKERHUB_ACCOUNT'
  exit 1
fi

UUID=$(uuidgen)
NAME=buildkit-merge-test
IMAGE=$DOCKERHUB_ACCOUNT/$NAME:$UUID

echo "Clearing build cache"
docker buildx prune -a -f >> /dev/null

echo "Will push images to $IMAGE"

echo ""
echo "--------------------------------------------------------------------"
echo ""

echo "Writing 'foo' -> foo.txt and 'bar' -> bar.txt"

rm -f foo.txt bar.txt
echo "foo" >> foo.txt
echo "bar" >> bar.txt

echo "Building, pushing to $IMAGE"
docker buildx build \
  --cache-to=type=inline \
  --tag=$IMAGE \
  --push \
  .

echo ""
echo "--------------------------------------------------------------------"
echo ""

rm -f foo.txt bar.txt
echo "Writing 'foo' -> foo.txt and 'baz' -> bar.txt"
echo "foo" >> foo.txt
echo "baz" >> bar.txt

echo "Building with cache from $IMAGE -- notice that foo.txt is [CACHED]"
docker buildx build \
  --cache-from=$IMAGE \
  .

echo ""
echo "--------------------------------------------------------------------"
echo ""

rm -f foo.txt bar.txt
echo "Writing 'baz' -> foo.txt and 'bar' -> bar.txt"
echo "baz" >> foo.txt
echo "bar" >> bar.txt

echo "Building with cache from $IMAGE -- notice that bar.txt is not [CACHED]"
docker buildx build \
  --cache-from=$IMAGE \
  .
