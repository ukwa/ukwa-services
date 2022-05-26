#!/bin/bash

# Pull in production settings:
set -a && . $envfile && set +a

# Get a list of the images:
for img in $(docker-compose config | awk '{if ($1 == "image:") print $2;}'); do
  # Unique image names only...
  if [[ ! "$images" == *"$img"* ]]; then
    images="$images $img"
  fi
done

# Save the images in a composite file (loadable using 'docker load < services.img')
echo Saving $images
docker save -o services.img $images
