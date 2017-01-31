using ConicBenchmarkUtilities
using Pajarito
using ConicNonlinearBridge

# print with full precision
function vec_to_string(v)
    terms = String[]
    for x in v
        b = IOBuffer()
        show(b, x)
        push!(terms, takebuf_string(b))
    end
    return string("[",join(terms,","),"]")
end

function solveprint(instance, solver)
    # Convert from cbf to our conic format
    (c, A, b, con_cones, var_cones, vartypes, sense, objoffset) = cbftompb(instance)
    if sense == :Max
        scale!(c, -1)
    end

    # Load, solve, and time
    m = MathProgBase.ConicModel(solver)
    timeall = time()
    MathProgBase.loadproblem!(m, c, A, b, con_cones, var_cones)
    MathProgBase.setvartype!(m, vartypes)
    MathProgBase.optimize!(m)
    timeall = time() - timeall
    timesolver = MathProgBase.getsolvetime(m)
    status = MathProgBase.status(m)

    x = []
    try
        x = MathProgBase.getsolution(m)
    end

    objval = NaN
    objbound = NaN
    try
        objval = MathProgBase.getobjval(m)
        if sense == :Max
            objval = -objval
        end
        objval += objoffset
    end
    try
        objbound = MathProgBase.getobjbound(m)
        if sense == :Max
            objbound = -objbound
        end
        objbound += objoffset
    end

    println("#STATUS# $status")
    println("#OBJVAL# $objval")
    println("#OBJBOUND# $objbound")
    println("#TIMESOLVER# $timesolver")
    println("#TIMEALL# $timeall")
    println("#SOLUTION# $(vec_to_string(x))")
end


