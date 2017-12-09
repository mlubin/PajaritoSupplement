using JLD

include("perfplots.jl")

timeshift = 10.0

# produced by process_csv.jl in perfprofile mode
jldsource = joinpath(dirname(@__FILE__),"scale_perf.jld")

d = load(jldsource)
time_table = d["time_table"] + timeshift
itercount_table = d["itercount_table"]
solvers = d["solvers"]
@assert solvers == ["PAJ_Gurobi_MOSEK","PAJ_Gurobi_MOSEK_noscale"]
instance_names = d["instance_names"]

performance_profile(time_table, ["scaling","no scaling"], logscale=false, ymax=1.0, xmax=4, linewidth=3, xticks=[1,2,3,4])
Plots.savefig(joinpath(dirname(@__FILE__),"scale_time.tex"))

performance_profile(itercount_table, ["scaling","no scaling"], logscale=false, ymax=1.0, xmax=4, linewidth=3, xticks=[1,2,3,4])
Plots.savefig(joinpath(dirname(@__FILE__),"scale_iter.tex"))
