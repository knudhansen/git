#!/bin/bash

testPwd=$(pwd)
testName=test_1

remoteName=remote
export clientCounter=0
export currentClientNumber=0
export testWorkdirPath=${testPwd}/${testName}_workdir
declare -a fileCounters
export fileCounter=0

function createClient {
    clientNumber=$clientCounter
    export clientCounter=$((clientCounter+1))
    fileCounters+=( 0 )
    return $clientNumber
}
function getClientName {
    clientNumber=$1
    echo client${clientNumber}
}
function getClientPath {
    clientNumber=$1
    echo ${testWorkdirPath}/$(getClientName $clientNumber)
}
function getCurrentClientName {
    echo $(getClientName ${currentClientNumber})
}
function getCurrentClientPath {
    echo $(getClientPath ${currentClientNumber})
}

echo starting test $0 from ${testPwd}

rm -rf ${testWorkdirPath}
mkdir ${testWorkdirPath}

remotePath=${testWorkdirPath}/${remoteName}

# setup a remote
mkdir -p ${remotePath}
cd ${remotePath}
git init --bare

# setup a client cloning remote
createClient
currentClientNumber=$?
echo created client $currentClientNumber. File counter for the client is ${fileCounters[$currentClientNumber]}.
mkdir -p $(getCurrentClientPath)
cd $(getCurrentClientPath)
git clone -l ${remotePath} $(getCurrentClientPath)

# create a file and add it to git
filePrefix=file
fileDir=src
mkdir -p ${fileDir}
fileName=${fileDir}/${filePrefix}.txt
echo file created by $(getCurrentClientName) at $(date) > ${fileName}
git add $fileName && git commit -m "adding $fileName"
git push

# setup another client cloning remote
createClient
currentClientNumber=$?
echo created client $currentClientNumber. File counter for the client is ${fileCounters[$currentClientNumber]}.
mkdir -p $(getCurrentClientPath)
cd $(getCurrentClientPath)
git clone -l ${remotePath} $(getCurrentClientPath)

# verify that client0 and client1 are identical
if [ "$(diff -r $(getClientPath 0)/${fileDir} $(getClientPath 1)/${fileDir})" != "0"  ]; then
    exit 1
fi

# modify the file created by the first client

cd ${testPwd}
###rm -rf test1_workdir
