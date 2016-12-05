

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
    println(fdmeta, "\nstarting instance $shortname...")

    try
        process = spawn(`julia run.jl $solvername $tlim $datafolder $instancename`)
        t = time()
        sleep(60.0)
        pid = parse(Int, chomp(readline(open("mypid", "r"))))

        while process_running(process)
            if (time() - t) > (tlim + 60*5)
                kill(process)
                println(fdmeta, "killed by time limit")
            else
                memuse = parse(Int, split(readstring(pipeline(`cat /proc/$pid/status`,`grep RSS`)))[2])
                if memuse > mlim
                    kill(process)
                    println(fdmeta, "killed by memory limit")
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
