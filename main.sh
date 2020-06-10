#!/bin/bash

#Remeber to have env Variables for:
# ORANGEFS_KO
# ORANGEFS_PATH
#Usage
# ./setupPfs\
#   fd 
#

#Input Variables
node_file="./all_nodes"
partition="stor"
num_servers=2
server_dir=/mnt/ssd/jcernudagarcia/orangefs

#General Variables
CWD=$(pwd)
server_list=($(grep -E "*${partition}*" ${node_file} | head -n ${num_servers}))
server_comma=$( IFS=$','; echo "${server_list[*]}" )

# #Config PFS
name="orangefs" #TODO: Allow renaming
comm_port=3334  #TODO: Allow changing
dist_name="simple_stripe"
dist_params="strip_size:65536" #TODO: Allow changing
data_dir=${server_dir}/data/
meta_dir=${server_dir}/meta/
log_dir=${server_dir}/log

echo pvfs2-genconfig --quiet --protocol tcp --tcpport ${comm_port} --dist-name ${dist_name} --dist-params ${dist_params} --ioservers ${server_comma} --metaservers ${server_comma} --storage ${data_dir} --metadata ${meta_dir} --logfile ${log_dir} ${CWD}/pfs.conf

# #Server Setup
# #!/bin/bash
# SCRIPT_DIR=`pwd`
# NODES=$(cat ${SCRIPT_DIR}/conf/server_lists/clients)
# PFS_SERVERS=($(cat ${SCRIPT_DIR}/conf/server_lists/pfs))
# server=${PFS_SERVERS[0]}
# for node in $NODES
# do
# if [[ $node == *"comp"* ]]; then
#   mount_dir=/mnt/nvme/jcernudagarcia/write/pfs/
# else
#   mount_dir=/mnt/ssd/jcernudagarcia/write/pfs/
# fi
# echo "Starting pfs client on $node"
# ssh $node /bin/bash << EOF
# sudo kill-pvfs2-client
# mkdir -p ${mount_dir} 
# sudo insmod ${ORANGEFS_KO}/pvfs2.ko
# sudo ${ORANGEFS_PATH}/sbin/pvfs2-client -p ${ORANGEFS_PATH}/sbin/pvfs2-client-core
# sudo mount -t pvfs2 tcp://$server:3334/pfs ${mount_dir}
# mount | grep pvfs2
# EOF
# done

# #Client Setup
# #!/bin/bash
# SCRIPT_DIR=`pwd`
# NODES=$(cat ${SCRIPT_DIR}/conf/server_lists/clients)
# PFS_SERVERS=($(cat ${SCRIPT_DIR}/conf/server_lists/pfs))
# server=${PFS_SERVERS[0]}
# for node in $NODES
# do
# if [[ $node == *"comp"* ]]; then
#   mount_dir=/mnt/nvme/jcernudagarcia/write/pfs/
# else
#   mount_dir=/mnt/ssd/jcernudagarcia/write/pfs/
# fi
# echo "Starting pfs client on $node"
# ssh $node /bin/bash << EOF
# sudo kill-pvfs2-client
# mkdir -p ${mount_dir} 
# sudo insmod ${ORANGEFS_KO}/pvfs2.ko
# sudo ${ORANGEFS_PATH}/sbin/pvfs2-client -p ${ORANGEFS_PATH}/sbin/pvfs2-client-core
# sudo mount -t pvfs2 tcp://$server:3334/pfs ${mount_dir}
# mount | grep pvfs2
# EOF
# done

# #IOR
# OUT_DIR=$1
# IDENTIFIER=$2
# $i=
# echo -e "${GREEN}Running ${IDENTIFIER} on ${i} nodes ${NC}"
# echo "mpirun --hostfile computeNodes -np $(( 40*$i )) ior -a MPIIO -b 16m -s 4 -t 16m -e -E -k -w -i 3 -o ${OUT_DIR} > log-${IDENTIFIER}-${i}.log"
# mpirun --hostfile computeNodes -np $(( 40*$i )) ior -a MPIIO -b 16m -s 4 -t 16m -e -E -k -w -i 3 -o ${OUT_DIR} > log-${IDENTIFIER}-${i}.log
# echo -n "${IDENTIFIER}-${i}, " >> results
# grep -E "write" log-${IDENTIFIER}-${i}.log | tail -n 1 | awk '{ print $4 }' >> results
# mv log-${IDENTIFIER}-${i}.log ./logs/