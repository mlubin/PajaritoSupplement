using ConicBenchmarkUtilities
using Mosek
using MathProgBase

# Usage: process_output.jl [--noconicsolve] RESULTFOLDERS... OUTPUT.csv

@assert length(ARGS) >= 2
NOCONIC = false
if ARGS[1] == "--noconicsolve"
    NOCONIC = true
    shift!(ARGS)
end
resultfiles = []
for i in 1:length(ARGS)-1
    append!(resultfiles,[joinpath(pwd(),ARGS[i],f) for f in readdir(joinpath(pwd(), ARGS[i]))])
end

fd = open(joinpath(pwd(), ARGS[end]), "w")

# Process into a CSV file with columns:
println(fd,"solver,instance,sense,timelimit,status,objval_reported,objbound,calc_objgap,calc_status,solvertime,totaltime,nodecount,filename,rel_objval_error,max_linear_violation,max_soc_violation,max_socrot_violation,max_exp_violation,max_psd_violation,max_int_violation,validator_status,validator_relobjdiff,conic_subproblem_count,conic_optimal_count,conic_infeasible_count,conic_relaxation_status,conic_subproblem_time,conic_relaxation_time,mip_subproblem_time,iteration_count")

# From instance name to file name
function find_instance(name)
    instances = joinpath(dirname(@__FILE__),"..","cbfs")
    try
        match = "$name.*"
        f = readstring(`find $instances -name $match`)
        if length(split(f,"\n")) == 2
            return convert(String,chomp(f))
        end
    end
    return ""
end

function make_smat(svec::Vector{Float64})
    dim = Int(sqrt(1/4+2length(svec)) - 1/2)
    smat = Array{Float64}(dim,dim)
    k = 1

    for i in 1:dim, j in i:dim
        if i == j
            smat[i,j] = svec[k]
        else
            smat[i,j] = (1/sqrt(2))*svec[k]
        end
        k += 1
    end

    return smat
end

function violation_cone(subvec,cone)
    if cone == :Zero
        return :Linear, maximum(abs,subvec)
    elseif cone == :NonNeg
        return :Linear, -minimum(min.(subvec, 0.))
    elseif cone == :NonPos
        return :Linear, maximum(max.(subvec, 0.))
    elseif cone == :SOC
        return :SOC, max(0., vecnorm(subvec[2:end]) - subvec[1])
    elseif cone == :SOCRotated
        # (y,z,x) in RSOC <=> (sqrt2inv*(y+z),sqrt2inv*(-y+z),x) in SOC
        return :SOCRotated, max(0., sqrt(1/2*(subvec[1] - subvec[2])^2 + sum(abs2, subvec[3:end])) - 1/sqrt(2)*(subvec[1] + subvec[2]))
    elseif cone == :ExpPrimal
        return :Exp, max(subvec[2]*exp(subvec[1]/subvec[2]) - subvec[3],0)
    elseif cone == :Free
        return :Linear, 0.0
    elseif cone == :SDP
        smat = make_smat(subvec)
        return :PSD, -min(eigmin(Symmetric(smat)),0.0)
    else
        error("Unrecognized cone $cone")
    end
end


function compute_violations(dat, solution)
    c, A, b, con_cones, var_cones, vartypes, sense, objoffset = cbftompb(dat)

    if length(solution) > length(c)
        println("Solution is too long")
    end
    @assert length(solution) >= length(c)
    solution = solution[1:length(c)]
    objval = dot(c,solution)

    y = b - A*solution
    linear_violation = -Inf
    soc_violation = -Inf
    socrot_violation = -Inf
    exp_violation = -Inf
    psd_violation = -Inf
    for (cones,x) in [(var_cones,solution),(con_cones,y)]
        for (cone, idx) in cones
            t, viol = violation_cone(x[idx],cone)
            if t == :Linear
                linear_violation = max(linear_violation,viol)
            elseif t == :SOC
                soc_violation = max(soc_violation,viol)
            elseif t == :SOCRotated
                socrot_violation = max(socrot_violation,viol)
            elseif t == :Exp
                exp_violation = max(exp_violation,viol)
            elseif t == :PSD
                psd_violation = max(psd_violation,viol)
            end
        end
    end

    int_violation = 0.0
    for i in 1:length(vartypes)
        if vartypes[i] == :Int || vartypes[i] == :Bin
            int_violation = max(int_violation, abs(solution[i]-round(solution[i])))
        end
    end

    return objval, linear_violation, soc_violation, socrot_violation, exp_violation, psd_violation, int_violation
end

function validate_with_conic_solver(dat, solution)
    c, A, b, con_cones, var_cones, vartypes, sense, objoffset = cbftompb(dat)
    @assert objoffset == 0.0

    if sense == :Max
        c = -c
    end

    con_cones = copy(con_cones)
    I_eq = Int[]
    J_eq = Int[]
    b_eq = Float64[]
    intcount = 1
    for i in 1:length(vartypes)
        if vartypes[i] == :Int
            push!(I_eq,intcount)
            intcount += 1
            push!(J_eq,i)
            push!(b_eq, round(solution[i]))
        else
            @assert vartypes[i] == :Cont
        end
    end
    con_cones = vcat(con_cones, (:Zero,size(A,1)+1:size(A,1)+intcount-1))
    A = vcat(A, sparse(I_eq,J_eq,ones(length(I_eq)),length(I_eq),length(c)))
    b = vcat(b, b_eq)

    m = MathProgBase.ConicModel(MosekSolver(LOG=0))
    MathProgBase.loadproblem!(m, c, A, b, con_cones, var_cones)
    MathProgBase.optimize!(m)
    status = MathProgBase.status(m)
    if status == :Optimal
        objval = MathProgBase.getobjval(m)
        if sense == :Max
            objval *= -1
        end
    else
        objval = NaN
    end
    return status, objval
