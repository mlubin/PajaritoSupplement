
# Usage: run.jl SOLVERNAME TIMELIMIT DATAFOLDER INSTANCENAME

using ConicBenchmarkUtilities
using Pajarito
using ConicNonlinearBridge


# Print with full precision
function vec_to_string(v)
    terms = String[]
    for x in v
        b = IOBuffer()
        show(b, x)
        push!(terms, String(take!(b)))
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
    if !all(t->t==:Cont, vartypes)
        MathProgBase.setvartype!(m, vartypes)
    end
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
    nodecount = NaN
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
    try
        nodecount = MathProgBase.getnodecount(m)
    end

    println("#STATUS# $status")
    println("#OBJVAL# $objval")
    println("#OBJBOUND# $objbound")
    println("#NODECOUNT# $nodecount")
    println("#TIMESOLVER# $timesolver")
    println("#TIMEALL# $timeall")
    println("#SOLUTION# $(vec_to_string(x))")
end


solvermap = Dict(
    # BONMIN
    "BONMIN_OA" =>
    (["AmplNLWriter"], quote ConicNLPWrapper(
    nlp_solver=BonminNLSolver(["bonmin.algorithm=\"B-OA\"", "bonmin.time_limit=$tlim", "halt_on_ampl_error=yes", "bonmin.allowable_fraction_gap=$rgap", "bonmin.oa_log_level=1", "bonmin.bb_log_level=1"]),
    disaggregate_soc=false,
    ) end),

    "BONMIN_OADIS" =>
    (["AmplNLWriter"], quote ConicNLPWrapper(
    nlp_solver=BonminNLSolver(["bonmin.algorithm=\"B-OA\"", "bonmin.time_limit=$tlim", "halt_on_ampl_error=yes", "bonmin.allowable_fraction_gap=$rgap", "bonmin.oa_log_level=1", "bonmin.bb_log_level=1"]),
    disaggregate_soc=true,
    ) end),

    "BONMIN_BB" =>
    (["AmplNLWriter"], quote ConicNLPWrapper(
    nlp_solver=BonminNLSolver(["bonmin.algorithm=\"B-BB\"", "bonmin.time_limit=$tlim", "halt_on_ampl_error=yes", "bonmin.allowable_fraction_gap=$rgap", "bonmin.oa_log_level=1", "bonmin.bb_log_level=1"]),
    disaggregate_soc=false,
    ) end),

    # SCIP
    "SCIP_MISOCP" =>
    (["SCIP"], quote SCIPSolver(
    "limits/gap", rgap, "numerics/feastol", tol_feas, "limits/time", tlim,
    ) end),

    # CPLEX
    "CPLEX_MISOCP" =>
    (["CPLEX"], quote CplexSolver(
    CPX_PARAM_THREADS=1, CPX_PARAM_TILIM=tlim, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap,
    ) end),

    # Paj CBC
    "PAJ_CBC_ECOS" =>
    (["Cbc","ECOS"], quote PajaritoSolver(
    mip_solver=CbcSolver(logLevel=0, integerTolerance=tol_int, primalTolerance=tol_feas, ratioGap=tol_gap, check_warmstart=false),
    cont_solver=ECOSSolver(verbose=false),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    ) end),

    # Paj GLPK
    "PAJ_GLPK_ECOS" =>
    (["GLPKMathProgInterface","ECOS"], quote PajaritoSolver(
    mip_solver=GLPKSolverMIP(msg_lev=GLPK.MSG_OFF, tol_int=tol_int, tol_bnd=tol_feas, mip_gap=tol_gap, presolve=true),
    cont_solver=ECOSSolver(verbose=false),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    ) end),

    # Paj CPLEX
    "PAJ_CPLEX_sep" =>
    (["CPLEX"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    prim_cuts_only=true, solve_relax=false, solve_subp=false,
    ) end),

    "PAJ_CPLEX_msd_sep" =>
    (["CPLEX"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    mip_solver_drives=true,
    prim_cuts_only=true, solve_relax=false, solve_subp=false,
    ) end),

    # Paj CPLEX MOSEK

    # Iter
    "PAJ_CPLEX_MOSEK" =>
    (["CPLEX","Mosek"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap),
    cont_solver=MosekSolver(LOG=0, NUM_THREADS=1),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    ) end),

    "PAJ_CPLEX_MOSEK_subponly" =>
    (["CPLEX","Mosek"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap),
    cont_solver=MosekSolver(LOG=0, NUM_THREADS=1),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    prim_cuts_assist=false,
    ) end),

    "PAJ_CPLEX_MOSEK_noscale" =>
    (["CPLEX","Mosek"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap),
    cont_solver=MosekSolver(LOG=0, NUM_THREADS=1),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    scale_subp_cuts=false,
    ) end),

    "PAJ_CPLEX_MOSEK_nopreslv" =>
    (["CPLEX","Mosek"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap, CPX_PARAM_PREIND=0),
    cont_solver=MosekSolver(LOG=0, NUM_THREADS=1),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    ) end),

    "PAJ_CPLEX_MOSEK_noscale_nopreslv" =>
    (["CPLEX","Mosek"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap, CPX_PARAM_PREIND=0),
    cont_solver=MosekSolver(LOG=0, NUM_THREADS=1),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    scale_subp_cuts=false,
    ) end),

    "PAJ_CPLEX_MOSEK_noinit" =>
    (["CPLEX","Mosek"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap),
    cont_solver=MosekSolver(LOG=0, NUM_THREADS=1),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    init_soc_one=false, init_soc_inf=false, init_exp=false, init_sdp_lin=false, init_sdp_soc=false,
    ) end),

    # MSD
    "PAJ_CPLEX_MOSEK_msd" =>
    (["CPLEX","Mosek"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap),
    cont_solver=MosekSolver(LOG=0, NUM_THREADS=1),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    mip_solver_drives=true,
    ) end),

    "PAJ_CPLEX_MOSEK_msd_subponly" =>
    (["CPLEX","Mosek"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap),
    cont_solver=MosekSolver(LOG=0, NUM_THREADS=1),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    mip_solver_drives=true,
    prim_cuts_assist=false,
    ) end),

    "PAJ_CPLEX_MOSEK_msd_noscale" =>
    (["CPLEX","Mosek"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap),
    cont_solver=MosekSolver(LOG=0, NUM_THREADS=1),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    mip_solver_drives=true,
    scale_subp_cuts=false,
    ) end),

    "PAJ_CPLEX_MOSEK_msd_nopreslv" =>
    (["CPLEX","Mosek"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap,
    CPX_PARAM_PREIND=0),
    cont_solver=MosekSolver(LOG=0, NUM_THREADS=1),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    mip_solver_drives=true,
    ) end),

    "PAJ_CPLEX_MOSEK_msd_noscale_nopreslv" =>
    (["CPLEX","Mosek"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap,
    CPX_PARAM_PREIND=0),
    cont_solver=MosekSolver(LOG=0, NUM_THREADS=1),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    mip_solver_drives=true,
    scale_subp_cuts=false,
    ) end),

    "PAJ_CPLEX_MOSEK_msd_noinit" =>
    (["CPLEX","Mosek"], quote PajaritoSolver(
    mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap),
    cont_solver=MosekSolver(LOG=0, NUM_THREADS=1),
    log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    mip_solver_drives=true,
    init_soc_one=false, init_soc_inf=false, init_exp=false, init_sdp_lin=false, init_sdp_soc=false,
    ) end),




    # Iter
    # "PAJ_CPLEX_MOSEK_dualonly" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, prim_cuts_assist=false) end),
    # "PAJ_CPLEX_MOSEK_dualonlynoscale" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, prim_cuts_assist=false, scale_subp_cuts=false) end),
    # "PAJ_CPLEX_MOSEK_dualonlynopresolve" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap, CPX_PARAM_PREIND=0), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, prim_cuts_assist=false) end),
    # "PAJ_CPLEX_MOSEK_dualonlynoscalenopresolve" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap, CPX_PARAM_PREIND=0), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, prim_cuts_assist=false, scale_subp_cuts=false) end),
    # "PAJ_CPLEX_MOSEK" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas) end),
    # "PAJ_CPLEX_MOSEK_primonlynorelax" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, prim_cuts_only=true, solve_relax=false) end),
    #
    # # "PAJ_CPLEX_MOSEK_noconic" =>
    # # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas,
    # prim_cuts_only=true, solve_relax=false, solve_subp=false) end),
    #
    # # MSD
    # "PAJ_CPLEX_MOSEK_msddualonly" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, mip_solver_drives=true, use_mip_starts=true, prim_cuts_assist=false) end),
    # "PAJ_CPLEX_MOSEK_msddualonlynoscale" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, mip_solver_drives=true, use_mip_starts=true, prim_cuts_assist=false, scale_subp_cuts=false) end),
    # "PAJ_CPLEX_MOSEK_msd" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, mip_solver_drives=true, use_mip_starts=true) end),
    # "PAJ_CPLEX_MOSEK_msdprimonlynorelax" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, mip_solver_drives=true, use_mip_starts=true, prim_cuts_only=true, solve_relax=false) end),
    #
    # # "PAJ_CPLEX_MOSEK_msdnoconic" =>
    # # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, mip_solver_drives=true, use_mip_starts=true, prim_cuts_only=true, solve_relax=false, solve_subp=false) end),
    # #should maybe not use mip starts on msdnoconic! but then this helps that solver in comparisons because heur cb wastes time! could turn off on msd?
    #
    # # Other
    # "PAJ_CPLEX_MOSEK_subopt" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, mip_subopt_count=5, mip_subopt_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=0.01, CPX_PARAM_TILIM=120.)) end),
    # "PAJ_CPLEX_MOSEK_msdnostarts" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, mip_solver_drives=true, use_mip_starts=false) end),

    # Portfolio tests solvers

    # CPLEX iter - no conic
    # "PAJ_CPLEX_noconic" =>
    # (["CPLEX"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, prim_cuts_only=true, solve_relax=false, solve_subp=false) end),
    # "PAJ_CPLEX_noconic_noinit" =>
    # (["CPLEX"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, prim_cuts_only=true, solve_relax=false, solve_subp=false, init_soc_one=false, init_soc_inf=false, init_exp=false, init_sdp_lin=false) end),
    #
    # # CPLEX MSD - no conic
    # "PAJ_CPLEX_noconic_msd" =>
    # (["CPLEX"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, prim_cuts_only=true, solve_relax=false, solve_subp=false, mip_solver_drives=true, use_mip_starts=false) end),
    # "PAJ_CPLEX_noconic_noinit_msd" =>
    # (["CPLEX"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, prim_cuts_only=true, solve_relax=false, solve_subp=false, mip_solver_drives=true, use_mip_starts=false, init_soc_one=false, init_soc_inf=false, init_exp=false, init_sdp_lin=false) end),
    #
    # # CPLEX iter - primal assist
    # "PAJ_CPLEX_MOSEK" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas) end),
    # "PAJ_CPLEX_ECOS" =>
    # (["CPLEX","ECOS"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas) end),
    # "PAJ_CPLEX_SCS" =>
    # (["CPLEX","SCS"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), cont_solver=SCSSolver(verbose=0, warm_start=true, eps=1e-4), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas) end),




    # "PAJ_CPLEX_ECOS_msd" =>
    # (["CPLEX","ECOS"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap), cont_solver=ECOSSolver(verbose=false), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, mip_solver_drives=true, use_mip_starts=true) end),
    # "PAJ_CPLEX_SCS_msd" =>
    # (["CPLEX","SCS"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=1, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=rgap), cont_solver=SCSSolver(verbose=0, warm_start=true, eps=1e-4), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, mip_solver_drives=true, use_mip_starts=true) end),
    #
    # # CPLEX iter - noscale/presolve
    # "PAJ_CPLEX_MOSEK_noscale" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, scale_subp_cuts=false) end),
    # "PAJ_CPLEX_MOSEK_nopresolve" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_PREIND=0, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, scale_subp_cuts=true) end),
    # "PAJ_CPLEX_MOSEK_noscale_nopresolve" =>
    # (["CPLEX","Mosek"], quote PajaritoSolver(mip_solver=CplexSolver(CPX_PARAM_THREADS=1, CPX_PARAM_PREIND=0, CPX_PARAM_SCRIND=0, CPX_PARAM_EPINT=tol_int, CPX_PARAM_EPRHS=tol_feas, CPX_PARAM_EPGAP=tol_gap), cont_solver=MosekSolver(LOG=0, NUM_THREADS=1), log_level=logl, timeout=tlim, rel_gap=rgap, prim_cut_feas_tol=tol_feas, scale_subp_cuts=false) end),
)


function getsolver(solvername, tlim, logl, rgap)
    packages, solvername = solvermap[solvername]
    for p in packages
        eval(parse("using $p"))
    end
    return eval(solvername)
end


@assert length(ARGS) >= 3

# Save process ID for runmeta.jl
open("mypid", "w") do fd
    print(fd, getpid())
end

# General options
logl = 3
rgap = 1e-5
tol_conic = 1e-6

# Pajarito MIP solver options
tol_int = 1e-8
tol_feas = 1e-7
tol_gap = 0.

solvername = ARGS[1]
tlim = parse(Float64, ARGS[2])
datafolder = ARGS[3]

# Force Pajarito to compile on a small instance for the solver to avoid measuring compilation time, keep quiet
if startswith(solvername, "PAJ")
    TT = STDOUT
    solver = getsolver(solvername, 60., 3, rgap)
    open("/dev/null", "w") do fd
        redirect_stdout(fd)
        instance = readcbfdata(joinpath(datafolder, "compile.cbf.gz"))
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
# try
    solveprint(instance, solver)
# catch e
    # println("#ERROR# $e")
# end
