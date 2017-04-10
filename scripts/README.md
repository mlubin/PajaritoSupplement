

# Processing AWS output
```
# From top directory of supplement
julia scripts/process_awsoutput.jl awsoutput/misocp3q/ results/misocp3q.csv
julia scripts/process_awsoutput.jl awsoutput/bonmin awsoutput/misocp3q awsoutput/misocpApr6 results/solvercomparison.csv
```

# Processing CSV output

```
# From top directory of supplement
julia scripts/process_csv.jl check results/misocp3q.csv

# if there are runs to exclude, list them in an "exclude" file
julia scripts/process_csv.jl statuscounts results/misocp3q.csv postprocessing/misocp3q_statuscounts.csv --exclude=postprocessing/misocp3q_exclude

julia scripts/process_csv.jl geomeans results/misocp3q.csv --exclude=postprocessing/misocp3q_exclude > postprocessing/misocp3q_geomeans 

julia scripts/process_csv.jl check results/solvercomparison.csv

julia scripts/process_csv.jl statuscounts results/solvercomparison.csv postprocessing/solvercomparison_statuscounts.csv --exclude=postprocessing/solvercomparison_exclude --bestof="BONMIN BONMIN_BB BONMIN_OA BONMIN_OADIS" --bestof="PAJ_CPLEX_MOSEK_msd_bestof2 PAJ_CPLEX_MOSEK_msd PAJ_CPLEX_MOSEK_msdnostarts"

julia scripts/process_csv.jl geomeans results/solvercomparison.csv --exclude=postprocessing/solvercomparison_exclude > postprocessing/solvercomparison_geomeans

julia scripts/process_csv.jl geomeans results/solvercomparison.csv --exclude=postprocessing/solvercomparison_exclude --bestof="BONMIN BONMIN_BB BONMIN_OA BONMIN_OADIS" --bestof="PAJ_CPLEX_MOSEK_msd_bestof2 PAJ_CPLEX_MOSEK_msd PAJ_CPLEX_MOSEK_msdnostarts"

```

# Generating performance profiles
```
# output goes into jld file
julia scripts/process_csv.jl perfprofile results/misocp3q.csv postprocessing/subpscaling_perf.jld PAJ_CPLEX_MOSEK_dualonly PAJ_CPLEX_MOSEK_dualonlynoscale --exclude=postprocessing/misocp3q_exclude

julia postprocessing/subpscaling_perf.jl

julia scripts/process_csv.jl perfprofile results/misocp3q.csv postprocessing/subpsep_perf.jld PAJ_CPLEX_MOSEK_dualonly PAJ_CPLEX_MOSEK_primonlynorelax PAJ_CPLEX_MOSEK_msddualonly PAJ_CPLEX_MOSEK_msdprimonlynorelax  --exclude=postprocessing/misocp3q_exclude

julia postprocessing/subpsep_perf.jl

julia scripts/process_csv.jl perfprofile results/solvercomparison.csv postprocessing/solvercomparison_perf.jld CPLEX_MISOCP PAJ_CPLEX_MOSEK_msd PAJ_CPLEX_MOSEK SCIP_MISOCP BONMIN PAJ_CBC_ECOS PAJ_GLPK_ECOS  --exclude=postprocessing/solvercomparison_exclude --bestof="BONMIN BONMIN_BB BONMIN_OA BONMIN_OADIS" --bestof="PAJ_CPLEX_MOSEK_msd_bestof2 PAJ_CPLEX_MOSEK_msd PAJ_CPLEX_MOSEK_msdnostarts"

julia postprocessing/solvercomparison_perf.jl
```
