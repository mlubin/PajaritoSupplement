

# Processing AWS output
```
# From top directory of supplement
julia scripts/process_awsoutput.jl awsoutput/misocp3q/ results/misocp3q.csv
```

# Processing CSV output

```
# From top directory of supplement
julia scripts/process_csv.jl check results/misocp3q.csv

# if there are runs to exclude, list them in an "exclude" file
julia scripts/process_csv.jl statuscounts results/misocp3q.csv --exclude=postprocessing/misocp3q_exclude > postprocessing/misocp3q_statuscounts

julia scripts/process_csv.jl geomeans results/misocp3q.csv --exclude=postprocessing/misocp3q_exclude > postprocessing/misocp3q_geomeans 


```

# Generating performance profiles
```
# output goes into jld file
julia scripts/process_csv.jl perfprofile results/misocp3q.csv postprocessing/14_4_1_perf.jld PAJ_CPLEX_MOSEK_dualonly PAJ_CPLEX_MOSEK_dualonlynoscale --exclude=postprocessing/misocp3q_exclude

julia postprocessing/14_4_1_perf.jl

```