solvermap = Dict(
    # OPTIONS MOSEK
    "PAJ_CBC_MOSEK" =>
    (["Cbc","Mosek"], quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap) end),
    "PAJ_NOPASS_CBC_MOSEK" =>
    (["Cbc","Mosek"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, pass_mip_sols=false) end),
    "PAJ_ROUND_CBC_MOSEK" =>
    (["Cbc","Mosek"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, round_mip_sols=true) end),
    "PAJ_NORELAX_CBC_MOSEK" =>
    (["Cbc","Mosek"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, solve_relax=false) end),
    "PAJ_NODIS_CBC_MOSEK" =>
    (["Cbc","Mosek"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, soc_disagg=false) end),
    "PAJ_NOSOCINIT_CBC_MOSEK" =>
    (["Cbc","Mosek"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, init_soc_inf=false, init_soc_one=false) end),
    "PAJ_SUBOPT-2-1_CBC_MOSEK" =>
    (["Cbc","Mosek"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=2, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.01, seconds=120)) end),
    "PAJ_SUBOPT-8-1_CBC_MOSEK" =>
    (["Cbc","Mosek"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=8, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.01, seconds=120)) end),
    "PAJ_SUBOPT-2-10_CBC_MOSEK" =>
    (["Cbc","Mosek"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=2, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.1, seconds=120)) end),
    "PAJ_SUBOPT-8-10_CBC_MOSEK" =>
    (["Cbc","Mosek"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=8, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.1, seconds=120)) end),

    # OPTIONS ECOS
    "PAJ_CBC_ECOS" =>
    (["Cbc","ECOS"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap) end),
    "PAJ_NOPASS_CBC_ECOS" =>
    (["Cbc","ECOS"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, pass_mip_sols=false) end),
    "PAJ_ROUND_CBC_ECOS" =>
    (["Cbc","ECOS"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, round_mip_sols=true) end),
    "PAJ_NORELAX_CBC_ECOS" =>
    (["Cbc","ECOS"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, solve_relax=false) end),
    "PAJ_NODIS_CBC_ECOS" =>
    (["Cbc","ECOS"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, soc_disagg=false) end),
    "PAJ_NOSOCINIT_CBC_ECOS" =>
    (["Cbc","ECOS"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, init_soc_inf=false, init_soc_one=false) end),
    "PAJ_SUBOPT-2-1_CBC_ECOS" =>
    (["Cbc","ECOS"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=2, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.01, seconds=120)) end),
    "PAJ_SUBOPT-8-1_CBC_ECOS" =>
    (["Cbc","ECOS"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=8, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.01, seconds=120)) end),
    "PAJ_SUBOPT-2-10_CBC_ECOS" =>
    (["Cbc","ECOS"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=2, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.1, seconds=120)) end),
    "PAJ_SUBOPT-8-10_CBC_ECOS" =>
    (["Cbc","ECOS"],quote PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=8, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.1, seconds=120)) end),

    # OPEN-SOURCE
    "BONMIN_OA" =>
    (["AmplNLWriter"],quote ConicNLPWrapper(nlp_solver=BonminNLSolver(["bonmin.algorithm=\"B-OA\"", "bonmin.time_limit=$tlim", "halt_on_ampl_error=yes", "bonmin.allowable_fraction_gap=$rgap", "bonmin.oa_log_level=1", "bonmin.bb_log_level=1"]), disaggregate_soc=false) end),
    "BONMIN_OADIS" =>
    (["AmplNLWriter"],quote ConicNLPWrapper(nlp_solver=BonminNLSolver(["bonmin.algorithm=\"B-OA\"", "bonmin.time_limit=$tlim", "halt_on_ampl_error=yes", "bonmin.allowable_fraction_gap=$rgap", "bonmin.oa_log_level=1", "bonmin.bb_log_level=1"]), disaggregate_soc=true) end),
    "BONMIN_BB" =>
    (["AmplNLWriter"],quote ConicNLPWrapper(nlp_solver=BonminNLSolver(["bonmin.algorithm=\"B-BB\"", "bonmin.time_limit=$tlim", "halt_on_ampl_error=yes", "bonmin.allowable_fraction_gap=$rgap", "bonmin.oa_log_level=1", "bonmin.bb_log_level=1"]), disaggregate_soc=false) end),

    # NON-COMMERCIAL
    "PAJ_SCIP_MOSEK" =>
    (["SCIP","Mosek"],quote PajaritoSolver(mip_solver=SCIPSolver("display/verblevel", 0, "limits/gap", 0.0, "limits/time", tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap) end),
    "PAJ_MSD_SCIP_MOSEK" =>
    (["SCIP","Mosek"],quote PajaritoSolver(mip_solver=SCIPSolver("display/verblevel", 0, "limits/gap", rgap, "limits/time", tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true) end),
    "PAJ_SCIP_ECOS" =>
    (["SCIP","ECOS"],quote PajaritoSolver(mip_solver=SCIPSolver("display/verblevel", 0, "limits/gap", 0.0, "limits/time", tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap) end),
    "PAJ_MSD_SCIP_ECOS" =>
    (["SCIP","ECOS"],quote PajaritoSolver(mip_solver=SCIPSolver("display/verblevel", 0, "limits/gap", rgap, "limits/time", tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true) end),
    "SCIP_MISOCP" =>
    (["SCIP"],quote ConicNLPWrapper(nlp_solver=SCIPSolver("display/verblevel", 1, "limits/gap", rgap, "limits/time", tlim), soc_as_quadratic=true, disaggregate_soc=false) end),
    "SCIP_MISOCPDIS" =>
    (["SCIP"],quote ConicNLPWrapper(nlp_solver=SCIPSolver("display/verblevel", 1, "limits/gap", rgap, "limits/time", tlim), soc_as_quadratic=true, disaggregate_soc=true) end),

    # COMMERCIAL
    # CPX_PARAM_EPGAP=0., CPX_PARAM_EPINT=1e-8, CPX_PARAM_EPRHS=1e-8,
    "PAJ_CPLEX_MOSEK" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=0.), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap) end),
    "PAJ_MSD_CPLEX_0GAP_MOSEK" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=0.), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true) end),
    "PAJ_NEW_MSD_CPLEX_MOSEK" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=rgap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true) end),

    "PAJ_CPLEX_tols_MOSEK" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_EPINT=1e-8,CPX_PARAM_EPRHS=1e-8,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=0.), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap) end),
    "PAJ_MSD_CPLEX_tols_0GAP_MOSEK" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_EPINT=1e-8,CPX_PARAM_EPRHS=1e-8,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=0.), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true) end),
    "PAJ_NEW_MSD_CPLEX_tols_MOSEK" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_EPINT=1e-8,CPX_PARAM_EPRHS=1e-8,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=rgap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true) end),

    "PAJ_PRAS_CPLEX_tols_MOSEK" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_EPINT=1e-8,CPX_PARAM_EPRHS=1e-8,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=0.), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cuts_assist=true) end),
    "PAJ_PRAS_MSD_CPLEX_tols_0GAP_MOSEK" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_EPINT=1e-8,CPX_PARAM_EPRHS=1e-8,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=0.), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true, prim_cuts_assist=true) end),
    "PAJ_PRAS_NEW_MSD_CPLEX_tols_MOSEK" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_EPINT=1e-8,CPX_PARAM_EPRHS=1e-8,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=rgap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true, prim_cuts_assist=true) end),



    "PAJ_CPLEX_ECOS" =>
    (["CPLEX","ECOS"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=0.), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap) end),
    "PAJ_MSD_CPLEX_ECOS" =>
    (["CPLEX","ECOS"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=rgap), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true) end),
    "CPLEX_MISOCP" =>
    (["CPLEX"],quote CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_SCRIND=1,CPX_PARAM_EPGAP=rgap) end),
    "PAJ_CPLEX_MOSEK_tols" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=0.), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120., INTPNT_CO_TOL_REL_GAP=1e-9, INTPNT_CO_TOL_DFEAS=1e-10), log_level=logl, timeout=tlim, rel_gap=rgap) end),
    "PAJ_CPLEX_tols_MOSEK" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_EPINT=1e-8,CPX_PARAM_EPRHS=1e-8,CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=0.), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap) end),
    "PAJ_CPLEX_tols_MOSEK_tols" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_EPINT=1e-8,CPX_PARAM_EPRHS=1e-8,CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=0.), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120., INTPNT_CO_TOL_REL_GAP=1e-9, INTPNT_CO_TOL_DFEAS=1e-10), log_level=logl, timeout=tlim, rel_gap=rgap) end),
    "PAJ_MSD_CPLEX_tols_MOSEK_tols" =>
    (["CPLEX","Mosek"],quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_EPINT=1e-8,CPX_PARAM_EPRHS=1e-8,CPX_PARAM_THREADS=1,CPX_PARAM_TILIM=tlim,CPX_PARAM_SCRIND=0,CPX_PARAM_EPGAP=rgap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120., INTPNT_CO_TOL_REL_GAP=1e-9, INTPNT_CO_TOL_DFEAS=1e-10), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true) end),

    # NEW MSD WITH CPLEX ONLY
)


