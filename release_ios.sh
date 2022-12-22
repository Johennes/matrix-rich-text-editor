#!/usr/bin/env bash

TAG=""

while getopts ":t:" option; do
   case "${option}" in
      t) # Enter a name
          TAG=${OPTARG};;
     \?) # Invalid option
          echo "Error: Invalid option"
          exit;;
   esac
done

BRANCH_NAME=$(git branch --show-current)
echo "branch name: ${BRANCH_NAME}"

if [ "$BRANCH_NAME" == "main" ]; then 
  echo "On main branch."
else 
  echo "Not on main branch. Exiting..."
  exit 1
fi

if [ -z "$(git status --porcelain)" ]; then 
  echo "Working directory is clean."
else 
  echo "Working directory is not clean. Exiting..."
  exit 1
fi

# Complete any prerequisites as defined in /bindings/wysiwyg-ffi/README.md#ios
make ios

BUILD_DIR=build
REPO_PATH="${BUILD_DIR}/matrix-wysiwyg-composer-swift"
WYSIWYG_COMPOSER_PATH="platforms/ios/lib/WysiwygComposer/"
rm -rf $BUILD_DIR
mkdir $BUILD_DIR
git clone https://github.com/matrix-org/matrix-wysiwyg-composer-swift.git $REPO_PATH
git fetch
git checkout main
rsync -a --delete --exclude=".git" $WYSIWYG_COMPOSER_PATH $REPO_PATH
last_commit=$(git rev-parse --short HEAD);
RELEASE_BRANCH="release_$last_commit"
cd $REPO_PATH
git checkout -b $RELEASE_BRANCH
git add .
git commit -m "release $last_commit"
if [ "$TAG" != "" ]; then
  echo "found a tag $TAG"]
  REMOTE_BRANCH_NAME="release_$TAG"
  git tag $TAG
else
  echo "tag not found"
  REMOTE_BRANCH_NAME=${RELEASE_BRANCH}
fi
git push origin $RELEASE_BRANCH:$REMOTE_BRANCH_NAME
# if you have github cli installed this will create the PR automatically
gh pr create -r matrix.org/professional-services-uk -f