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
echo "INFO :: create clients"
clientCreate
client0=$?

# setup client0 cloning remote
# ----------------------------
echo "INFO :: client0 clones remote (empty)"
clientSwitch $client0
git clone -l ${remotePath} $(clientCurrentGetPath)

# create a file and add it to git
# -------------------------------
echo "INFO :: client0 adds a new file"
filePathCreate src
file0=$?
# changes on master branch
msg=$(fileCreate $(filePathGet $file0) $(clientCurrentGetName))
git add $(filePathGet $file0) && git commit -m "$msg"
git branch $(clientCurrentGetName)
msg=$(fileModify $(filePathGet $file0) $(clientCurrentGetName))
git add $(filePathGet $file0) && git commit -m "$msg"
msg=$(fileModify $(filePathGet $file0) $(clientCurrentGetName))
git add $(filePathGet $file0) && git commit -m "$msg"
# changes on client0 branch
git checkout $(clientCurrentGetName)
msg=$(fileModify $(filePathGet $file0) $(clientCurrentGetName))
git add $(filePathGet $file0) && git commit -m "$msg"
echo "INFO :: client0 pushes"
git push origin master
