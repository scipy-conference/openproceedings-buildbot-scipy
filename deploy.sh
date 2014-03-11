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

echo -e "Starting to deploy to Github Pages\n"
COMMIT_MESSAGE="Travis build $TRAVIS_BUILD_NUMBER"
if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    git config --global user.email "scipy-proceedings-bot@andreazonca.com"
    git config --global user.name "scipy-proceedings-bot"
    #using token clone gh-pages branch
    git clone --quiet --branch=$BRANCH https://${GH_TOKEN}@github.com/$TARGET_REPO.git built_website &> /dev/null
    #go into directory and copy data we're interested in to that directory
    mkdir -p built_website/$TARGET_FOLDER
    cd built_website/$TARGET_FOLDER
    rsync -rv --exclude=.git  $TRAVIS_BUILD_DIR/../buildbot/$PELICAN_OUTPUT_FOLDER/* .
else
    git config --global user.email "scipy-proceedings-bot-unsecure@andreazonca.com"
    git config --global user.name "scipy-proceedings-bot-unsecure"
    cd $TRAVIS_BUILD_DIR
    # assumes each PR is about a single paper, and a single paper has only 1 rst or md file
    CHANGED_PAPER=`git diff --name-only $TRAVIS_COMMIT^1 $TRAVIS_COMMIT | egrep 'rst|md'`
    TARGET_REPO="$GITHUB_ORGANIZATION/proc_pdf_drafts_2014"

    git clone --quiet --branch=$BRANCH https://c935f10c2fff248013e6527d9e7fb29f7f628df8@github.com/$TARGET_REPO.git built_website 
    cd $TRAVIS_BUILD_DIR/built_website/
    cp $TRAVIS_BUILD_DIR/../buildbot/$PELICAN_OUTPUT_FOLDER/pdf/*${CHANGED_PAPER%%.*}*pdf .
    COMMIT_MESSAGE="$COMMIT_MESSAGE, pull request $TRAVIS_PULL_REQUEST, paper $CHANGED_PAPER"
fi

#add, commit and push files
git add -f .
git commit -m "$COMMIT_MESSAGE" -m "Commit $TRAVIS_REPO_SLUG/$TRAVIS_COMMIT"
git push -fq origin $BRANCH &> /dev/null
echo -e "Deploy completed\n"
