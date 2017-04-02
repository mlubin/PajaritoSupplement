using ConicBenchmarkUtilities
using Mosek
using MathProgBase

resultfiles = readdir(joinpath(pwd(), ARGS[1]))

fd = open(joinpath(pwd(), ARGS[2]), "w")

# process into a CSV file with columns:
println(fd,"solver,instance,status,objval_reported,objbound,solvertime,totaltime,filename,objval_solution,max_linear_violation,max_soc_violation,max_socrot_violation,max_int_violation,validator_status,validator_objval")

# from instance name to file name
function find_instance(name)
    instances = joinpath(dirname(@__FILE__),"..","instancedata")
    try
        match = "$name.*"
        f = readstring(`find $instances -name $match`)
        if length(split(f,"\n")) == 2
            return chomp(f)
        end
    end
    return ""
end

function violation_cone(subvec,cone)
    if cone == :Zero
        return :Linear, maxabs(subvec)
    elseif cone == :NonNeg
        return :Linear, -minimum(min.(subvec, 0.))
    elseif cone == :NonPos
        return :Linear, maximum(max.(subvec, 0.))
    elseif cone == :SOC
        return :SOC, max(0., vecnorm(subvec[2:end]) - subvec[1])
    elseif cone == :SOCRotated
        # (y,z,x) in RSOC <=> (sqrt2inv*(y+z),sqrt2inv*(-y+z),x) in SOC
        return :SOCRotated, max(0., sqrt(1/2*(subvec[1] - subvec[2])^2 + sumabs2(subvec[3:end])) - 1/sqrt(2)*(subvec[1] + subvec[2]))
    elseif cone == :ExpPrimal
        error("Unexpected expcone")
        return :Exp, max(subvec[2]*exp(subvec[1]/subvec[2]) - subvec[3],0)
    elseif cone == :Free
        return :Linear, 0.0
    else
        error("Unrecognized cone $cone")
    end
end


function compute_violations(dat, solution)
    c, A, b, con_cones, var_cones, vartypes, sense, objoffset = cbftompb(dat)

    # will be fixed soon, should really be equal
    #if length(solution) > length(c)
    #    println("Solution is too long")
    #end
    @assert length(solution) >= length(c)
    solution = solution[1:length(c)]
    objval = dot(c,solution)

    y = b - A*solution
    linear_violation = 0.0
    soc_violation = 0.0
    socrot_violation = 0.0
    exp_violation = 0.0
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
            end
        end
    end

    int_violation = 0.0
    for i in 1:length(vartypes)
        if vartypes[i] == :Int || vartypes[i] == :Bin
            int_violation = max(int_violation, abs(solution[i]-round(solution[i])))
        end
    end

    return objval, linear_violation, soc_violation, socrot_violation, exp_violation, int_violation
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


    solver = " "
    instance = " "
    status = " "
    objval = " "
    objbound = " "
    solvertime = " "
    totaltime = " "
    objval_sol = " "
    linear_violation = " "
    soc_violation = " "
    socrot_violation = " "
    exp_violation = " "
    int_violation = " "
    validator_status = " "
    validator_objval = " "
    solution = []
    # gaplimit = false

    for line in eachline(joinpath(pwd(), ARGS[1], filename))
        if startswith(line, "#SOLVERNAME#")
            solver = split(line)[2]
        elseif startswith(line, "#INSTANCE#")
            instance = split(line)[2]
            if endswith(instance, ".gz")
                instance = instance[1:end-3]
            end
        elseif startswith(line, "#STATUS#")
            status = split(line)[2]
        elseif startswith(line, "#OBJVAL#")
            objval = split(line)[2]
        elseif startswith(line, "#OBJBOUND#")
            objbound = split(line)[2]
        elseif startswith(line, "#TIMESOLVER#")
            solvertime = split(line)[2]
        elseif startswith(line, "#TIMEALL#")
            totaltime = split(line)[2]
        elseif startswith(line, "#SOLUTION#")
            solutionvec = split(line)[2]
            if startswith(solutionvec,'[') && endswith(solutionvec,']') && !startswith(solutionvec, "[]")
                solution = [parse(Float64,x) for x in split(solutionvec[2:end-1],',')]
            end
        end
        # elseif contains(line, "gap limit reached") # SCIP does this when it means optimal
        #     gaplimit=true
        #end
    end
    if length(solution) > 0 && all(isfinite,solution)
        instancefile = find_instance(instance)
        dat = readcbfdata(instancefile)

        objval_sol, linear_violation, soc_violation, socrot_violation, exp_violation, int_violation = compute_violations(dat,solution)
        validator_status, validator_objval = validate_with_conic_solver(dat,solution)
    end

    # if gaplimit
    #     @assert contains(solver, "SCIP")
    #     status = "Optimal"
    # end

    println(fd,
"$solver,$instance,$status,$objval,$objbound,$solvertime,$totaltime,$(basename(filename)),$objval_sol,$linear_violation,$soc_violation,$socrot_violation,$int_violation,$validator_status,$validator_objval")
end

close(fd)
