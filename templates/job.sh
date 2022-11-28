#!/bin/bash

# A.Mereghetti, 2022-11-28
# this is a template job file

RunFolder=$HOME

# start job
echo " starting job at `date`..."
echo " ...running as $USER ..."
cd ${RunFolder}

# run
for ((ii=1;ii<=1200;ii++)); do
    echo "Hello world! ${ii}"
    sleep 1
done

# end of job
cd - > /dev/null 2>&1
echo " ...ending job at `date`."
