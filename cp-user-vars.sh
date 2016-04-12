# Sample user configuration file.
#
# To use this file:
# Copy this file to /root/cp-user-vars.sh 
# edit the file contents
# save the file


# Pointing CRASHPLAN_DIR to an existing CrashPlan directory will allow
# the new container to take over for a previous installation, without
# the need to adopt the old computer.
CRASHPLAN_DIR="/usr/local/etc/crashplan"

# This is where incoming backups (i.e. using the Crashplan 
# desktop client to backup to your NAS) are stored.
# Pointing DATA_DIR to an existing CrashPlan backup archive
# will allow the new instance of CrashPlan to skip a lot of time
# synchronizing the backup state.
DATA_DIR="/volume1/Storage/Backup/Crashplan"

# Add/change entries here to suit your needs, for example:
# USER_VOLUMES="-v /volume1:/volume1:ro -v /photos:/photos:ro"
#
# The below setting will give the CrashPlan container read-only
# access to a shared folder 'Storage' on /volume1
USER_VOLUMES="-v /volume1/Storage:/volume1/Storage:ro"

