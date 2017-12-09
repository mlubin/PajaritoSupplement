#!/bin/bash
# run from PajaritoSupplement directory

# set julia binary location
JULIA=/home/coey/julia-903644385b/bin/julia

mkdir -p output


for SOLVER in PAJ_Gurobi_msd_sep PAJ_Gurobi_sep PAJ_Gurobi_MOSEK_msd PAJ_Gurobi_MOSEK PAJ_Gurobi_MOSEK_msd_subponly_noinit PAJ_Gurobi_MOSEK_subponly_noinit
do
    $JULIA scripts/runmeta.jl --nochecktimemem $SOLVER 600 40000000 cbfs/micp/ sets/micp_A.txt
    $JULIA scripts/runmeta.jl --nochecktimemem $SOLVER 600 40000000 cbfs/micp/ sets/micp_B.txt
    $JULIA scripts/runmeta.jl --nochecktimemem $SOLVER 600 40000000 cbfs/micp/ sets/micp_C.txt
    $JULIA scripts/runmeta.jl --nochecktimemem $SOLVER 600 40000000 cbfs/misocp/ sets/micp_D.txt
    $JULIA scripts/runmeta.jl --nochecktimemem $SOLVER 600 40000000 cbfs/misocp/ sets/micp_E.txt
done

mkdir -p output/micpsubpsep
mv output/*.txt output/micpsubpsep


for SOLVER in PAJ_Gurobi_MOSEK_msd_noscale PAJ_Gurobi_MOSEK_noscale
do
    $JULIA scripts/runmeta.jl --nochecktimemem $SOLVER 600 40000000 cbfs/micp/ sets/micp_A.txt
    $JULIA scripts/runmeta.jl --nochecktimemem $SOLVER 600 40000000 cbfs/micp/ sets/micp_B.txt
    $JULIA scripts/runmeta.jl --nochecktimemem $SOLVER 600 40000000 cbfs/micp/ sets/micp_C.txt
    $JULIA scripts/runmeta.jl --nochecktimemem $SOLVER 600 40000000 cbfs/misocp/ sets/micp_D.txt
    $JULIA scripts/runmeta.jl --nochecktimemem $SOLVER 600 40000000 cbfs/misocp/ sets/micp_E.txt
done

mkdir -p output/micpscale
mv output/*.txt output/micpscale
