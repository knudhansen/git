#!/bin/bash

testPwd=$(pwd)
testName=test_1

remoteName=remote
export testWorkdirPath=${testPwd}/${testName}_workdir
declare -a fileCounters

#client variables
export clientCounter=0
export currentClientNumber=0
# client functions
function clientGetName {
    clientNumber=$1
    echo client${clientNumber}
}
function clientGetPath {
    clientNumber=$1
    echo ${testWorkdirPath}/$(clientGetName $clientNumber)
}
function clientCurrentGetName {
    echo $(clientGetName ${currentClientNumber})
}
function clientCurrentGetPath {
    echo $(clientGetPath ${currentClientNumber})
}
function clientCreate {
    clientNumber=$clientCounter
    echo "DEBUG :: clientCounter before: $clientCounter" >&2
    export clientCounter=$((clientCounter+1))
    echo "DEBUG :: clientCounter after: $clientCounter" >&2
    fileCounters+=( 0 )
    mkdir -p $(clientGetPath $clientNumber) 
    return $clientNumber
}
function clientSwitch {
    currentClientNumber=$1
    cd $(clientCurrentGetPath)
}
function clientFileDiff {
    relativeFilePath=$1
    clientNumberA=$2
    clientNumberB=$3
    absoluteFilePathClientA="$(clientGetPath $clientNumberA)/$relativeFilePath"
    absoluteFilePathClientB="$(clientGetPath $clientNumberB)/$relativeFilePath"
    diff -r $absoluteFilePathClientA $absoluteFilePathClientB
    return $?
}

# filePath variables
declare -a filePathList
# filePath functions
function filePathGet {
    fileNumber=$1
    echo ${filePathList[$fileNumber]}
}
function filePathCreate {
    fileDir=${1:-'.'}
    fileNumber=${#fileList[@]}
    filePath=${fileDir}/file${fileNumber}.txt
    filePathList+=( $filePath )
    return $FileNumber
}


function fileCreate {
    filePath=$1
    author=$(clientCurrentGetName)
    echo "$author creates file $filePath" >&2
    # verify that the file does not already exist
    if test -f $filePath; then
	echo "ERROR >> trying to create file $filePath which already exists. fileCreate was aborted." >&2
	return 0
    fi
    # create dir and file
    mkdir -p $(dirname $filePath)
    echo file created by ${author} at $(date) | tee ${filePath}
}
function fileModify {
    filePath=$1
    editor=$(clientCurrentGetName)
    # verify that the file exists
    if test -f filePath; then
	echo "ERROR >> trying to modify file $filePath which does not exists. fileModify was aborted." >&2
	return 0
    fi
    echo file modified by ${editor} at $(date) | tee -a ${filePath}
}

echo "INFO :: starting test $0 from ${testPwd}"

git config --global push.default matching

rm -rf ${testWorkdirPath}
mkdir ${testWorkdirPath}

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
msg=$(fileCreate $(filePathGet $file0))
echo add and commit
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
msg=$(fileModify $(filePathGet $file0))
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
