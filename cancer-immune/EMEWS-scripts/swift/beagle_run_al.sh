#! /usr/bin/env bash

set -eu


export PROJECT=CI-CCR000040
if [[ ${PROJECT:-} == "" ]]
then
  echo "Error: You need to set environment variable PROJECT."
  exit 1
fi


if [ "$#" -ne 1 ]; then
  script_name=$(basename $0)
  echo "Usage: ${script_name} EXPERIMENT_ID input_file (e.g. ${script_name} experiment_1)"
  exit 1
fi

SWIFT_T=/lustre/beagle2/ncollier/sfw/swift-t_11302017
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
export PROCS=1552

# TODO edit QUEUE, WALLTIME, PPN, AND TURNBINE_JOBNAME
# as required. Note that QUEUE, WALLTIME, PPN, AND TURNBINE_JOBNAME will
# be ignored if the MACHINE variable (see below) is not set.
export QUEUE=batch
export WALLTIME=200:00:00
export PPN=8
export TURBINE_JOBNAME="${EXPID}_job"

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

PARAM_SET="$EMEWS_PROJECT_ROOT/data/al_paramset_2.rds"
NUM_CLUSTERS=5
NUM_RANDOM_SAMPLING=5
MAX_ITER=40
TRIALS=20
N=100
RESTART_FILE="$EMEWS_PROJECT_ROOT/data/restart_sdf_0.rds"

# TODO edit command line arguments, e.g. -nv etc., as appropriate
# for your EQ/Py based run. Note that $* will pass any of this
# script's command line arguments to swift-t


CMD_LINE_ARGS="$* -num_clusters=$NUM_CLUSTERS -num_random_sampling=$NUM_RANDOM_SAMPLING "
CMD_LINE_ARGS+="-max_iter=$MAX_ITER -param_set=$PARAM_SET -trials=$TRIALS -n=$N "
CMD_LINE_ARGS+="-restart_file=$RESTART_FILE"

# set machine to your schedule type (e.g. pbs, slurm, cobalt etc.),
# or empty for an immediate non-queued unscheduled run
MACHINE="cray"

if [ -n "$MACHINE" ]; then
  MACHINE="-m $MACHINE"
fi

export PROCS_PER_RUN=256
export ADLB_PAR_MOD=$PROCS_PER_RUN

MODEL_DIR=$EMEWS_PROJECT_ROOT/model
export CHISIM_INPUT_DIRECTORY=/lustre/beagle2/ncollier/chiSIM/chiSim_Input_NS/chicago_for_256p
export FLU_DATA_FILE=$EMEWS_PROJECT_ROOT/data/flu_data_2015.csv


# Add any script variables that you want to log as
# part of the experiment meta data to the USER_VARS array,
# for example, USER_VARS=("VAR_1" "VAR_2")
USER_VARS=("MODEL_DIR" "INPUT_FILE" "CHISIM_INPUT_DIRECTORY" "FLU_DATA_FILE")
# log variables and script to to TURBINE_OUTPUT directory
log_script

# echo's anything following this standard out
set -x

module swap PrgEnv-cray PrgEnv-gnu
module load boost/1.54.0

swift-t -n $PROCS $MACHINE -p -r $MODEL_DIR -I $MODEL_DIR  -r $EQR -I $EQR \
  $EMEWS_PROJECT_ROOT/swift/al_workflow.swift $CMD_LINE_ARGS
