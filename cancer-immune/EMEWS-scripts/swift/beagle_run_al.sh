#! /usr/bin/env bash

set -eu

export PROJECT=CI-CCR000040

if [ "$#" -ne 2 ]; then
  script_name=$(basename $0)
  echo "Usage: ${script_name} EXPERIMENT_ID  num_threads (e.g. ${script_name} experiment_1 4)"
  exit 1
fi


SWIFT_T=/lustre/beagle2/ncollier/sfw/swift-t-12042018
PATH=$SWIFT_T/stc/bin:$PATH

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
# 1040
export PROCS=1008

# TODO edit QUEUE, WALLTIME, PPN, AND TURNBINE_JOBNAME
# as required. Note that QUEUE, WALLTIME, PPN, AND TURNBINE_JOBNAME will
# be ignored if the MACHINE variable (see below) is not set.
export QUEUE=batch
export WALLTIME=12:00:00
export PPN=8
export TURBINE_JOBNAME="${EXPID}_job"
export PYTHONPATH=$EMEWS_PROJECT_ROOT/python

CMD_LINE_ARGS="$*"

mkdir -p $TURBINE_OUTPUT

EXECUTABLE=cancer-immune-EMEWS2
EP=$EMEWS_PROJECT_ROOT/../PhysiCell-src/$EXECUTABLE
EXE=$TURBINE_OUTPUT/$EXECUTABLE
cp $EP $EXE

DEFAULT_XML=$EMEWS_PROJECT_ROOT/data/PhysiCell_default_settings.xml
CONFIG=$TURBINE_OUTPUT/default_config.xml
cp $DEFAULT_XML $CONFIG

NUM_THREADS=$2

# if R cannot be found, then these will need to be
# uncommented and set correctly.
# export R_HOME=/path/to/R
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$R_HOME/lib
# if python packages can't be found, then uncommited and set this
# export PYTHONPATH=/path/to/python/packages

# Resident task workers and ranks
export TURBINE_RESIDENT_WORK_WORKERS=1
export RESIDENT_WORK_RANKS=$(( PROCS - 2 ))

# EQ/R location
EQR=$SWIFT_T/ext/EQ-R

NUM_CLUSTERS=25
NUM_RANDOM_SAMPLING=25
MAX_ITER=20
TRIALS=20
N=2
TISD=0.25

# TODO edit command line arguments, e.g. -nv etc., as appropriate
# for your EQ/Py based run. Note that $* will pass any of this
# script's command line arguments to swift-t
PSF="$EMEWS_PROJECT_ROOT/data/al_params.Rds"
PARAM_SET=$TURBINE_OUTPUT/al_params.Rds
cp $PSF $PARAM_SET

RF="$EMEWS_PROJECT_ROOT/data/sdf_0.Rds"
RESTART_FILE=$TURBINE_OUTPUT/sdf_0.Rds
cp $RF $RESTART_FILE


# CMD_LINE_ARGS+="-restart_file=$RESTART_FILE"

# set machine to your schedule type (e.g. pbs, slurm, cobalt etc.),
# or empty for an immediate non-queued unscheduled run
MACHINE="cray"

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

export TURBINE_RESIDENT_WORK_WORKERS=1
export RESIDENT_WORK_RANKS=$(( PROCS - 2 ))

module load PrgEnv-gnu

set -x

swift-t -n $PROCS $MACHINE -p -r $EQR -I $EQR \
  $EMEWS_PROJECT_ROOT/swift/al_workflow.swift \
  -e LD_LIBRARY_PATH=$LD_LIBRARY_PATH \
  -e EMEWS_PROJECT_ROOT=$EMEWS_PROJECT_ROOT \
  -e TURBINE_OUTPUT=$TURBINE_OUTPUT \
  -e PYTHONPATH=$PYTHONPATH \
  -e TURBINE_RESIDENT_WORK_WORKERS=$TURBINE_RESIDENT_WORK_WORKERS \
  -e RESIDENT_WORK_RANKS = $RESIDENT_WORK_RANKS \
  -num_clusters=$NUM_CLUSTERS \
  -num_random_sampling=$NUM_RANDOM_SAMPLING \
  -max_iter=$MAX_ITER \
  -param_set=$PARAM_SET \
  -trials=$TRIALS \
  -n=$N \
  -restart_file=$RESTART_FILE \
  -model="$EXE" \
  -config="$CONFIG" \
  -num_threads=$NUM_THREADS \
  -tisd=$TISD
