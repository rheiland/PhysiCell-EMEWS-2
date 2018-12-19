#! /usr/bin/env bash

set -eu

if [ "$#" -ne 4 ]; then
  script_name=$(basename $0)
  echo "Usage: ${script_name} EXPERIMENT_ID INPUT_PARAMS INIT_POP NUM_THREADS"
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
# check_directory_exists

# TODO edit the number of processes as required.
export PROCS=6

# TODO edit QUEUE, WALLTIME, PPN, AND TURNBINE_JOBNAME
# as required. Note that QUEUE, WALLTIME, PPN, AND TURNBINE_JOBNAME will
# be ignored if MACHINE flag (see below) is not set
export QUEUE=batch
export WALLTIME=00:10:00
export PPN=16
export TURBINE_JOBNAME="${EXPID}_job"

# if R cannot be found, then these will need to be
# uncommented and set correctly.
# export R_HOME=/path/to/R
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$R_HOME/lib
# export PYTHONHOME=/path/to/python
export PYTHONPATH=$EMEWS_PROJECT_ROOT/python:$EMEWS_PROJECT_ROOT/ext/EQ-Py

# Resident task workers and ranks
export TURBINE_RESIDENT_WORK_WORKERS=1
export RESIDENT_WORK_RANKS=$(( PROCS - 2 ))

# EQ/Py location
EQPY=$EMEWS_PROJECT_ROOT/ext/EQ-Py

# TODO edit command line arguments, e.g. -nv etc., as appropriate
# for your EQ/Py based run. $* will pass all of this script's
# command line arguments to the swift script
SEED=1234
ITERS=1
NUM_VARIATIONS=1
NUM_POP=3

TISD=0.25

STRATEGY="mu_plus_lambda"
#STRATEGY="simple"
# original was 0.2
MUTATION_PROB=0.2

mkdir -p $TURBINE_OUTPUT

GA_PARAMS_FILE=$2
PARAMS_FILE=$TURBINE_OUTPUT/ga_params.json
cp $GA_PARAMS_FILE $PARAMS_FILE

INIT_POP=$3
INITIAL_POPULATION=$TURBINE_OUTPUT/init_pop.csv
cp $INIT_POP $INITIAL_POPULATION


EXECUTABLE=cancer-immune-EMEWS2
EP=$EMEWS_PROJECT_ROOT/../PhysiCell-src/$EXECUTABLE
EXE=$TURBINE_OUTPUT/$EXECUTABLE
cp $EP $EXE

DEFAULT_XML=$EMEWS_PROJECT_ROOT/data/PhysiCell_default_settings.xml
CONFIG=$TURBINE_OUTPUT/default_config.xml
cp $DEFAULT_XML $CONFIG

NUM_THREADS=$4

# Uncomment this for the BG/Q:
#export MODE=BGQ QUEUE=default

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

# echo's anything following this to standard out
#-init_population=$INITIAL_POPULATION \ 
set -x
SWIFT_FILE=ga_workflow.swift
swift-t -n $PROCS $MACHINE -p  -I $EQPY -r $EQPY \
    $EMEWS_PROJECT_ROOT/swift/$SWIFT_FILE \
    -ni=$ITERS \
    -nv=$NUM_VARIATIONS \
    -np=$NUM_POP \
    -seed=$SEED \
    -strategy=$STRATEGY \
    -ga_params=$PARAMS_FILE \
    -init_population=$INITIAL_POPULATION \
    -mutation_prob=$MUTATION_PROB \
    -model="$EXE" \
    -config="$CONFIG" \
    -num_threads=$NUM_THREADS \
    -tisd=$TISD
