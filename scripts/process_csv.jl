using DataFrames, NamedArrays
import DocOpt
using JLD

doc = """CSV Process Utility

Usage:
  process_csv.jl check <csvfile> [--exclude=<excludefile>]
  process_csv.jl statuscounts <csvfile> <csvfileout> [--exclude=<excludefile>] [--bestof=<list>]...
  process_csv.jl geomeans <csvfile> [--exclude=<excludefile>] [--bestof=<list>]...
  process_csv.jl perfprofile <csvfile> <output_jld> <solver>... [--exclude=<excludefile>] [--bestof=<list>]...
  process_csv.jl -h | --help

Options:
  -h --help               Show this screen.
  --exclude=<excludefile> A list of runs to exclude.
  --bestof=<list>         Create an artificial solver by taking the best of multiple solvers. Format: "A B C" creates a new solver A from best of B and C.
"""

arguments = DocOpt.docopt(doc)

# process the csv produced by process_awsoutput.jl
results = readtable(arguments["<csvfile>"])

# file listing manually excluded results
# format by line: solver instance ignored comment
# example: PAJ_CPLEX_MOSEK clay0304h.cbf # CPLEX gave wrong answer
if isa(arguments["--exclude"], String)
    excluded = [split(strip(l))[1:2] for l in split(readstring(arguments["--exclude"]),'\n') if strip(l) != ""]
else
    excluded = []
end
function isexcluded(solver,inst)
    for k in 1:length(excluded)
        if excluded[k][1] == solver && excluded[k][2] == inst
            return true
        end
    end
    return false
end

for i in 1:size(results,1)
    if isexcluded(results[i,:solver],results[i,:instance])
        results[i,:status] = "Excluded"
    end
    if isna(results[i,:status])
        results[i,:status] = "Blank"
    end
end

for solverlist in arguments["--bestof"]
    newsolver = split(solverlist)[1]
    best_of_solvers = split(solverlist)[2:end]
    newrows = []
    for rowlist in groupby(results,:instance)
        besttime = Inf
        beststatus = "Blank"
        inst = rowlist[1,:instance]
        for i in 1:size(rowlist,1)
            if rowlist[i,:solver] in best_of_solvers
                if rowlist[i,:status] == "Optimal"
                    besttime = min(besttime,rowlist[i,:solvertime])
                    beststatus = "Optimal"
                elseif rowlist[i,:status] in ["UserLimit","KilledTime","KilledMemory"]
                    if beststatus != "Optimal"
                        besttime = min(besttime,rowlist[i,:solvertime])
                        beststatus = "UserLimit"
                    end
                end
            end
        end
        newrow = Dict{Symbol,Any}(n => NA for n in names(results))
        newrow[:instance] = inst
        newrow[:solver] = newsolver
        newrow[:status] = beststatus
        newrow[:solvertime] = besttime
        push!(newrows,newrow)
    end
    for r in newrows
        push!(results, r)
    end
end


optimal_runs = results[results[:status] .== "Optimal",:]

function printdf(df)
    # lifted from DataFrames.show()
    rowindices1 = 1:size(df,1)
    rowindices2 = 1:0
    maxwidths = DataFrames.getmaxwidths(df, rowindices1, rowindices2, :Rows)
    DataFrames.showrows(STDOUT, df, 1:size(df,1), 1:0, maxwidths, false, :Row, true)
    println()
end

if arguments["check"]


    # problematic violations
    viol = optimal_runs[(optimal_runs[:max_linear_violation] .> 1e-3) .| (optimal_runs[:max_soc_violation] .> 1e-3) .| (optimal_runs[:max_socrot_violation] .> 1e-3) .| (optimal_runs[:max_exp_violation] .> 1e-3) .| (optimal_runs[:max_psd_violation] .> 1e-3) .| (optimal_runs[:max_int_violation] .> 1e-3), :]

    if size(viol,1) == 0
        println("No problematic violations")
    else
        println("Problematic violations")
        println(viol)
    end

    # check for disagreements in objective value
    for optval_by_instance in groupby(optimal_runs, :instance)
        first_optval = optval_by_instance[1,:objval_reported]
        sense = optval_by_instance[1,:sense]
        inst = optval_by_instance[1,:instance]
        for i in 2:size(optval_by_instance,1)
            solver = optval_by_instance[i,:solver]
            optval = optval_by_instance[i,:objval_reported]
            if abs(optval-first_optval)/abs(first_optval+1e-5) > 1e-4
                println("Objective disagreement on instance $inst (sense = $sense)")
                printdf(optval_by_instance[:,[:solver,:objval_reported,:objbound]])
                break
            end
        end
    end

    # check for duplicated runs
    for g1 in groupby(results, :instance)
        for g2 in groupby(g1,:solver)
            if size(g2,1) > 1
                s = g2[1,:solver]
                inst = g2[1,:instance]
                println("Multiple results for solver $s instance $inst")
            end
        end
    end


