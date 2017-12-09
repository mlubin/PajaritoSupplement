using JLD

include("perfplots.jl")

timeshift = 10.0

# produced by process_csv.jl in perfprofile mode
jldsource = joinpath(dirname(@__FILE__),"sepcuts_perf.jld")

d = load(jldsource)
time_table = d["time_table"] + timeshift
itndcount_table = d["itndcount_table"]
solvers = d["solvers"]
@assert solvers == ["PAJ_Gurobi_MOSEK","PAJ_Gurobi_MOSEK_msd","PAJ_Gurobi_sep","PAJ_Gurobi_msd_sep"]
instance_names = d["instance_names"]

performance_profile(time_table[:,[1,3]], ["subp+","sep"], logscale=false, ymax=1.0, xmax=6, linewidth=3)
Plots.savefig(joinpath(dirname(@__FILE__),"sepcuts_iter_time.tex"))

performance_profile(itndcount_table[:,[1,3]], ["subp+","sep"], logscale=false, ymax=1.0, xmax=8, linewidth=3)
Plots.savefig(joinpath(dirname(@__FILE__),"sepcuts_iter_iters.tex"))

performance_profile(time_table[:,[2,4]], ["subp+","sep"], logscale=false, ymax=1.0, xmax=6, linewidth=3)
Plots.savefig(joinpath(dirname(@__FILE__),"sepcuts_msd_time.tex"))

performance_profile(itndcount_table[:,[2,4]], ["subp+","sep"], logscale=false, ymax=1.0, xmax=25, linewidth=3)
Plots.savefig(joinpath(dirname(@__FILE__),"sepcuts_msd_nodes.tex"))
