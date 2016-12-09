using ConicBenchmarkUtilities
using Pajarito
using ECOS
using ConicIP
using Mosek
using Gurobi
using Cbc
using SCIP
using ConicNonlinearBridge
using AmplNLWriter


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
    println("#SOLUTION# $x")
end


function getsolver(solvername, tlim, logl, rgap)
    solvermap = Dict(
        # OPTIONS MOSEK
        "PAJ_CBC_MOSEK" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap),
        "PAJ_NOPASS_CBC_MOSEK" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, pass_mip_sols=false),
        "PAJ_ROUND_CBC_MOSEK" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, round_mip_sols=true),
        "PAJ_NORELAX_CBC_MOSEK" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, solve_relax=false),
        "PAJ_NODIS_CBC_MOSEK" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, soc_disagg=false),
        "PAJ_NOSOCINIT_CBC_MOSEK" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, init_soc_inf=false, init_soc_one=false),
        "PAJ_SUBOPT-2-1_CBC_MOSEK" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=2, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.01, seconds=120)),
        "PAJ_SUBOPT-8-1_CBC_MOSEK" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=8, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.01, seconds=120)),
        "PAJ_SUBOPT-2-10_CBC_MOSEK" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=2, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.1, seconds=120)),
        "PAJ_SUBOPT-8-10_CBC_MOSEK" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=8, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.1, seconds=120)),

        # OPTIONS ECOS
        "PAJ_CBC_ECOS" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap),
        "PAJ_NOPASS_CBC_ECOS" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, pass_mip_sols=false),
        "PAJ_ROUND_CBC_ECOS" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, round_mip_sols=true),
        "PAJ_NORELAX_CBC_ECOS" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, solve_relax=false),
        "PAJ_NODIS_CBC_ECOS" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, soc_disagg=false),
        "PAJ_NOSOCINIT_CBC_ECOS" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, init_soc_inf=false, init_soc_one=false),
        "PAJ_SUBOPT-2-1_CBC_ECOS" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=2, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.01, seconds=120)),
        "PAJ_SUBOPT-8-1_CBC_ECOS" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=8, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.01, seconds=120)),
        "PAJ_SUBOPT-2-10_CBC_ECOS" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=2, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.1, seconds=120)),
        "PAJ_SUBOPT-8-10_CBC_ECOS" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, mip_subopt_count=8, mip_subopt_solver=CbcSolver(logLevel=0, ratioGap=0.1, seconds=120)),

        # OPEN-SOURCE
        "PAJ_CBC_CIP" =>
        PajaritoSolver(mip_solver=CbcSolver(logLevel=0, ratioGap=0., seconds=tlim), cont_solver=ConicIPSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap),
        "BONMIN_OA" =>
        ConicNLPWrapper(nlp_solver=BonminNLSolver(["bonmin.algorithm=\"B-OA\"", "bonmin.time_limit=$tlim", "halt_on_ampl_error=yes", "bonmin.allowable_fraction_gap=$rgap", "bonmin.oa_log_level=1", "bonmin.bb_log_level=1"]), disaggregate_soc=false),
        "BONMIN_OADIS" =>
        ConicNLPWrapper(nlp_solver=BonminNLSolver(["bonmin.algorithm=\"B-OA\"", "bonmin.time_limit=$tlim", "halt_on_ampl_error=yes", "bonmin.allowable_fraction_gap=$rgap", "bonmin.oa_log_level=1", "bonmin.bb_log_level=1"]), disaggregate_soc=true),
        "BONMIN_BB" =>
        ConicNLPWrapper(nlp_solver=BonminNLSolver(["bonmin.algorithm=\"B-BB\"", "bonmin.time_limit=$tlim", "halt_on_ampl_error=yes", "bonmin.allowable_fraction_gap=$rgap", "bonmin.oa_log_level=1", "bonmin.bb_log_level=1"]), disaggregate_soc=false),

        # NON-COMMERCIAL
        "PAJ_SCIP_MOSEK" =>
        PajaritoSolver(mip_solver=SCIPSolver("display/verblevel", 0, "limits/gap", 0.0, "limits/time", tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap),
        "PAJ_MSD_SCIP_MOSEK" =>
        PajaritoSolver(mip_solver=SCIPSolver("display/verblevel", 0, "limits/gap", rgap, "limits/time", tlim), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true),
        "PAJ_SCIP_ECOS" =>
        PajaritoSolver(mip_solver=SCIPSolver("display/verblevel", 0, "limits/gap", 0.0, "limits/time", tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap),
        "PAJ_MSD_SCIP_ECOS" =>
        PajaritoSolver(mip_solver=SCIPSolver("display/verblevel", 0, "limits/gap", rgap, "limits/time", tlim), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true),
        "SCIP_MISOCP" =>
        ConicNLPWrapper(nlp_solver=SCIPSolver("display/verblevel", 1, "limits/gap", rgap, "limits/time", tlim), soc_as_quadratic=true, disaggregate_soc=false),
        "SCIP_MISOCPDIS" =>
        ConicNLPWrapper(nlp_solver=SCIPSolver("display/verblevel", 1, "limits/gap", rgap, "limits/time", tlim), soc_as_quadratic=true, disaggregate_soc=true),

        # COMMERCIAL
        "PAJ_GUROBI_MOSEK" =>
        PajaritoSolver(mip_solver=GurobiSolver(OutputFlag=0, Threads=1, TimeLimit=tlim, MIPGap=0.), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap),
        "PAJ_MSD_GUROBI_MOSEK" =>
        PajaritoSolver(mip_solver=GurobiSolver(OutputFlag=0, Threads=1, TimeLimit=tlim, MIPGap=rgap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1, OPTIMIZER_MAX_TIME=120.), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true),
        "PAJ_GUROBI_ECOS" =>
        PajaritoSolver(mip_solver=GurobiSolver(OutputFlag=0, Threads=1, TimeLimit=tlim, MIPGap=0.), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap),
        "PAJ_MSD_GUROBI_ECOS" =>
        PajaritoSolver(mip_solver=GurobiSolver(OutputFlag=0, Threads=1, TimeLimit=tlim, MIPGap=rgap), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, mip_solver_drives=true),
        "GUROBI_MISOCP" =>
        GurobiSolver(OutputFlag=1, Threads=1, TimeLimit=tlim, MIPGap=rgap),
        "MOSEK_MISOCP" =>
        MosekSolver(LOG=1, NUM_THREADS=1, OPTIMIZER_MAX_TIME=tlim, MIO_TOL_REL_GAP=rgap),
    )

    return deepcopy(solvermap[solvername])
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
        instance = readcbfdata(joinpath(datafolder, "estein", "estein4_A.cbf.gz"))
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
println("#FILENAME# $(basename(instancename))")
println("#INSTANCE# $(instance.name)")
println("#TIMELIMIT# $tlim")

# Attempt to solve, print solve info
timesolve = time()
try
    solveprint(instance, solver)
catch e
    println("#ERROR# $e")
end
