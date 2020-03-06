#!/bin/bash

testPwd=$(pwd)
a=$(basename -- $0)
testName=${a%.*}

remoteName=remote
export testWorkdirPath=${testPwd}/${testName}_workdir
declare -a fileCounters

source clientHandling.source
source filePathHandling.source

source fileHandling.source

echo "INFO :: starting test ${testName} from ${testPwd}"

git config push.default matching

rm -rf ${testWorkdirPath}
mkdir -p ${testWorkdirPath}

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
echo created client $client0. File counter for the client is ${fileCounters[$client0]}.
clientCreate
client1=$?
echo created client $client1. File counter for the client is ${fileCounters[$client1]}.

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
git add $(filePathGet $file0) && git commit -m "$msg"
echo "INFO :: client0 pushes"
git push origin master

# setup client1 cloning remote
# ----------------------------
echo "INFO :: client1 clones remote"
clientSwitch $client1
git clone -l ${remotePath} $(clientCurrentGetPath)
# verify that client0 and client1 are identical
clientFileDiff ${fileDir} $client0 $client1
if [ "$?" != "0"  ]; then
    echo "Error: Differences after cloning! Exitting"
    exit 1
fi

# modify the file created by the first client
# -------------------------------------------
echo "INFO :: client1 modifies the file"
msg=$(fileModify $(filePathGet $file0) $(clientCurrentGetName))
git add $(filePathGet $file0) && git commit -m "$msg"
echo "INFO :: client1 pushes"
git push
# verify that client0 and client1 are not identical anymore
clientFileDiff ${fileDir} $client0 $client1
if [ "$?" == "0"  ]; then
    echo exiting
    exit 1
fi

# change back to client0 and pull the changes from client1
# --------------------------------------------------------
echo "INFO :: client0 pulls"
clientSwitch $client0
git pull
#verify that client0 and client1 are identical again
clientFileDiff ${fileDir} $client0 $client1
if [ "$?" != "0"  ]; then
    echo "Error: Differences after pulling! Exitting"
    exit 1
fi

# cd back to test dir
cd ${testPwd}
###rm -rf test1_workdir
