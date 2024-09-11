#!/bin/bash

source testHandling.source

git config --global push.default matching

remoteName=remote
remotePath=${testWorkdirPath}/${remoteName}

# setup a remote
# --------------
echo "INFO :: setup remote"
mkdir -p ${remotePath}
cd ${remotePath}
git init --bare

# create clients
# --------------
echo "INFO :: create client"
clientCreate
client0=$?
echo created client $client0. File counter for the client is ${fileCounters[$client0]}.
clientCreate
client1=$?
echo created client $client1. File counter for the client is ${fileCounters[$client1]}.

# setup client0 cloning remote
# ----------------------------
echo "INFO :: client0 clones remote (empty)"
clientSwitch $client0
git clone -l ${remotePath} $(clientCurrentGetPath)
echo "making initial commit"
filePathCreate src
file0=$?
msg=$(fileCreate $(filePathGet $file0) $(clientCurrentGetName))
echo add and commit
git add $(filePathGet $file0) && git commit -m "$msg"
git push origin master
echo create branch $(clientGetName $client1) on remote
git branch $(clientGetName $client1)
git checkout $(clientGetName $client1)
git push origin $(clientGetName $client1)

# setup client1 cloning remote
# ----------------------------
echo "INFO :: client1 clones remote"
clientSwitch $client1
git clone -l ${remotePath} $(clientCurrentGetPath)
echo "git branch -a"
git branch -a
echo "git branch -vv"
git branch -vv
echo "INFO :: client1 modifies file"
msg=$(fileModify $(filePathGet $file0) $(clientCurrentGetName))
echo add and commit
git add $(filePathGet $file0) && git commit -m "$msg"
git push origin master:client1