elseif arguments["statuscounts"]

    # status counts by solver

    statuses = sort(collect(unique(results[:status])))
    all_solvers = sort(collect(unique(results[:solver])))
    status_table = NamedArray(zeros(Int,length(all_solvers),length(statuses)+1))
    setnames!(status_table, all_solvers, 1)
    setnames!(status_table, [statuses;"Total"], 2)
    for i in 1:size(results,1)
        status_table[results[i,:solver],results[i,:status]] += 1
        status_table[results[i,:solver],"Total"] += 1
    end

    df2 = DataFrame(convert(Array,status_table))
    names!(df2, convert(Vector{Symbol},names(status_table,2)))
    df2[:solver] = names(status_table,1)
    writetable(arguments["<csvfileout>"],df2)


elseif arguments["geomeans"]

    function shifted_geomean(table, field, shift, groupby)
        solvers = unique(table[groupby])
        sum_by = Dict(g => 0.0 for g in solvers)
        counter_by = Dict(g => 0 for g in solvers)
        # prod(x_i + s)^(1/n) - s
        # compute prod(x_i+s)^(1/n) as
        # exp(sum(log(x_i+s))/n)
        for i in 1:size(table,1)
            if isna(table[i,field])
                continue
            end
            sum_by[table[i,groupby]] += log(table[i,field] + shift)
            counter_by[table[i,groupby]] += 1
        end
        for g in solvers
            r = exp(sum_by[g]/counter_by[g]) - shift
            println("$g: $r")
        end
    end


    time_shift = 10.0
    subproblem_shift = 1.0

    # tidy data (needed for KilledX cases)
    for i in 1:size(results,1)
        if isna(results[i,:solvertime])
            results[i,:solvertime] = results[i,:timelimit]
        end
    end

    println("Shifted geomean of solve time on all instances")
    shifted_geomean(results, :solvertime, time_shift, :solver)
    println()

    println("Shifted geomean of solve time on optimal instances")
    shifted_geomean(optimal_runs, :solvertime, time_shift, :solver)
    println()

    println("Shifted geomean of conic subproblem count on all instances")
    shifted_geomean(results, :conic_subproblem_count, subproblem_shift, :solver)
    println()

    println("Shifted geomean of conic subproblem count on optimal instances")
    shifted_geomean(optimal_runs, :conic_subproblem_count, subproblem_shift, :solver)
    println()

    println("Shifted geomean of iteration count on all instances")
    shifted_geomean(results, :iteration_count, subproblem_shift, :solver)
    println()

    println("Shifted geomean of proportion of time spent in conic solver on all instances")
    shifted_geomean(results, :prop_conic_total, 0.0, :solver)


elseif arguments["perfprofile"]
    solvers = arguments["<solver>"]
    # need a table of [time] X [solver] where each row is a solver
    time_rows = []
    itercount_rows = []
    instance_names = String[]
    for by_instance in groupby(optimal_runs, :instance)
        time_row = fill(Inf,length(solvers))
        itercount_row = fill(Inf,length(solvers))
        for i in 1:size(by_instance,1)
            push!(instance_names,by_instance[1,:instance])
            if by_instance[i,:status] == "Optimal"
                whichsolver = indexin([by_instance[i,:solver]],solvers)[1]
                if whichsolver != 0
                    time_row[whichsolver] = by_instance[i,:solvertime]
                    if !isna(by_instance[i,:conic_subproblem_count])
                        itercount_row[whichsolver] = by_instance[i,:conic_subproblem_count]
                    end
                end # else not plotting this solver
            end # else not solved, Inf by default
        end
        push!(time_rows,time_row')
        push!(itercount_rows,itercount_row')
    end
    time_mat = vcat(time_rows...)
    itercount_mat = vcat(itercount_rows...)
    @assert endswith(arguments["<output_jld>"],".jld")
    save(arguments["<output_jld>"], "time_table", time_mat, "itercount_table", itercount_mat, "solvers", solvers, "instance_names", instance_names)
    #p = performance_profile(mat, solvers, title="TITLE")
    #Plots.savefig("perf.png")
end

    


