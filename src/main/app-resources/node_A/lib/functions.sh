#!/bin/bash

# define the exit codes
SUCCESS=0
ERR_PUBLISH=55

# source the ciop functions (e.g. ciop-log, ciop-getparam)
echo program "started"
source ${ciop_job_include}

MATLAB_LAUNCHER=$_CIOP_APPLICATION_PATH/node_A/bin/run_runALES_jason_CSF.sh
MATLAB_CMD=$_CIOP_APPLICATION_PATH/node_A/bin/runALES_jason_CSF
MATLAB_RUNTIME=/opt/v90
#RADS=/home/ndayoub/ALES_RUN/
RADS=https://store.terradue.com/api/rads/data/
##############################################################################
# Trap function to exit gracefully
# Globals:
#   SUCCESS
#   ERR_PUBLISH
# Arguments:
#   None
# Returns:
#   None
###############################################################################

# define the exit codes

SUCCESS=0
ERR_MCR=1
ERR_NOPARAMS=2
ERR_NOINPUT=3
# add trap to exit
function cleanExit ()
{
  local retval=$?
  local msg=""
  case "${retval}" in
    ${SUCCESS})     msg="Processing successfully concluded";;
    $ERR_MCR)       msg="Error executing MCR";;
    $ERR_NOPARAMS)  msg="Some parameters undefined";;
    $ERR_NOINPUT)   msg="No input files or parameters";;
    *)              msg="Unknown error";;
  esac

  [ "${retval}" != "0" ] && ciop-log "ERROR" "Error ${retval} - ${msg}, processing aborted" || ciop-log "INFO" "${msg}"
  exit ${retval}
}

###############################################################################
# Log an input string to the log file
# Globals:
#   None
# Arguments:
#   input reference to log
# Returns:
#   None
###############################################################################
function log_input()
{
  local input="$1"
  ciop-log "INFO" "processing input: ${input}"
}

###############################################################################
# Pass the input string to the next node, without storing it on HDFS
# Globals:
#   None
# Arguments:
#   input reference to pass
# Returns:
#   0 on success
#   ERR_PUBLISH if something goes wrong
###############################################################################
function pass_next_node()
{
  local input="$1"
  echo "${input}" | ciop-publish -s || return ${ERR_PUBLISH}
}

function main ()
{
  local input              
  input="$1"

# get parameters
# get the time limits
   date_start=$( ciop-getparam startdate )
   date_end=$( ciop-getparam enddate )

# get the latitude and longitude limits
   bbox="$( ciop-getparam qbbox )" 
   lat_min=$( echo ${bbox} | cut -d "," -f 2 )
   lat_max=$( echo ${bbox} | cut -d "," -f 4 )
   lon_min=$( echo ${bbox} | cut -d "," -f 1 )
   lon_max=$( echo ${bbox} | cut -d "," -f 3 )

#  get the distance limits
   dislims="$( ciop-getparam distant_limits )"
   dist_min=$( echo ${dislims} | cut -d "," -f 1 )
   dist_max=$( echo ${dislims} | cut -d "," -f 2 )

# get the corrections
   iono="$( ciop-getparam ionosphere )"
   dry="$( ciop-getparam dry_tropo )"
   wet="$( ciop-getparam wet_tropo )"
   ib="$( ciop-getparam inv_bar )"
   sb="$( ciop-getparam ssb )"
   ocean="$( ciop-getparam tide_ocean )"
   load="$( ciop-getparam tide_load )"

# get the SGDR files from the catalog search

	ciop-log "INFO" "----------------------------"
	ciop-log "INFO" "processing input: ${input}"
	ciop-log "INFO" "opensearch-client $input enclosure"
	ciop-log "INFO" "ciop-copy -o $TMPDIR $enclosure"
	ciop-log "INFO" "----------------------------"
   enclosure=$( opensearch-client $input enclosure )    
   retrieved=$( ciop-copy -o $TMPDIR $enclosure )        
   local_input=$retrieved
# get the mission name
   mission="$( ciop-getparam Mission )"
# pass arguments and run matlab code (note: $TMPDIR is passed to the code to contain the output files)
   cmd="$MATLAB_LAUNCHER $MATLAB_RUNTIME $mission $lat_min $lat_max $dist_min $dist_max $local_input $RADS $TMPDIR "$iono" "$dry" "$wet" "$ib" "$sb" "$ocean" "$load""
   eval $cmd 1>&2

   [ "$?" == "0" ] || exit $ERR_MCR

# publish results
#   echo $TMPDIR/ALES/*.mat | ciop-publish -m
   echo $TMPDIR/CGDR/*.nc | ciop-publish -m
#rm $TMPDIR/ALES/*.mat
rm $TMPDIR/CGDR/*.nc
   ciop-log "INFO" "Publishing ..."
nj=$nj+1
if (($nj==1)); then
echo "Time Span: " $date_start $date_end
echo "Box Boundaries: " $lon_min $lon_max $lat_min $lat_max
echo "Distance Limits: " $dist_min $dist_max
fi 
}

###############################################################################
# ithout storing it on HDFS
# Globals:
#   None
# Arguments:
#   input reference to pass
# Returns:
#   0 on success
#   ERR_PUBLISH if something goes wrong 
###############################################################################




