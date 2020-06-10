#!/bin/bash

#Remeber to have env Variables for:
# ORANGEFS_KO
# ORANGEFS_PATH
#We also need
# /conf/all_nodes
# /conf/hostfile for mpi
#Usage
# ./setup\
#   stor 2 /mnt/ssd/jcernudagarcia/orangefs\
#   comp 2 /mnt/nvme/jcernudagarcia/write/pfs/\
#   5 1 16M 4

#Input Variables
server_partition=$1
num_servers=$2
server_dir=$3
client_partition=$4
num_clients=$5
client_dir=$6
num_ior_iter=$7
mpi_factor=$8
ior_size=$9
ior_rep=$10

#General Variables
CWD=$(pwd)

server_list=($(grep -E "*${server_partition}*" ${CWD}/conf/all_nodes | head -n ${num_servers}))
server_comma=$( IFS=$','; echo "${server_list[*]}" )

client_list=($(grep -E "*${client_partition}*" ${CWD}/conf/all_nodes | head -n ${num_clients}))

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
  ssh ${node} /bin/bash << EOF
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
  ssh ${node} /bin/bash << EOF
    echo "Starting client on ${node}"
    sudo kill-pvfs2-client
    mkdir -p ${client_dir} 
    sudo insmod ${ORANGEFS_KO}/pvfs2.ko
    sudo ${ORANGEFS_PATH}/sbin/pvfs2-client -p ${ORANGEFS_PATH}/sbin/pvfs2-client-core
    sudo mount -t pvfs2 tcp://${server_list[0]}:${comm_port}/${name} ${client_dir}
  EOF
done

#IOR
identifier="S-${server_partition}-${server_number}-C-${client_partition}-${client_number}"
factor=$((${num_ior_iter}-1))

mkdir -p ${CWD}/logs/
touch ${client_dir}/test

echo -e "Running IOR"
mpirun --hostfile ${CWD}/conf/hostfile -np $(( ${mpi_factor}*$num_clients )) ior -a MPIIO -b ${ior_size} -s ${ior_rep} -t ${ior_size} -e -E -k -w -i ${num_ior_iter} -o ${client_dir}/test > log-${identifier}.log

echo -n "${identifier}, " >> ${CWD}/results
grep -E "write" log-${identifier}.log | tail -n ${num_ior_iter} | head -n ${factor} | awk -v f=${factor} ' { s+=$2;r=s/f }END{ print r }' >> ${CWD}/results

mv log-${identifier}.log ${CWD}/logs/

#Stop servers
for node in ${server_list}
do
  ssh ${node} /bin/bash << EOF
    echo "Killing server at ${node} "
    rm -rf ${server_dir}/*
    killall -s SIGKILL pvfs2-server
  EOF
done

#Stop clients
for node in ${client_list}
do
  ssh ${node} /bin/bash << EOF
    echo "Stopping client on $node"
    rm -rf ${client_dir}/*
    sudo /usr/sbin/kill-pvfs2-client
  EOF
done