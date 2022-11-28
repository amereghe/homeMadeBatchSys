#!/bin/bash

# A.Mereghetti, 2021-02-09
# a very simple queueing system
# all job files should be named job_*.sh
# the script takes as input argument the number of CPUs allocated
#    for running jobs. If this is not provided, the script finds
#    the number of CPUs/cores available on the machine and subtracts
#    one.

function myExit(){
    echo " ...final balance:"
    echo "    nSubmitted: ${nSubmitted}"
    echo "    nCleaned: ${nCleaned}"
    echo " ...ending at `date`."
    exit $1
}

nSubmitted=0
nCleaned=0
lDebug=false
lRoot=false
if [ "$USER" == "root" ] ; then
    lRoot=true
fi
if [ $# -ge 1 ] ; then
    nCPUs=$1
else
    # a default number
    nCPUs=`grep -Pc '^processor\t' /proc/cpuinfo`
    let nCPUs=${nCPUs}-1
fi
echo ""
echo " starting $0 at `date` run as $USER - allocated CPUs: ${nCPUs} ..."

if [ -e stop.submit ] ; then
    echo " ...stop.submit found! exiting istantly..."
    myExit 0
fi

echo " getting running jobs..."
runningJobs=`ps aux | grep job_ | grep -v grep`
if [ -n "${runningJobs}" ] ; then
    nProcesses=`echo "${runningJobs}" | wc -l`
    if ${lDebug} ; then
        echo " ...jobs already running:"
        echo "${runningJobs}"
    fi
    echo " ...total number of running processes: ${nProcesses};"
else
    nProcesses=0
    echo " ...no running jobs!"
fi

echo " getting finished jobs..."
currJobs=`ls -1 job_*.sh 2>/dev/null`
if [ -n "${currJobs}" ] ; then
    currJobs=( ${currJobs} )
    for tmpJob in ${currJobs[@]} ; do
        if [ -z "`ps aux | grep ${tmpJob} | grep -v grep`" ] ; then
            ! ${lDebug} || echo " ...job ${tmpJob} is finished!"
            mv ${tmpJob} ${tmpJob}.log finished/
            let nCleaned=${nCleaned}+1
        fi
    done
fi
if [ ${nCleaned} -eq 0 ] ; then
    echo " ...no finished job!"
else
    echo " ...total number of finished (and cleaned) jobs: ${nCleaned}"
fi

echo " getting waiting jobs..."
waitingJobs=`ls -1tr queueing/job_*.sh 2>/dev/null`
if [ -z "${waitingJobs}" ] ; then
    echo " ...no waiting jobs: exiting!"
    myExit 0
else
    waitingJobs=( ${waitingJobs} )
    if ${lDebug} ; then
        echo " ...waiting jobs:"
        for tmpJob in ${waitingJobs[@]} ; do
            echo " `basename ${tmpJob}`"
        done
    fi
    echo " ...total number of waiting jobs: ${#waitingJobs[@]};"
fi

echo " getting how many jobs I can submit..." 
let nSubmit=${nCPUs}-${nProcesses}
if [ ${nSubmit} -gt 0 ] ; then
    [ ${nSubmit} -le ${#waitingJobs[@]} ] || nSubmit=${#waitingJobs[@]}
    echo " ...submitting ${nSubmit} jobs!"
    for (( jj=0; jj<${nSubmit}; jj++ )) ; do
        tmpFile=${waitingJobs[$jj]}
        tmpFileName=`basename ${tmpFile}`
        ! ${lDebug} || echo " ...submitting `basename ${tmpFileName}`..."
        if ${lRoot} ; then
            # root submitting:
            jobOwner=`stat -c "%U" ${tmpFile}`
            mv ${tmpFile} .
            # run the job as the user owning the job file
            sudo -H -u ${jobOwner} bash -c "./${tmpFileName} 2>&1 > ${tmpFileName}.log" &
        else
            mv ${tmpFile} .
            ./${tmpFileName} 2>&1 > ${tmpFileName}.log &
        fi
        let nSubmitted=${nSubmitted}+1
    done
else
    echo " ...no job can be submitted: ${nProcesses} processes and ${nCPUs} CPU(s)."
fi

# good bye
myExit 0
