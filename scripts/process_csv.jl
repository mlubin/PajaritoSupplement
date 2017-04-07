using DataFrames, Query, NamedArrays

# process the csv produced by process_awsoutput.jl
results = readtable(ARGS[1])

# file listing manually excluded results
# format by line: solver instance ignored comment
# example: PAJ_CPLEX_MOSEK clay0304h.cbf # CPLEX gave wrong answer
excluded = [split(strip(l))[1:2] for l in split(readstring(ARGS[2]),'\n') if strip(l) != ""]
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
end

optimal_runs = @from r in results begin
               @where r.status == "Optimal"
               @select r
               @collect DataFrame
               end

# problematic violations
viol = @from r in results begin
       @where r.max_linear_violation > 1e-3 || r.max_soc_violation > 1e-3 || r.max_socrot_violation > 1e-3 || r.max_exp_violation > 1e-3 || r.max_int_violation > 1e-5
       @select r
       @collect DataFrame
       end

if size(viol,1) == 0
    println("No problematic violations")
else
    println("Problematic violations")
    println(viol)
end


# check for disagreements in objective value
instances = unique(optimal_runs[:instance])
for inst in instances
    optval_by_instance = @from r in optimal_runs begin
                         @where r.instance == inst
                         @select {r.solver,r.objval_reported,r.objbound,r.sense}
                         @collect DataFrame
                         end
    first_optval = optval_by_instance[1,:objval_reported]
    for i in 2:size(optval_by_instance,1)
        solver = optval_by_instance[i,:solver]
        optval = optval_by_instance[i,:objval_reported]
        if abs(optval-first_optval)/abs(first_optval+1e-5) > 1e-4
            println("Objective disagreement on instance $inst")
            println(optval_by_instance)
            break
        end
    end
end

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

println("Status counts by solver")
for k in 1:3:length(statuses)+1
    println(status_table[:,k:min(length(statuses)+1,k+2)])
end
println()


function shifted_geomean(table, field, shift, groupby)
    solvers = unique(table[groupby])
    sum_by = Dict(g => 0.0 for g in solvers)
    counter_by = Dict(g => 0 for g in solvers)
    # prod(x_i + s)^(1/n) - s
    # compute prod(x_i+s)^(1/n) as
    # exp(sum(log(x_i+s))/n)
    for i in 1:size(table,1)
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

println("Shifted geomean of solve time on all instances")
shifted_geomean(results, :solvertime, time_shift, :solver)
println()

println("Shifted geomean of solve time on optimal instances")
shifted_geomean(optimal_runs, :solvertime, time_shift, :solver)
println()

println("Shifted geomean of conic subproblem count on optimal instances")
shifted_geomean(optimal_runs, :conic_subproblems, subproblem_shift, :solver)

