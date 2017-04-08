

# Processing AWS output
```
# From top directory of supplement
julia scripts/process_awsoutput.jl awsoutput/misocp3q/ results/misocp3q.csv
```

# Processing CSV output

```
# From top directory of supplement
julia scripts/process_csv.jl results/misocp3q.csv
# if there are runs to exclude, list them in an "exclude" file
julia scripts/process_csv.jl results/misocp3q.csv results/misocp3q_exclude
```
