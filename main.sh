#!/bin/bash

#Remeber to have env Variables for:
# ORANGEFS_KO
# ORANGEFS_PATH
#Usage
# ./setup\
#   fd 
#

#Input Variables
node_file="./all_nodes"
server_partition="stor"
num_servers=2
server_dir=/mnt/ssd/jcernudagarcia/orangefs
client_partition="comp"
num_clients=2
client_dir=/mnt/nvme/jcernudagarcia/write/pfs/

#General Variables
CWD=$(pwd)

server_list=($(grep -E "*${server_partition}*" ${node_file} | head -n ${num_servers}))
server_comma=$( IFS=$','; echo "${server_list[*]}" )

client_list=($(grep -E "*${client_partition}*" ${node_file} | head -n ${num_clients}))

# #Config PFS
name="orangefs" #TODO: Allow renaming
comm_port=3334  #TODO: Allow changing
dist_name="simple_stripe"
dist_params="strip_size:65536" #TODO: Allow changing
data_dir=${server_dir}/data/
meta_dir=${server_dir}/meta/
log_dir=${server_dir}/log

mkdir -p ${CWD}/conf/
echo pvfs2-genconfig --quiet --protocol tcp --tcpport ${comm_port} --dist-name ${dist_name} --dist-params ${dist_params} --ioservers ${server_comma} --metaservers ${server_comma} --storage ${data_dir} --metadata ${meta_dir} --logfile ${log_dir} ${CWD}/conf/pfs.conf

#Server Setup
for node in ${server_list}
do
  ssh $node /bin/bash << EOF
    echo "Setting up server at ${node}"
    rm -rf ${server_dir}*
    mkdir -p ${server_dir}
    pvfs2-server -f -a ${node} ${CWD}/pfs.conf
    pvfs2-server -a ${node} ${CWD}/conf/pfs.conf
  EOF
done


#Client Setup
for node in ${client_list}
do
  ssh $node /bin/bash << EOF
    echo "Starting client on ${node}"
    sudo kill-pvfs2-client
    mkdir -p ${client_dir} 
    sudo insmod ${ORANGEFS_KO}/pvfs2.ko
    sudo ${ORANGEFS_PATH}/sbin/pvfs2-client -p ${ORANGEFS_PATH}/sbin/pvfs2-client-core
    sudo mount -t pvfs2 tcp://${server_list[0]}:${comm_port}/${name} ${client_dir}
  EOF
done

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