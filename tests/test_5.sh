#!/bin/bash

source testHandling.source

git config push.default matching

mainRepoRemoteName=main_repo_remote
submodule0RemoteName=submodule_0_remote
submodule1RemoteName=submodule_1_remote

function getRemoteUrl {
    local name=$1
    
    echo ${testWorkdirPath}/${name}
}

# setup remotes
# -------------
echo "INFO :: setup remotes"
for repoName in $mainRepoRemoteName $submodule0RemoteName $submodule1RemoteName; do
    repoPath=$(getRemoteUrl $repoName)
    echo "INFO :: setting remote $repoPath"
    mkdir -p ${repoPath}
    cd ${repoPath}
    git init --bare
done

# create client
# -------------
echo "INFO :: create client"
clientCreate
client0=$?
echo created client $client0. File counter for the client is ${fileCounters[$client0]}.
clientCreate
client1=$?
echo created client $client1. File counter for the client is ${fileCounters[$client1]}.
clientCreate
client2=$?
echo created client $client2. File counter for the client is ${fileCounters[$client2]}.

# setup client0 cloning remote
# ----------------------------
echo "INFO :: client0 clones remote (empty)"
clientSwitch $client0
git clone -l $(getRemoteUrl ${mainRepoRemoteName}) $(clientCurrentGetPath)
filePathCreate src
file0=$?
msg=$(fileCreate $(filePathGet $file0) $(clientCurrentGetName))
echo add and commit
git add $(filePathGet $file0) && git commit -m "$msg"
echo "INFO :: client0 pushes"
git push origin master

# setup client1 cloning submodule0 remote
# ---------------------------------------
echo "INFO :: client1 clones submodule remote (empty)"
clientSwitch $client1
git clone -l $(getRemoteUrl ${submodule0RemoteName}) $(clientCurrentGetPath)
filePathCreate src
file1=$?
msg=$(fileCreate $(filePathGet $file1) $(clientCurrentGetName))
echo add and commit
git add $(filePathGet $file1) && git commit -m "$msg"
echo "INFO :: client1 pushes"
git push origin master

# add submodule 0 to the repo
# ---------------------------
echo "INFO :: client0 adds a submodule"
clientSwitch $client0
git submodule add $(getRemoteUrl ${submodule0RemoteName}) ./sm/sm0
git commit -m "adding submodule 0" && git push origin master
filePathCreate src
file2=$?
cd sm/sm0
  msg=$(fileCreate $(filePathGet $file2) $(clientCurrentGetName))
  git add $(filePathGet $file2)
  git commit -m "$msg"
  git push origin master
cd -
git add sm/sm0
git commit -m "updating submodule $msg"
git push origin master

# setup client2 cloning remote
# ----------------------------
echo "INFO :: client2 clones remote"
clientSwitch $client2
git clone -l $(getRemoteUrl ${mainRepoRemoteName}) $(clientCurrentGetPath)
git submodule update --init
cd sm/sm0
  git checkout master # need to checkout the master branch of sm before updating it
  msg=$(fileModify $(filePathGet $file2) $(clientCurrentGetName))
  git add $(filePathGet $file2)
  git commit -m "$msg"
  git push origin master
cd -

# switch back to client 0 and update submodule
# --------------------------------------------
echo "INFO :: client 0 gets submodule updated"
clientSwitch $client0
(cd sm/sm0 && git pull)
git add sm/sm0
git commit -m "updating submodule"
git push origin master
