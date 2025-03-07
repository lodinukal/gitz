#!/bin/bash

set -euxo pipefail

harness_path="harness"

if [ -d ./"$harness_path" ]; then
  rm -rf ./"$harness_path"
fi

mkdir -p ./"$harness_path"
pushd ./"$harness_path"

mkdir bare
pushd bare
git init --bare
popd

mkdir empty
pushd empty
git init
git branch -m main
popd

mkdir discover
pushd discover
mkdir -p sub/dir/ect/ory
git init
git branch -m main
popd

mkdir notgit

mkdir corrupted
pushd corrupted
git init
rm -rf .git/HEAD
popd

git clone https://github.com/octocat/Hello-World helloworld
git clone https://github.com/octocat/Hello-World helloworld_detached
pushd helloworld_detached
git checkout 7fd1a60b01f91b314f59955a4e4d4e80d8edf11d
popd

popd
