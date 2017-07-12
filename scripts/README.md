

# Processing AWS output
```
# From top directory of supplement
julia scripts/process_awsoutput.jl awsoutput/misocp3q/ results/misocp3q.csv
julia scripts/process_awsoutput.jl awsoutput/bonmin awsoutput/misocp3q awsoutput/misocpApr6 results/solvercomparison.csv
julia scripts/process_awsoutput.jl --noconicsolve out_cont_soc out_cont_socexp out_cont_socexppsd out_cont_socpsd results/multiportfolio_cont.csv
julia scripts/process_awsoutput.jl --noconicsolve out_micp_soc results/multiportfolio_micp_soc.csv
julia scripts/process_awsoutput.jl --noconicsolve out_micp_socexp results/multiportfolio_micp_socexp.csv
julia scripts/process_awsoutput.jl --noconicsolve out_micp_socpsd results/multiportfolio_micp_socpsd.csv
julia scripts/process_awsoutput.jl --noconicsolve out_micp_socexppsd results/multiportfolio_micp_socexppsd.csv
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


julia scripts/process_csv.jl check results/multiportfolio_micp_soc.csv
julia scripts/process_csv.jl check results/multiportfolio_micp_socexp.csv
julia scripts/process_csv.jl check results/multiportfolio_micp_socpsd.csv
julia scripts/process_csv.jl check results/multiportfolio_micp_socexppsd.csv


julia scripts/process_csv.jl statuscounts results/multiportfolio_micp_soc.csv postprocessing/multiportfolio_micp_soc_statuscounts.csv
julia scripts/process_csv.jl statuscounts results/multiportfolio_micp_socexp.csv postprocessing/multiportfolio_micp_socexp_statuscounts.csv
julia scripts/process_csv.jl statuscounts results/multiportfolio_micp_socpsd.csv postprocessing/multiportfolio_micp_socpsd_statuscounts.csv
julia scripts/process_csv.jl statuscounts results/multiportfolio_micp_socexppsd.csv postprocessing/multiportfolio_micp_socexppsd_statuscounts.csv


julia scripts/process_csv.jl geomeans results/multiportfolio_micp_soc.csv > postprocessing/multiportfolio_micp_soc_geomeans
julia scripts/process_csv.jl geomeans results/multiportfolio_micp_socexp.csv > postprocessing/multiportfolio_micp_socexp_geomeans
julia scripts/process_csv.jl geomeans results/multiportfolio_micp_socpsd.csv > postprocessing/multiportfolio_micp_socpsd_geomeans
julia scripts/process_csv.jl geomeans results/multiportfolio_micp_socexppsd.csv > postprocessing/multiportfolio_micp_socexppsd_geomeans

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
