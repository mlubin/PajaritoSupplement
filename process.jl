using ConicBenchmarkUtilities

resultfiles = readdir(joinpath(pwd(), ARGS[1]))

fd = open(joinpath(pwd(), ARGS[2]), "w")

# process into a CSV file with columns:
println(fd,"solver,instance,status,objval,objbound,solvertime,totaltime,filename")

# from instance name to file name
function find_instance(name)
    instances = joinpath(dirname(@__FILE__),"instancedata")
    try
        match = "$name.*"
        f = readstring(`find $instances -name $match`)
        if length(split(f,"\n")) == 2
            return chomp(f)
        end
    end
    return ""
end


function validate_solution(instancename, solution)
    instancefile = find_instance(instancename)
    dat = readcbfdata(instancefile)
    c, A, b, con_cones, var_cones, vartypes, sense, objoffset = cbftompb(dat)
    @assert length(solution) == length(c)
    objval = dot(c,solution)
    return objval
end

for filename in resultfiles
    if filename == ".DS_Store" || contains(filename,"META")
        continue
    end

    solver = " "
    instance = " "
    status = " "
    objval = " "
    objbound = " "
    solvertime = " "
    totaltime = " "
    solution = []
    # gaplimit = false

    for line in eachline(joinpath(pwd(), ARGS[1], filename))
        if startswith(line, "#SOLVERNAME#")
            solver = split(line)[2]
        elseif startswith(line, "#INSTANCE#")
            instance = split(line)[2]
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
            if startswith(solutionvec,'[') && endswith(solutionvec,']')
                solution = [parse(Float64,x) for x in split(solutionvec[2:end-1],',')]
            end
        end
        # elseif contains(line, "gap limit reached") # SCIP does this when it means optimal
        #     gaplimit=true
        #end
    end
    @show instance,length(solution)
    if length(solution) > 0
        objval_sol = validate_solution(instance,solution)
        try
            diff = abs(objval_sol-parse(Float64,objval))/abs(objval_sol)
            if diff > 1e-3
                @show diff
            end
        end
    end

    # if gaplimit
    #     @assert contains(solver, "SCIP")
    #     status = "Optimal"
    # end

    println(fd, "$solver,$instance,$status,$objval,$objbound,$solvertime,$totaltime,$(basename(filename))")
end

close(fd)
