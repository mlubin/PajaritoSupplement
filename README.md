# PajaritoSupplement

This supplement is for reproducing the computational results in section 6 of "Outer Approximation With Conic Certificates For Mixed-Integer Convex Problems" by Chris Coey, Miles Lubin, and Juan Pablo Vielma.
* Section 6.1 describes our presentation of results in tables and performance profiles. 
* Section 6.2 presents the comparisons of 9 MISOCP solvers (3 Bonmin, Pajarito + CBC or GLPK, SCIP, CPLEX, and 2 Pajarito + CPLEX) on our testset of 120 MISOCP (mixed-integer second-order cone programming) instances from CBLIB (http://cblib.zib.de/). 
* Section 6.3 presents the comparisons of key algorithmic variants of Pajarito (cut types, cut disaggregation, cut scaling) on our testset of 95 MICP (mixed-integer conic programming) instances (involving mixtures of second-order, exponential, and positive semidefinite cone constraints). 

The folders in this supplement are organized as follows.
* `cbfs/` contains our MISOCP and MICP testsets. Each instance file is stored as a gzipped `cbf` file (`.cbf.gz`). CBF is described by Friberg at http://cblib.zib.de/.
* `sets/` contains lists of instances from the `cbfs/` folder. These lists are used by the scripts to test the infrastructure or to run manageable subsets of the instances.
* `scripts/` contains the bash (`.sh`) and Julia (`.jl`) scripts for running the MISOCP and MICP tests on a local machine and later processing the output into `.csv` files ready for further analysis.
* `awsscripts/` contains files for running the (time-consuming) MISOCP tests specifically on AWS EC2 cloud compute infrastructure in parallel, rather than on the local machine. This folder is irrelevant if the MISOCP tests are to be run on the local machine.
* `output/` initially contains a text file outputted by the `scripts/run.jl` script for each solver-instance run that we performed. Each text file contains solver logs, errors, warnings, and a printout of the summary information such as objective, solution, status, and execution time. The current set of files should be deleted or moved before running the scripts again.
* `results/` initially contains `.csv` files that are outputted by the `scripts/process_output.jl` script. Each line in each file corresponds to a solver-instance run, and summarizes the important performance metrics and solution checks. The current set of files should be deleted or moved before running the scripts again. 
* `analysis/` 

TODO change "subpsep" to "types" for clarity. 
TODO maybe move any outputs of the analysis scripts, or move the analysis scripts to scripts folder


## Software installation

TODO copy code from awsscripts readme and modify


## MISOCP tests


## MICP tests


