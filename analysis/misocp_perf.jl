using JLD

include("perfplots.jl")

timeshift = 10.0

# produced by process_csv.jl in perfprofile mode
jldsource = joinpath(dirname(@__FILE__),"misocp_perf.jld")

d = load(jldsource)
time_table = d["time_table"] + timeshift
solvers = d["solvers"]
@assert solvers == ["BONMIN","PAJ_CBC_ECOS","PAJ_GLPK_ECOS","SCIP_MISOCP","CPLEX_MISOCP","PAJ_CPLEX_MOSEK","PAJ_CPLEX_MOSEK_msd"]
instance_names = d["instance_names"]

performance_profile(time_table[:,[5,7]], ["CPLEX","MSD_CPLEX_MOSEK"], logscale=false, ymax=1.0, xmax=8, linewidth=3)
Plots.savefig(joinpath(dirname(@__FILE__),"misocp_comm_time.tex"))

performance_profile(time_table[:,[1,2]], ["BONMIN_best","iter_CBC_ECOS"], logscale=false, ymax=1.0, xmax=8, linewidth=3)
Plots.savefig(joinpath(dirname(@__FILE__),"misocp_open_time.tex"))
