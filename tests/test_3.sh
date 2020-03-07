#!/bin/bash

source testHandling.source

git config push.default matching

remoteName=remote
remotePath=${testWorkdirPath}/${remoteName}

# setup a remote
# --------------
echo "INFO :: setup remote"
mkdir -p ${remotePath}
cd ${remotePath}
git init --bare

# create client
# -------------
echo "INFO :: create client"
clientCreate
client0=$?
echo created client $client0. File counter for the client is ${fileCounters[$client0]}.

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
msg=$(fileCreate $(filePathGet $file0) $(clientCurrentGetName))
echo add and commit
git add $(filePathGet $file0) && git commit -m "$msg"
echo "INFO :: client0 pushes"
git push origin master

# create a branch and update file0 in the branch
# ----------------------------------------------
echo create branch
git branch $(clientCurrentGetName)
git checkout $(clientCurrentGetName)
msg=$(fileModify $(filePathGet $file0) $(clientCurrentGetName))
echo add and commit
git add $(filePathGet $file0) && git commit -m "$msg"
echo "INFO :: client 0 pushes"
git push origin client0
msg=$(fileModify $(filePathGet $file0) $(clientCurrentGetName))
echo add and commit
git add $(filePathGet $file0) && git commit -m "$msg"
#git push origin client0
# add a new file on master
git checkout master
filePathCreate src
file1=$?
msg=$(fileCreate $(filePathGet $file1) $(clientCurrentGetName))
git add $(filePathGet $file1) && git commit -m "$msg"
echo "INFO :: client 0 pushes"
git push

# cd back to test dir
cd ${testPwd}
###rm -rf test1_workdir
