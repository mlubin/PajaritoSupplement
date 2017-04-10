# dual only versus dual only no scaling

using JLD

include("perfplots.jl")

timeshift = 10.0

# produced by process_csv.jl in perfprofile mode
jldsource = joinpath(dirname(@__FILE__),"subpscaling_perf.jld") 

d = load(jldsource)
time_table = d["time_table"] + timeshift
itercount_table = d["itercount_table"]
solvers = d["solvers"]
@assert solvers == ["PAJ_CPLEX_MOSEK_dualonly","PAJ_CPLEX_MOSEK_dualonlynoscale"]
instance_names = d["instance_names"]

Plots.scalefontsizes(2.3)

performance_profile(time_table, ["scaling","no scaling"],logscale=false, ymax=1.0, xmax=4, linewidth=3, xticks=[1,2,3,4])
Plots.savefig(joinpath(dirname(@__FILE__),"scaletime.eps"))

performance_profile(itercount_table, ["scaling","no scaling"],logscale=false, ymax=1.0, xmax=4, linewidth=3, xticks=[1,2,3,4])
Plots.savefig(joinpath(dirname(@__FILE__),"scaleiter.eps"))
