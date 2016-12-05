

# usage: runmeta.jl SOLVERNAME TIMELIMIT MEMORYLIMIT DATAFOLDER INSTANCENAMES

solvername = ARGS[1]
tlim = parse(Float64, ARGS[2])
mlim = parse(Int, ARGS[3])
datafolder = ARGS[4]
instfile = ARGS[5]

# Print info and all instances in the set to a META file for the solver
fdmeta = open("output/META.$solvername.txt", "w")
println(fdmeta, "#SOLVER# $solvername")
println(fdmeta, "#TIMELIMIT# $tlim")
println(fdmeta, "#MEMLIMIT# $mlim")

instancelist = readdlm(instfile)
println(fdmeta, "#INSTANCES#")
for instancename in instancelist
    println(fdmeta, instancename)
end
println(fdmeta)
flush(fdmeta)

# Run each instance one by one
# This only works on Linux because we check the memory use with Linux commands
for instancename in instancelist
    shortname = chomp(split(instancename, "/")[2])
    println(fdmeta, "\nstarting instance $shortname...")

    # Try to start a process to run the current instance on
    # If this fails, it won't affect running future instances
    try
        process = spawn(`julia run.jl $solvername $tlim $datafolder $instancename`)
        t = time()
        sleep(60.0)
        pid = parse(Int, chomp(readline(open("mypid", "r"))))

        while process_running(process)
            if (time() - t) > (tlim + 60*5)
                # Kill if time limit exceeded (some solvers don't respect time limits)
                kill(process)
                println(fdmeta, "killed by time limit")
            else
                # Try to kill if memory limit exceeded (some solvers use too much memory and fail)
                # If this try fails, process has already stopped
                try
                    memuse = parse(Int, split(readstring(pipeline(`cat /proc/$pid/status`,`grep RSS`)))[2])
                    if memuse > mlim
                        kill(process)
                        println(fdmeta, "killed by memory limit")
                    end
                end
            end
            sleep(1.0)
        end

        println(fdmeta, "...took $(time() - t) seconds")
    catch e
        println(fdmeta, "...process error: $e")
    end

    flush(fdmeta)
end

close(fdmeta)
