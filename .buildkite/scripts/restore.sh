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
    SANITIZED_NAME="${NAME//./-}"
    FILEPATH=$(echo "$project" | jq -r '.FilePath')
    PROJECT_DIR=$(dirname "$FILEPATH")
    
    cat <<EOF >> dynamic-steps.yml
    - label: ":dotnet: Restore $NAME"
      key: "restore-$SANITIZED_NAME"
      command: |
        dotnet restore "$FILEPATH" --packages ".nuget/packages"
      plugins:
        - docker:
            image: mcr.microsoft.com/dotnet/sdk:9.0
        - artifacts:
            compressed: ".nuget/packages.tgz"
            upload: ".nuget/packages"
        - artifacts:
            upload: "**/obj/*"
    
    - label: ":dotnet: Build $NAME"
      depends_on: "restore-$SANITIZED_NAME"
      command: |
        dotnet build --configuration Release --no-restore "$FILEPATH"
      plugins:
        - artifacts:
            download: "**/obj/*"
        - artifacts:
            download: ".nuget/packages"
            compressed: ".nuget/packages.tgz"
        - docker:
            image: mcr.microsoft.com/dotnet/sdk:9.0
        
EOF
  done
  cat dynamic-steps.yml
  
  #Upload the dynamic steps to Buildkite
  #buildkite-agent pipeline upload dynamic-steps.yml
else
  echo "No projects to restore."
fi
