

# usage: runmeta.jl SOLVERNAME TIMELIMIT MEMORYLIMIT DATAFOLDER INSTANCENAMES

solvername = ARGS[1]
tlim = parse(Float64, ARGS[2])
mlim = parse(Int, ARGS[3])
datafolder = ARGS[4]
instfile = ARGS[5]

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

for instancename in instancelist
    shortname = chomp(split(instancename, "/")[2])
    println(fdmeta, "Starting instance $shortname...")

    process = spawn(`julia run.jl $solvername $tlim $datafolder $instancename`)
    t = time()
    sleep(60.0)
    pid = parse(Int, chomp(readline(open("mypid", "r"))))

    while process_running(process)
        if (time() - t) > (tlim + 60*5)
            try
                kill(process)
                println(fdmeta, "Killed by time limit")
            end
        else
            try
                memuse = parse(Int, split(readstring(pipeline(`cat /proc/$pid/status`,`grep RSS`)))[2])
                if memuse > mlim
                    kill(process)
                    println(fdmeta, "Killed by memory limit")
                end
            end
        end
        sleep(1.0)
    end

    println(fdmeta, "...$(time() - t) seconds\n")
    flush(fdmeta)
end

close(fdmeta)
