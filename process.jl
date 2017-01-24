
resultfiles = readdir(joinpath(pwd(), ARGS[1]))

fd = open(joinpath(pwd(), ARGS[2]), "w")

# process into a CSV file with columns:
println(fd,"solver,instance,status,objval,objbound,solvertime,totaltime,filename")

for filename in resultfiles
    if filename == ".DS_Store"
        continue
    end

    solver = " "
    instance = " "
    status = " "
    objval = " "
    objbound = " "
    solvertime = " "
    totaltime = " "
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
            solutionvec = split(line)[2:end]
        # elseif contains(line, "gap limit reached") # SCIP does this when it means optimal
        #     gaplimit=true
        end
    end

    # if gaplimit
    #     @assert contains(solver, "SCIP")
    #     status = "Optimal"
    # end

    println(fd, "$solver,$instance,$status,$objval,$objbound,$solvertime,$totaltime,$(basename(filename))")
end

close(fd)
