#!/bin/bash

for i in {1..24}
do
  stor ${i} /mnt/ssd/jcernudagarcia/orangefs\
  comp ${i} /mnt/nvme/jcernudagarcia/write/ssd/\
  5 1 16M 4
done

