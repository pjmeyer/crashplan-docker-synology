#!/bin/sh
#
# Startup script for running CrashPlan in a Docker container on a Synology
# NAS.
#
# PJ Meyer
# (modifications made from original by AJ Kerrigan)


DOCKER=/var/packages/Docker/target/usr/bin/docker
IMAGE=ajkerrigan/crashplan

# Pointing CRASHPLAN_DIR to an existing CrashPlan directory will allow
# the new container to take over for a previous installation, without
# the need to adopt the old computer.
CRASHPLAN_DIR="/usr/local/etc/crashplan"

# Pointing DATA_DIR to an existing CrashPlan backup archive
# will allow the new instance of CrashPlan to skip a lot of time
# synchronizing the backup state.
DATA_DIR="/volume1/CrashPlan/backupArchives"

# Add/change entries here to suit your needs, for example:
# USER_VOLUMES="-v /volume1:/volume1:ro -v /photos:/photos:ro"
#
# The default setting will give the CrashPlan container read-only
# access to /volume1
USER_VOLUMES="-v /volume1:/volume1:ro"

# Check for overloaded variables in root's home dir
if [ -e /root/cp-user-vars.sh ]; then
   echo 'Found the user variables file. Updating...'
   . /root/cp-user-vars.sh
else
   echo 'No user variables file found. Using git defaults. You can change the'
   echo 'default CrashPlan install directory, the user volumes, and data '
   echo 'directory by adding those variables to /root/cp-user-vars.sh'
fi

# Test
echo "CRASHPLAN_DIR=$CRASHPLAN_DIR"
echo "DATA_DIR=$DATA_DIR"
echo "USER_VOLUMES=$USER_VOLUMES"
# Test


VOLUMES="${USER_VOLUMES} -v ${CRASHPLAN_DIR}:/config -v ${DATA_DIR}:/data -v /etc/localtime:/etc/localtime:ro"
PORTS="-p 4242:4242 -p 4243:4243"
PS_FORMAT="\"table {{.Names}}\t{{.Image}}\t{{.CreatedAt}}\t{{.Status}}\""

RUN_CMD="${DOCKER} run -d --net=host --name=crashplan ${VOLUMES} ${PORTS}"
START_CMD="${DOCKER} start"
STOP_CMD="${DOCKER} stop"
PS_CMD="${DOCKER} ps --all --filter ancestor=${IMAGE}"

CONTAINER_ID=`${PS_CMD} --quiet`
[ ${CONTAINER_ID} ] && CONTAINER_STATUS=`${DOCKER} inspect --format="{{.SynoStatus}}" ${CONTAINER_ID}`

_start ()
{
    if [ -z "${CONTAINER_ID}" ]; then
        echo "No existing CrashPlan container found. Running image \"${IMAGE}\"."
        ${RUN_CMD} ${IMAGE}
    elif [ "${CONTAINER_STATUS}" == "exited" ] || [ "${CONTAINER_STATUS}" == "created" ]; then
        echo "Starting CrashPlan container with ID ${CONTAINER_ID}."
        ${START_CMD} ${CONTAINER_ID}
        CONTAINER_STATUS=`${DOCKER} inspect --format="{{.SynoStatus}}" ${CONTAINER_ID}` # Update container status
    else
        echo "Skipping start for CrashPlan container (ID ${CONTAINER_ID}) with \"${CONTAINER_STATUS}\" status."
    fi
}

_stop ()
{
    if [ -z "${CONTAINER_ID}" ]; then
        echo "Can't find a CrashPlan container to stop."
    elif [ "${CONTAINER_STATUS}" == "running" ]; then
        echo "Stopping CrashPlan container (ID ${CONTAINER_ID})."
        ${STOP_CMD} ${CONTAINER_ID}
        CONTAINER_STATUS=`${DOCKER} inspect --format="{{.SynoStatus}}" ${CONTAINER_ID}` # Update container status
    else
        echo "Skipping stop for CrashPlan container (ID ${CONTAINER_ID}) with \"${CONTAINER_STATUS}\" status."
    fi
}

_remove_container ()
{
    _stop
    if [ -n "${CONTAINER_ID}" ]; then
        echo "Removing CrashPlan container (ID ${CONTAINER_ID})."
        ${DOCKER} rm ${CONTAINER_ID} && unset CONTAINER_ID
    fi
}

_restart ()
{
    _stop
    _start
}

_recreate()
{
    _remove_container
    _start
}

case $1 in
start)
    _start
    exit 0
    ;;

stop)
    _stop
    exit 0
    ;;

restart)
    _restart
    exit 0
    ;;

recreate)
    _recreate
    exit 0
    ;;

status)
    if [ -z "${CONTAINER_ID}" ]; then
        echo "No CrashPlan container found."
    else
        printf "\n[[ Docker Container Status ]]\n\n"
        eval ${PS_CMD} --format="$PS_FORMAT"
        
        if [ "${CONTAINER_STATUS}" == "running" ]; then
            printf "\n[[ CrashPlan Service Information ]]\n\n"
            awk -F ',' '{
                printf "%-15s %s\n%-15s %d\n%-15s %-15s\n\n",
                "Host",$3,
                "Port",$1,
                "Auth Token",$2
            }' ${CRASHPLAN_DIR}/id/.ui_info
            grep CPVERSION "${CRASHPLAN_DIR}/log/app.log"
        fi
    fi
    exit 0
    ;;

*)
    /bin/echo "Usage: $0 { start | stop | status | recreate }"
    exit 1
    ;;

esac
