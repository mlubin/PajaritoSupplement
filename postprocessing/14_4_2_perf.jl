# dual only versus dual only no scaling

using JLD

include("perfplots.jl")

# produced by process_csv.jl in perfprofile mode
jldsource = joinpath(dirname(@__FILE__),"14_4_2_perf.jld")

d = load(jldsource)
time_table = d["time_table"]
itercount_table = d["itercount_table"]
solvers = d["solvers"]
@assert solvers == ["PAJ_CPLEX_MOSEK_dualonly","PAJ_CPLEX_MOSEK_primonlynorelax", "PAJ_CPLEX_MOSEK_msddualonly", "PAJ_CPLEX_MOSEK_msdprimonlynorelax"]
instance_names = d["instance_names"]

Plots.scalefontsizes(2.1)

performance_profile(time_table, ["Iter subp","Iter prim","MSD subp","MSD prim"],logscale=false, ymax=1.0, xmax=20, linewidth=3)
Plots.savefig(joinpath(dirname(@__FILE__),"14_4_2_time.eps"))
