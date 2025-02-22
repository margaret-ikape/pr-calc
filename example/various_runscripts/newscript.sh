#!/bin/bash
#!/usr/bin/python

module load python
module load gsl

bin=../bin
nprocs=$1

mmin=3e9
zeta=100
lambda=300

if [ ! $nprocs > 0 ] ; then
    echo "nprocs = $nprocs not > 0, exiting"
    exit
fi

source ../../scripts/banner.sh
#set cosmo params and params for d2z, fsm, ics etc
python ../../py/setParams.py globalParams.ini

#read -r BOXSIZE=$(python ../../py/setParams.py globalParams.ini)
echo $BOXSIZE

seed=18937

#Generate p(k) based on the cosmo params set above
python /global/cscratch1/sd/ikapem/ksz-reionization/pr-calc/py/tables/Pk.py /global/cscratch1/sd/ikapem/ksz-reionization/pr-calc/c++/example/parameterfiles/param.col

#echo $BOXSIZE
#read -r BOXSIZE=$(python ../../py/setParams.py globalParams.ini)
#echo $BOXSIZE

#read in p(k)
pkfile=wmap5_0_m.pk  

mybanner "RFAST TEST WITH NPROCS = $nprocs"

mybanner "Testing initial conditions"
srun -n $nprocs $bin/ics parameterfiles/param.ics -p $pkfile -o delta -b 1e3 -n 512 -v -s $seed

mybanner "Testing delta2zreion"
echo writing out zreion tables 
python /global/cscratch1/sd/ikapem/ksz-reionization/pr-calc/py/tables/fcoll_zreion.py $mmin $zeta
srun -n $nprocs $bin/delta2zreion parameterfiles/param.d2z -f newtest -m $mmin -z $zeta -r $lambda -v

mybanner "Testing all sky map"
#srun -n $nprocs $bin/allskymap parameterfiles/param.asm -i test -o test -v

mybanner "Testing flat sky map"
srun -n $nprocs $bin/flatskymap parameterfiles/param.fsm -i newtest -o newtest -v

mybanner "Output angular power spectrum to file"
/global/cscratch1/sd/ikapem/ksz-reionization/pr-calc/scripts/map2pk.py maps/newtest.kszmap newtest.ksz_cl.txt

# show the ksz map and output it to a pdf file
mybanner "Show ksz map"

/global/cscratch1/sd/ikapem/ksz-reionization/pr-calc/scripts/showmap.py maps/newtest.kszmap newtest.kszmap.pdf

