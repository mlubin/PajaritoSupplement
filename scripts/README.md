
Run the following commands from top directory of PajaritoSupplement. If Julia indicates that any packages need to be installed, do this. Ignore deprecation warnings.

# MISOCP solver comparisons
```
# Processing raw solver outputs
julia scripts/process_output.jl oldoutput/misocp results/misocp.csv

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

# MICP exclude
```
# Processing raw solver outputs
julia scripts/process_output.jl oldoutput/scale oldoutput/subpsep oldoutput/disagg results/micp.csv

# Processing CSV file
julia scripts/process_csv.jl check results/micp.csv

# If there are runs to exclude, list them in "exclude" files (analysis/scale_exclude.txt for noscale/scale/scaleup solvers, or analysis/disagg_exclude.txt for disagg/nodisagg solvers, or analysis/subpsep_exclude.txt for other solvers)

# MICP cut scaling algorithmic comparisons
```
# Processing raw solver outputs
julia scripts/process_output.jl oldoutput/scale results/scale.csv

# Generating table with status counts
julia scripts/process_csv.jl statuscounts results/scale.csv analysis/scale_statuscounts.csv --exclude=analysis/scale_exclude.txt

# Printing geomeans
julia scripts/process_csv.jl geomeans results/scale.csv --exclude=analysis/scale_exclude.txt > analysis/scale_geomeans.txt

# Generating performance profiles
julia scripts/process_csv.jl perfprofile results/scale.csv analysis/scale_perf.jld PAJ_Gurobi_MOSEK_noscale_subponly_noinit PAJ_Gurobi_MOSEK_msd_noscale_subponly_noinit PAJ_Gurobi_MOSEK_scale_subponly_noinit PAJ_Gurobi_MOSEK_msd_scale_subponly_noinit  --exclude=analysis/scale_exclude.txt
julia analysis/scale_perf.jl
```

# MICP cut disagg algorithmic comparisons
```
# Processing raw solver outputs
julia scripts/process_output.jl oldoutput/disagg results/disagg.csv

# Generating table with status counts
julia scripts/process_csv.jl statuscounts results/disagg.csv analysis/disagg_statuscounts.csv --exclude=analysis/disagg_exclude.txt

# Printing geomeans
julia scripts/process_csv.jl geomeans results/disagg.csv --exclude=analysis/disagg_exclude.txt > analysis/disagg_geomeans.txt

# Generating performance profiles
julia scripts/process_csv.jl perfprofile results/disagg.csv analysis/disagg_perf.jld PAJ_Gurobi_MOSEK_nodisagg_subponly_noinit PAJ_Gurobi_MOSEK_msd_nodisagg_subponly_noinit PAJ_Gurobi_MOSEK_subponly_noinit PAJ_Gurobi_MOSEK_msd_subponly_noinit --exclude=analysis/disagg_exclude.txt
julia analysis/disagg_perf.jl
```

# MICP cut types algorithmic comparisons
```
# Processing raw solver outputs
julia scripts/process_output.jl oldoutput/subpsep results/subpsep.csv

# Generating table with status counts
julia scripts/process_csv.jl statuscounts results/subpsep.csv analysis/subpsep_statuscounts.csv --exclude=analysis/subpsep_exclude.txt

# Printing geomeans
julia scripts/process_csv.jl geomeans results/subpsep.csv --exclude=analysis/subpsep_exclude.txt > analysis/subpsep_geomeans.txt

# Generating performance profiles
julia scripts/process_csv.jl perfprofile results/subpsep.csv analysis/subpsep_perf.jld PAJ_Gurobi_MOSEK PAJ_Gurobi_MOSEK_msd PAJ_Gurobi_sep PAJ_Gurobi_msd_sep --exclude=analysis/subpsep_exclude.txt
julia analysis/subpsep_perf.jl
```