function getsolver(solvername, tlim, logl, rgap)
    packages, solvername = solvermap[solvername]
    for p in packages
        eval(parse("using $p"))
    end
    return eval(solvername)
end



# main script
# usage: run.jl SOLVERNAME TIMELIMIT DATAFOLDER INSTANCENAME

@assert length(ARGS) >= 3

# Save process ID for runmeta.jl
open("mypid", "w") do fd
    print(fd, getpid())
end

logl = 2
rgap = 1e-5

solvername = ARGS[1]
tlim = parse(Float64, ARGS[2])
datafolder = ARGS[3]

# Force Pajarito to compile on a small instance for the solver to avoid measuring compilation time, keep quiet
if startswith(solvername, "PAJ")
    TT = STDOUT
    open("/dev/null", "w") do fd
        redirect_stdout(fd)
        instance = readcbfdata(joinpath(datafolder, "estein4_A.cbf.gz"))
        solver = getsolver(solvername, 20., 0, rgap)
        solveprint(instance, solver)
    end
    redirect_stdout(TT)
end

instancename = ARGS[4]

# Interpret instance data as cbf
instance = readcbfdata(joinpath(datafolder, instancename))

solver = getsolver(solvername, tlim, logl, rgap)

println("#SOLVERNAME# $solvername")
println("#SOLVER# $solver")
println("#INSTANCE# $instancename")
println("#TIMELIMIT# $tlim")

# Attempt to solve, print solve info
timesolve = time()
try
    solveprint(instance, solver)
catch e
    println("#ERROR# $e")
end
