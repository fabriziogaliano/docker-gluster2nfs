#!/usr/bin/env bash
set -e

# Variable for GlusterClient
GLUSTER_BIN=$(which mount.glusterfs)
EXPORT_ID=$((1))

# Options for starting Ganesha
: ${GANESHA_LOGFILE:="/dev/stdout"}
: ${GANESHA_CONFIGFILE:="/etc/ganesha/ganesha.conf"}
: ${GANESHA_OPTIONS:="-N NIV_EVENT"} # NIV_DEBUG
: ${GANESHA_EPOCH:=""}
: #${GANESHA_EXPORT:="/export"}

cat /dev/null > /etc/ganesha/ganesha.conf

function mountExportsVolumes {

  read -a gluster_volume_names <<<$GLUSTER_VOLUMES

  for volume in ${gluster_volume_names[@]}; do
    mkdir -p /data/gluster/${volume}
    EXPORT_ID=$(($EXPORT_ID+1))
    $GLUSTER_BIN ${GLUSTER_HOST}:/${volume} /data/gluster/${volume}
    #echo "/data/gluster/${volume} *(rw,sync,no_subtree_check,fsid=0,no_root_squash)" >> /etc/exports
    bootstrap_config $volume
  done

}

function bootstrap_config {
	volume=$1
	echo "Bootstrapping Ganesha NFS config"
    cat <<END >>${GANESHA_CONFIGFILE}
EXPORT
{
		# Export Id (mandatory, each EXPORT must have a unique Export_Id)
		Export_Id = ${EXPORT_ID};

		# Exported path (mandatory)
		Path = /data/gluster/${volume};
		# Pseudo Path (for NFS v4)
		Pseudo = /${volume}_nfs4;
		Access_Type = RW;
		Squash = No_Root_Squash;
		#Transports = TCP;
		#Protocols = NFS4;
		SecType = "sys";
		# Exporting FSAL
		FSAL {
			Name = VFS;
		}
}
END
}

# function bootstrap_export {
# 	if [ ! -f ${GANESHA_EXPORT} ]; then
# 		mkdir -p "${GANESHA_EXPORT}"
#     fi
# }

function init_rpc {
	echo "Starting rpcbind"
	rpcbind || return 0
	rpc.statd -L || return 0
	rpc.idmapd || return 0
	sleep 1
}

function init_dbus {
	echo "Starting dbus"
	rm -f /var/run/dbus/system_bus_socket
	rm -f /var/run/dbus/pid
	dbus-uuidgen --ensure
	dbus-daemon --system --fork
	sleep 1
}

mountExportsVolumes
#bootstrap_config
init_rpc
init_dbus

echo "Starting Ganesha NFS"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib
exec /usr/bin/ganesha.nfsd -F -L ${GANESHA_LOGFILE} -f ${GANESHA_CONFIGFILE} ${GANESHA_OPTIONS}

