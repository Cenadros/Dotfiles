#!/bin/bash

git pull origin main
. symlinks.bash

pushd ${HOME}/.zprezto
git pull && git submodule update --init --recursive
popd

pushd ${HOME}/.nvm
git fetch --tags origin && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
popd
