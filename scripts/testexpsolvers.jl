using ConicBenchmarkUtilities
using ECOS
using SCS
using MathProgBase

# julia testexpsolvers.jl ECOS ../instancedata/minlplib2/syn/*
# julia testexpsolvers.jl SCS ../instancedata/minlplib2/syn/*

# see if the solver can solve the continuous relaxations

if ARGS[1] == "ECOS"
    solver = ECOSSolver()
elseif ARGS[1] == "SCS"
    solver = SCSSolver()
else
    error("Unrecognized solver $(ARGS[1])")
end

solved = 0
suboptimal = 0

results = []

for F in ARGS[2:end]
    dat = readcbfdata(F)

    c, A, b, con_cones, var_cones, vartypes, sense, objoffset = cbftompb(dat)

    @assert dat.sense == :Min
    @assert dat.objoffset == 0.0

    m = MathProgBase.ConicModel(solver)
    MathProgBase.loadproblem!(m, c, A, b, con_cones, var_cones)
    #MathProgBase.setvartype!(m, vartypes)
    MathProgBase.optimize!(m)
    status = MathProgBase.status(m)
    if status == :Optimal
        solved += 1
    elseif status == :Suboptimal
        suboptimal += 1
    end
    push!(results,(F,status))

end

for (name,status) in results
    println("$(basename(name)) $status")
end

println("SOLVED $solved SUBOPTIMAL $suboptimal TOTAL $(length(ARGS)-1)")
