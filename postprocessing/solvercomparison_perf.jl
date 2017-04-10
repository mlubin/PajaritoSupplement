# dual only versus dual only no scaling

using JLD

include("perfplots.jl")

timeshift = 10.0

# produced by process_csv.jl in perfprofile mode
jldsource = joinpath(dirname(@__FILE__),"solvercomparison_perf.jld")

d = load(jldsource)
time_table = d["time_table"] + timeshift
solvers = d["solvers"]
@assert solvers == ["CPLEX_MISOCP","PAJ_CPLEX_MOSEK_msd","PAJ_CPLEX_MOSEK","SCIP_MISOCP","BONMIN","PAJ_CBC_ECOS","PAJ_GLPK_ECOS"]
instance_names = d["instance_names"]

Plots.scalefontsizes(2.1)

performance_profile(time_table[:,1:2], ["CPLEX","MSD CPLEX"],logscale=false, ymax=1.0, xmax=15, linewidth=3)
Plots.savefig(joinpath(dirname(@__FILE__),"commercialtime.eps"))

performance_profile(time_table[:,5:7], ["BONMIN","iter. Cbc","iter. GLPK"],logscale=false, ymax=1.0, xmax=15, linewidth=3)
Plots.savefig(joinpath(dirname(@__FILE__),"opensourcetime.eps"))

performance_profile(time_table[:,[4,6]], ["iter. Cbc","SCIP_MISOCP"],logscale=false, ymax=1.0, xmax=15, linewidth=3)
Plots.savefig(joinpath(dirname(@__FILE__),"itercbcsciptime.eps"))
