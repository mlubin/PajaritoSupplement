#!/bin/bash
# run from PajaritoSupplement directory

# set julia binary location
JULIA=/home/coey/julia-903644385b/bin/julia

mkdir -p output

N=12
(
for SOLVER in PAJ_Gurobi_MOSEK_msd PAJ_Gurobi_MOSEK_msd_noscale 
do
    for ISET in A B C D E
    do
        ((i=i%N)); ((i++==0)) && wait
        $JULIA scripts/runmeta.jl $SOLVER 3600 50000000 cbfs/micp/ sets/micp_$ISET.txt &
    done
done
)
wait

mkdir -p output/micp
mv output/*.txt output/micp
