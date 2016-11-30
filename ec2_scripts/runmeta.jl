

# usage: runmeta.jl SOLVERNAME TIMELIMIT MEMORYLIMIT DATAFOLDER INSTANCENAMES

solvername = ARGS[1]
tlim = parse(Float64,ARGS[2])
memorylim = parse(Int,ARGS[3])
datafolder = ARGS[4]
instfile = ARGS[5]

fdmeta = open("output/$solvername.$tlim.txt","w")
println(fdmeta,"#SOLVER# $solvername")
println(fdmeta,"#TIMELIMIT# $tlim")

instancelist = readdlm(instfile)
println(fdmeta,"#INSTANCES#")
for instancename in instancelist
    println(fdmeta,instancename)
end
println(fdmeta)

for instancename in instancelist
    s = chomp(split(instancename,"/")[2])
    filename = "output/$solvername.$s.txt"
    process = spawn(`julia run.jl $solvername $tlim $datafolder $instancename`)
    t = time()
    sleep(120.0)
    pid = parse(Int,chomp(readline(open("mypid","r"))))
    while process_running(process)
        if time() - t > tlim + 60*5
            kill(process)
            println(fdmeta,"Killed by time limit")
        else
            memory = parse(Int,split(readstring(pipeline(`cat /proc/$pid/status`,`grep RSS`)))[2])
            if memory > memorylim
                kill(process)
                println(fdmeta,"Killed by memory limit")
            end
        end
        sleep(1.0)
    end
    println(fdmeta,"$(time() - t) seconds.")
end
close(fdmeta)
