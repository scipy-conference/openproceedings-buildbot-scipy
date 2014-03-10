#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
BRANCH=master
TRAVIS_REPO_SLUG_ARRAY=(${TRAVIS_REPO_SLUG//\// })
GITHUB_ORGANIZATION=${TRAVIS_REPO_SLUG_ARRAY[0]}
TARGET_REPO=$GITHUB_ORGANIZATION/$GITHUB_ORGANIZATION.github.io
# if target folder is not a single folder, change the rsync command
TARGET_FOLDER=$1
PELICAN_OUTPUT_FOLDER=output

if [ "$TRAVIS" == "true" ]; then
    git config --global user.email "scipy-proceedings-bot@andreazonca.com"
    git config --global user.name "scipy-proceedings-bot"
fi
echo -e "Starting to deploy to Github Pages\n"
COMMIT_MESSAGE="Travis build $TRAVIS_BUILD_NUMBER"
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    TARGET_FOLDER=$TARGET_FOLDER/submission/$TRAVIS_PULL_REQUEST
    COMMIT_MESSAGE="$COMMIT_MESSAGE, pull request $TRAVIS_PULL_REQUEST"
fi

#using token clone gh-pages branch
git clone --quiet --branch=$BRANCH https://${GH_TOKEN}@github.com/$TARGET_REPO.git built_website &> /dev/null
#go into directory and copy data we're interested in to that directory
mkdir -p built_website/$TARGET_FOLDER
cd built_website/$TARGET_FOLDER
rsync -rv --exclude=.git  $TRAVIS_BUILD_DIR/../buildbot/$PELICAN_OUTPUT_FOLDER/* .
#add, commit and push files
git add -f .
git commit -m "$COMMIT_MESSAGE"
git push -fq origin $BRANCH &> /dev/null
echo -e "Deploy completed\n"
