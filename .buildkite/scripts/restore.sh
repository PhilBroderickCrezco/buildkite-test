#!/bin/bash

set -eu

# Create restore step for each affected project
if [ "$(cat has-affected-projects.txt)" = "true" ]; then
  echo "Generating dynamic restore steps..."
  #buildkite-agent artifact download affected-projects.json .
  
  # Generate dynamic steps
  cat <<EOF > dynamic-steps.yml
  steps:
EOF

  jq -c '.[]' affected-projects.json | while read -r project; do
    NAME=$(echo "$project" | jq -r '.Name')
    FILEPATH=$(echo "$project" | jq -r '.FilePath')
    
    cat <<EOF >> dynamic-steps.yml
    - label: ":package: Restore $NAME"
      key: "restore-$NAME"
      command: |
        dotnet restore "$FILEPATH" --packages ".nuget/${NAME}/packages"
      plugins:
        - docker:
            image: mcr.microsoft.com/dotnet/sdk:9.0
    - label: ":package: Build $NAME"
      depends_on: "restore-$NAME"
      command: |
        dotnet build --configuration Release --no-restore  "$FILEPATH"
      plugins:
        - docker:
            image: mcr.microsoft.com/dotnet/sdk:9.0
EOF
  done
  cat dynamic-steps.yml
  
  #Upload the dynamic steps to Buildkite
  buildkite-agent pipeline upload dynamic-steps.yml
else
  echo "No projects to restore."
fi
