# dual only versus dual only no scaling

using JLD

include("perfplots.jl")

timeshift = 10.0

# produced by process_csv.jl in perfprofile mode
jldsource = joinpath(dirname(@__FILE__),"subpsep_perf.jld")

d = load(jldsource)
time_table = d["time_table"] + timeshift
itercount_table = d["itercount_table"]
solvers = d["solvers"]
@assert solvers == ["PAJ_CPLEX_MOSEK_dualonly","PAJ_CPLEX_MOSEK_primonlynorelax", "PAJ_CPLEX_MOSEK_msddualonly", "PAJ_CPLEX_MOSEK_msdprimonlynorelax"]
instance_names = d["instance_names"]

Plots.scalefontsizes(2.1)

performance_profile(time_table, ["iter. subp","iter. sep","MSD subp","MSD sep"],logscale=false, ymax=1.0, xmax=15, linewidth=3)
Plots.savefig(joinpath(dirname(@__FILE__),"septime.tex"))
