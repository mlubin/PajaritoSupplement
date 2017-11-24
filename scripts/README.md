
Run the following commands from top directory of PajaritoSupplement.

# MISOCP solver comparisons
```
# Processing raw solver outputs
julia scripts/process_output.jl output/misocp results/misocp.csv

# Processing CSV file
julia scripts/process_csv.jl check results/misocp.csv

# If there are runs to exclude, list them in an "exclude" file (postprocessing/misocp_exclude.txt)

# Generating table with status counts
julia scripts/process_csv.jl statuscounts results/misocp.csv postprocessing/misocp_statuscounts.csv --exclude=postprocessing/misocp_exclude.txt

# Printing geomeans
julia scripts/process_csv.jl geomeans results/misocp.csv --exclude=postprocessing/misocp_exclude.txt > postprocessing/misocp_geomeans.txt

# Generating performance profiles
julia scripts/process_csv.jl perfprofile results/misocp.csv postprocessing/misocp_perf.jld BONMIN PAJ_CBC_ECOS PAJ_GLPK_ECOS SCIP_MISOCP CPLEX_MISOCP PAJ_CPLEX_MOSEK PAJ_CPLEX_MOSEK_msd --exclude=postprocessing/misocp_exclude.txt --bestof="BONMIN BONMIN_BB BONMIN_OA BONMIN_OADIS"
julia postprocessing/misocp_perf.jl
```

# MICP algorithmic comparisons
```
# Processing raw solver outputs
julia scripts/process_output.jl output/micp results/micp.csv

# Processing CSV file
julia scripts/process_csv.jl check results/micp.csv

# If there are runs to exclude, list them in an "exclude" file (postprocessing/micp_exclude.txt)

# Generating table with status counts
julia scripts/process_csv.jl statuscounts results/micp.csv postprocessing/micp_statuscounts.csv --exclude=postprocessing/micp_exclude.txt

# Printing geomeans
julia scripts/process_csv.jl geomeans results/micp.csv --exclude=postprocessing/micp_exclude.txt > postprocessing/micp_geomeans.txt

# Generating performance profiles
julia scripts/process_csv.jl perfprofile results/micp.csv postprocessing/scale_perf.jld PAJ_CPLEX_MOSEK_dualonly PAJ_CPLEX_MOSEK_dualonlynoscale --exclude=postprocessing/micp_exclude.txt
julia postprocessing/scale_perf.jl
julia scripts/process_csv.jl perfprofile results/micp.csv postprocessing/sepcuts_perf.jld PAJ_CPLEX_MOSEK PAJ_CPLEX_MOSEK_dualonly PAJ_CPLEX_MOSEK_primonlynorelax --exclude=postprocessing/micp_exclude.txt
julia postprocessing/sepcuts_perf.jl
```
