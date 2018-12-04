#! /usr/bin/env bash

set -eu

if [ "$#" -ne 3 ]; then
  script_name=$(basename $0)
  echo "Usage: ${script_name} EXPERIMENT_ID INPUT_FILE num_threads (e.g. ${script_name} experiment_1 input.txt)"
  exit 1
fi


# uncomment to turn on swift/t logging. Can also set TURBINE_LOG,
# TURBINE_DEBUG, and ADLB_DEBUG to 0 to turn off logging
# export TURBINE_LOG=1 TURBINE_DEBUG=1 ADLB_DEBUG=1
export EMEWS_PROJECT_ROOT=$( cd $( dirname $0 )/.. ; /bin/pwd )
# source some utility functions used by EMEWS in this script
source "${EMEWS_PROJECT_ROOT}/etc/emews_utils.sh"

export EXPID=$1
export TURBINE_OUTPUT=$EMEWS_PROJECT_ROOT/experiments/$EXPID
check_directory_exists

# TODO edit the number of processes as required.
export PROCS=4

# TODO edit QUEUE, WALLTIME, PPN, AND TURNBINE_JOBNAME
# as required. Note that QUEUE, WALLTIME, PPN, AND TURNBINE_JOBNAME will
# be ignored if the MACHINE variable (see below) is not set.
export QUEUE=batch
export WALLTIME=00:10:00
export PPN=16
export TURBINE_JOBNAME="${EXPID}_job"

# if R cannot be found, then these will need to be
# uncommented and set correctly.
# export R_HOME=/path/to/R
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$R_HOME/lib
# if python packages can't be found, then uncommited and set this
export PYTHONPATH=$EMEWS_PROJECT_ROOT/python


# TODO edit command line arguments as appropriate
# for your run. Note that the default $* will pass all of this script's
# command line arguments to the swift script.
CMD_LINE_ARGS="$*"
INPUT_FILE=$EMEWS_PROJECT_ROOT/data/$2

mkdir -p $TURBINE_OUTPUT

EXECUTABLE=cancer-immune-EMEWS2
EP=$EMEWS_PROJECT_ROOT/../PhysiCell-src/$EXECUTABLE
EXE=$TURBINE_OUTPUT/$EXECUTABLE
cp  $EP $EXE

DEFAULT_XML=$EMEWS_PROJECT_ROOT/data/PhysiCell_default_settings.xml
CONFIG=$TURBINE_OUTPUT/default_config.xml
cp $DEFAULT_XML $CONFIG

NUM_THREADS=$3

# set machine to your schedule type (e.g. pbs, slurm, cobalt etc.),
# or empty for an immediate non-queued unscheduled run
MACHINE=""

if [ -n "$MACHINE" ]; then
  MACHINE="-m $MACHINE"
fi

# Add any script variables that you want to log as
# part of the experiment meta data to the USER_VARS array,
# for example, USER_VARS=("VAR_1" "VAR_2")
USER_VARS=()
# log variables and script to to TURBINE_OUTPUT directory
log_script

# echo's anything following this standard out
set -x

swift-t -n $PROCS $MACHINE -p $EMEWS_PROJECT_ROOT/swift/swift_run_sweep.swift \
  -f="$INPUT_FILE" -model="$EXE" -config="$CONFIG" -num_threads=$NUM_THREADS $CMD_LINE_ARGS
