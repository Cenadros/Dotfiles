#!/bin/bash
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${HOME}/.zprezto"
git clone --recurse-submodules https://github.com/belak/prezto-contrib "${HOME}/.zprezto/contrib"
git clone https://github.com/nvm-sh/nvm.git "${HOME}/.nvm"
pushd ${HOME}/.nvm
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
popd

bash symlinks.bash
