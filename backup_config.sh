#!/bin/vbash

function usage() {
  echo "USAGE: $0 [-p]"
  echo "-p: push after commit"
  exit
}

PUSH=0
while getopts ph OPT; do
  case $OPT in
    "p" ) PUSH=1 ;;
    "b" ) BRANCHSTYLE=1 ;;
    "h" ) usage ;;
  esac
done

#source /opt/vyatta/etc/functions/script-template

#Environment
SCRIPTPATH=$(readlink -f $0)
SCRIPTDIR=$(cd $(dirname $SCRIPTPATH); pwd)
SRCDIR=/config

source $SCRIPTDIR/config
REPOSITORYDIR=${REPOSITORYDIR:-/config/.backup}
HOSTNAME=${HOSTNAME:-`hostname`}
GIT_USERNAME=${GIT_USERNAME:-vyos}
GIT_USEREMAIL=${GIT_USEREMAIL:-vyos@example.com}
STORE_STYLE=${STORE_STYLE:-DIR}
BRANCH_NAME=${BRANCH_NAME:-master}

now=`date "+%Y/%m/%d %H:%M:%S"`
GITOPT="-c user.name='$GIT_USERNAME' -c user.email='GIT_USEREMAIL'"

#Backup Git
mkdir -p $REPOSITORYDIR
cd $REPOSITORYDIR

if ! git rev-parse --git-dir; then
  git init
  git $GITOPT commit --allow-empty -m "initial blank commit"
fi


if [ "$STORE_STYLE" == "BRANCH" ]; then
  if git show-ref --quiet refs/remotes/origin/$HOSTNAME; then
    git checkout $HOSTNAME
  else
    git checkout -B $HOSTNAME
  fi

  rsync -a --delete --exclude=$REPOSITORYDIR --exclude=$SCRIPTDIR --exclude=archive/ --exclude=vyos-migrate.log $SRCDIR $REPOSITORYDIR/

  git add .
  git $GITOPT commit -m "$HOSTNAME backup config $now"
  
  if [ $PUSH -eq 1 ]; then
    git push -u origin $HOSTNAME
  fi
else
  if [ ! -d "$HOSTNAME" ]; then
    mkdir "$HOSTNAME"
  fi
  git checkout master
  rsync -a --delete --exclude=$REPOSITORYDIR --exclude=$SCRIPTDIR --exclude=archive/ --exclude=vyos-migrate.log $SRCDIR $REPOSITORYDIR/$HOSTNAME/

  git add .
  git $GITOPT commit -m "$HOSTNAME backup config $now"

  if [ $PUSH -eq 1 ]; then
    git push -u origin master
  fi
fi


echo "Backup completed"
