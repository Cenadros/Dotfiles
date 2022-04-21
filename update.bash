#!/bin/bash

git pull origin main
. symlinks.bash

pushd ${HOME}/.zprezto
git pull && git submodule update --init --recursive
popd
