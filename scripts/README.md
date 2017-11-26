
Run the following commands from top directory of PajaritoSupplement.

# MISOCP solver comparisons
```
# Processing raw solver outputs
julia scripts/process_output.jl output/misocp results/misocp.csv

# Processing CSV file
julia scripts/process_csv.jl check results/misocp.csv

# If there are runs to exclude, list them in an "exclude" file (analysis/misocp_exclude.txt)

# Generating table with status counts
julia scripts/process_csv.jl statuscounts results/misocp.csv analysis/misocp_statuscounts.csv --exclude=analysis/misocp_exclude.txt

# Printing geomeans
julia scripts/process_csv.jl geomeans results/misocp.csv --exclude=analysis/misocp_exclude.txt > analysis/misocp_geomeans.txt

# Generating performance profiles
julia scripts/process_csv.jl perfprofile results/misocp.csv analysis/misocp_perf.jld BONMIN PAJ_CBC_ECOS PAJ_GLPK_ECOS SCIP_MISOCP CPLEX_MISOCP PAJ_CPLEX_MOSEK PAJ_CPLEX_MOSEK_msd --exclude=analysis/misocp_exclude.txt --bestof="BONMIN BONMIN_BB BONMIN_OA BONMIN_OADIS"
julia analysis/misocp_perf.jl
```

# MICP algorithmic comparisons
```
# Processing raw solver outputs
julia scripts/process_output.jl output/micp results/micp.csv

# Processing CSV file
julia scripts/process_csv.jl check results/micp.csv

# If there are runs to exclude, list them in an "exclude" file (analysis/micp_exclude.txt)

# Generating table with status counts
julia scripts/process_csv.jl statuscounts results/micp.csv analysis/micp_statuscounts.csv --exclude=analysis/micp_exclude.txt

# Printing geomeans
julia scripts/process_csv.jl geomeans results/micp.csv --exclude=analysis/micp_exclude.txt > analysis/micp_geomeans.txt

# Generating performance profiles
julia scripts/process_csv.jl perfprofile results/micp.csv analysis/scale_perf.jld PAJ_CPLEX_MOSEK_dualonly PAJ_CPLEX_MOSEK_dualonlynoscale --exclude=analysis/micp_exclude.txt
julia analysis/scale_perf.jl
julia scripts/process_csv.jl perfprofile results/micp.csv analysis/sepcuts_perf.jld PAJ_CPLEX_MOSEK PAJ_CPLEX_MOSEK_dualonly PAJ_CPLEX_MOSEK_primonlynorelax --exclude=analysis/micp_exclude.txt
julia analysis/sepcuts_perf.jl
```
