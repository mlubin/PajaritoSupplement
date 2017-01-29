#!/bin/bash
# INSTALL.sh
# Install the dependencies required to run on a EC2 instance

# Args: $1: iteration number

# Exit on any error, INSTALL.py will retry again later
set -e

# Julia packages
# cd ~/.julia/v0.5/Pajarito; git checkout master; git pull; cd -
# cd ~/.julia/v0.5/CPLEX; git checkout master; git pull; cd -
# cd ~/.julia/v0.5/Mosek; git checkout master; git pull; cd -
# cd ~/.julia/v0.5/MathProgBase; git checkout master; git pull; cd -
# cd ~/.julia/v0.5/JuMP; git checkout master; git pull; cd -
# cd ~/.julia/v0.5/ConicNonlinearBridge; git checkout master; git pull; cd -
# cd ~/.julia/v0.5/AmplNLWriter; git checkout master; git pull; cd -

cd ~/PajaritoSupplement; git pull; cd -

# Send signal to start job
touch READY
