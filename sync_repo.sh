#! /bin/bash

#================================================================
#  Sync Repo does the following:
#     * Downloads the latest versions of RPMs available from fedora & updates
#     * Also downloads the xml file + uses it to generate internal repo's
#
#   CRON: * * * 01 * /path/to/script/sync_repo.sh >/path/to/script/last_run.log 2>&1
#
#================================================================
# Version: 1.0       29/08/2011       Paul "1" Sanders
#              Basic stuff. I rule,
#              Initial version, 
#              Based off of previous repo work
#================================================================

alias echo='echo -e'

error_check () {
  if [[ "$1" != 0 ]]; then
    echo ">>>WARNING - $2 Failed, return code was $1"
    exit $1
  else
    echo "$2 Complete OK\n"
  fi
}

export MARKER="\n------------------"

#================================================================
echo `date`" $0 started.. "

DATE_STRING="`date +%Y_%m`"
DIRNAME="`pwd`/`dirname $0`"

# Space-delimited list containing '<ID>!<reponame>'
# ID is so that two repo's don't clash with each other
REPOLIST="14 15"

echo "${MARKER}"
echo "Starting Repo Management Phase #1:"
echo "  - Updating FEDORA repo's"
echo "${MARKER}"

for loop1 in ${REPOLIST}; do
  export YUM0="${loop1}"

  # d=delete obsoletes, n=newest RPMs, g=gpgcheck them, m=xml file, p=location
  reposync -c ${DIRNAME}/conf/yum.conf --norepopath -dnmp /server/repo/fedora${loop1}/ --repoid=sync_fedora
  error_check $? "Downloading FEDORA(${loop1}) repo"

  yum -c ${DIRNAME}/conf/yum.conf clean all

  cd /server/repo/fedora${loop1}/
  createrepo -C -g comps.xml .
  error_check $? "Creating repo"

  chmod -R 755 /server/repo/fedora${loop1}
  error_check $? "Setting correct permissions"

done


echo "${MARKER}"
echo "Starting Repo Management Phase #2:"
echo "  - Updating UPDATES repo's"
echo "${MARKER}"

for loop1 in ${REPOLIST}; do
  export YUM0="${loop1}"

  # d=delete obsoletes, n=newest RPMs, g=gpgcheck them, m=xml file, p=location
  reposync -c ${DIRNAME}/conf/yum.conf --norepopath -dnmp /server/repo/fedora${loop1}.updates/ --repoid=sync_updates
  error_check $? "Downloading UPDATES(${loop1}) repo"

  yum -c ${DIRNAME}/conf/yum.conf clean all

  cd /server/repo/fedora${loop1}.updates/
  createrepo -C -g comps.xml .
  error_check $? "Creating repo"

  chmod -R 755 /server/repo/fedora${loop1}.updates
  error_check $? "Setting correct permissions"

done


echo "`date` $0 Complete"
exit 0