end

for (cnt,filename) in enumerate(resultfiles)
    if startswith(basename(filename), ".") || contains(filename,"META")
        continue
    end
    println("$cnt of $(length(resultfiles)): $(basename(filename))")

    solver = split(basename(filename),".")[1]
    # instance name may have '.' in it
    instance = join(split(basename(filename),".")[2:end-1],".")
    instance = string(instance,".cbf")

    #solver = " "
    #instance = " "
    #sense = " "
    timelimit = " "
    status = " "
    objval = NaN
    objbound = NaN
    solvertime = " "
    totaltime = " "
    nodecount = " "
    rel_objval_error = " "
    linear_violation = " "
    soc_violation = " "
    socrot_violation = " "
    exp_violation = " "
    psd_violation = " "
    int_violation = " "
    validator_status = " "
    validator_relobjdiff = " "
    conic_subproblem_count = " "
    conic_optimal_count = " "
    conic_infeasible_count = " "
    conic_relaxation_status = " "
    conic_subproblem_time = " "
    conic_relaxation_time = " "
    mip_subproblem_time = " "
    iteration_count = " "
    solution = []

    for line in eachline(filename)
        if startswith(line, "#SOLVERNAME#")
            @assert solver == split(line)[2]
        elseif startswith(line, "#INSTANCE#")
            inst = split(line)[2]
            if endswith(inst, ".gz")
                @assert instance == inst[1:end-3]
            else
                @assert instance == inst
            end
        elseif startswith(line, "#TIMELIMIT#")
            timelimit = split(line)[2]
        elseif startswith(line, "#STATUS#")
            status = split(line)[2]
        elseif startswith(line, "#OBJVAL#")
            objval = parse(Float64,split(line)[2])
        elseif startswith(line, "#OBJBOUND#")
            objbound = parse(Float64,split(line)[2])
        elseif startswith(line, "#TIMESOLVER#")
            solvertime = split(line)[2]
        elseif startswith(line, "#TIMEALL#")
            totaltime = split(line)[2]
        elseif startswith(line, "#NODECOUNT#")
            nodecount = split(line)[2]
        elseif startswith(line, "#SOLUTION#")
            solutionvec = split(line)[2]
            if startswith(solutionvec,'[') && endswith(solutionvec,']') && !startswith(solutionvec, "[]")
                solution = [parse(Float64,x) for x in split(solutionvec[2:end-1],',')]
            end
        elseif startswith(line, " - Iterations           =")
            iteration_count = split(line)[4]
        elseif startswith(line, " -- Conic subproblems   =")
            conic_subproblem_count = split(line)[5]
        elseif startswith(line, " --- Optimal            =")
            conic_optimal_count = split(line)[4]
        elseif startswith(line, " --- Infeasible         =")
            conic_infeasible_count = split(line)[4]
        elseif startswith(line, " - Relaxation status    =")
            conic_relaxation_status = split(line)[5]
        elseif startswith(line, " -- Solve subproblems   =")
            conic_subproblem_time = split(line)[5]
        elseif startswith(line, " -- Solve relaxation    =")
            conic_relaxation_time = split(line)[5]
        elseif startswith(line, " -- Solve MIP models    =") || startswith(line, " -- MIP solver driving  =")
            mip_subproblem_time = split(line)[6]
        end
    end

    instancefile = find_instance(instance)
    dat = readcbfdata(instancefile)
    sense = string(dat.sense)
    calc_objgap = NaN
    calc_status = "other"

    if length(solution) > 0 && all(isfinite,solution)
        objval_sol, linear_violation, soc_violation, socrot_violation, exp_violation, psd_violation, int_violation = compute_violations(dat,solution)
        if !NOCONIC
            validator_status, validator_objval = validate_with_conic_solver(dat,solution)
            validator_relobjdiff = abs(objval_sol - validator_objval)/(abs(objval_sol) + 1e-5)
            rel_objval_error = abs(objval_sol - objval)/(abs(objval) + 1e-5)
        end

        if isfinite(objbound)
            calc_objgap = (objval_sol - objbound) / (abs(objval_sol) + 1e-5)
            if calc_objgap <= 1.25e-5
                calc_status = "conv"
            else
                calc_status = "not conv"
            end
        end
    end

    if startswith(solver, "BONMIN")
        # Trust what bonmin says (give it benefit of the doubt because we can't get bounds)
        if status == "Optimal"
            calc_status = "conv"
        elseif status == "Suboptimal"
            calc_status = "not conv"
        end
    end

    if status == "UserLimit" && (!startswith(solver, "SCIP") || calc_status == "not conv")
        # SCIP seems not to be stopping with our rel gap tolerance, so if it satisfies at end, accept
        calc_status = "limit"
    end

    println(fd,
"$solver,$instance,$sense,$timelimit,$status,$objval,$objbound,$calc_objgap,$calc_status,$solvertime,$totaltime,$nodecount,$(basename(filename)),$rel_objval_error,$linear_violation,$soc_violation,$socrot_violation,$exp_violation,$psd_violation,$int_violation,$validator_status,$validator_relobjdiff,$conic_subproblem_count,$conic_optimal_count,$conic_infeasible_count,$conic_relaxation_status,$conic_subproblem_time,$conic_relaxation_time,$mip_subproblem_time,$iteration_count")
end

close(fd)
