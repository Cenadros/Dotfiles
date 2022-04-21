#!/bin/bash
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${HOME}/.zprezto"
git clone --recurse-submodules https://github.com/belak/prezto-contrib "${HOME}/.zprezto/contrib"

bash symlinks.bash
