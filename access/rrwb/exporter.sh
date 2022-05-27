#!/bin/bash

envfile=$1

echo Reading env from $envfile ...

# Pull in production settings:
set -a && . $envfile && set +a

# Get a list of the images:
echo Scanning and pulling images... 
for img in $(docker-compose config | awk '{if ($1 == "image:") print $2;}'); do
  # Unique image names only...
  if [[ ! "$images" == *"$img"* ]]; then
    images="$images $img"
    # Pull it in case this host hasn't already pulled it:
    docker pull $img
  fi
done

# Save the images in a composite file (loadable using 'docker load < services.tar')
echo Saving $images ...
docker save -o services.tar $images
