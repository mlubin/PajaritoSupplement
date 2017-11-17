using Plots
pgfplots()

import BenchmarkProfiles

# Customized performance_profile method, derived from BenchmarkProfiles.jl
#Copyright (c) 2016: Dominique Orban.
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
function performance_profile(T :: Array{Float64,2}, labels :: Vector{String};
                             logscale :: Bool=true,
                             title :: String="",
                             ymax = 1.1,
                             xmax = NaN,
                             linewidth=1,
                             kwargs...)

  (ratios, max_ratio) = BenchmarkProfiles.performance_ratios(T, logscale=logscale)
  (np, ns) = size(ratios)

  ratios = [ratios; 2.0 * max_ratio * ones(1, ns)]
  xs = [1:np+1;] / np
  length(labels) == 0 && (labels = [@sprintf("column %d", col) for col = 1 : ns])
  profile = Plots.plot(; kwargs...)  # initial empty plot
  for s = 1 : ns
    Plots.plot!(ratios[:, s], xs, t=:steppost, label=labels[s], linewidth=linewidth)
  end
  if isfinite(xmax)
      Plots.xlims!(logscale ? 0.0 : 1.0, xmax)
  else
      Plots.xlims!(logscale ? 0.0 : 1.0, 1.1 * max_ratio)
  end
  Plots.ylims!(0, ymax)
  Plots.xlabel!("\$F\$" * (logscale ? " (log scale)" : ""))
  Plots.ylabel!("\$P\$")
  Plots.title!(title)
  return profile
end
