#!/bin/bash
# INSTALL.sh
# Install the dependencies required to run on a Gurobi-Ubuntu EC2 instance

# Args: $1: iteration number

# Exit on any error, INSTALL.py will retry again later
set -e

# apt-get tools
sudo apt-get update --yes > progress_A_1_$1.txt 2>&1
sudo apt-get -y --force-yes install git python-pip python-paramiko > progress_A_2_$1.txt 2>&1
sudo apt-get -y install build-essential gfortran pkg-config unzip libgmp-dev libz-dev libreadline-dev libncurses-dev > progress_A_3_$1.txt 2>&1

# Julia
wget https://julialang.s3.amazonaws.com/bin/linux/x64/0.5/julia-0.5.0-linux-x86_64.tar.gz
tar -xvzf julia-0.5.0-linux-x86_64.tar.gz > progress_B_1_$1.txt 2>&1

# Mosek 8.0.0.45
# wget http://download.mosek.com/stable/8.0.0.45/mosektoolslinux64x86.tar.bz2
# tar -xvjf mosektoolslinux64x86.tar.bz2 > progress_B_2_$1.txt 2>&1

# MOSEK licence
mkdir mosek
cp mosek.lic mosek

# Our tarball
wget https://s3.amazonaws.com/pajaritotesting/juliafiles_20161007.tar.gz
tar -xvzf juliafiles_20161007.tar.gz > progress_B_3_$1.txt 2>&1

# CBLIB data
wget https://s3.amazonaws.com/pajaritotesting/data.zip
unzip data.zip > progress_B_4_$1.txt 2>&1

# Boto
sudo pip install boto > progress_C_1_$1.txt 2>&1

# Julia path and Gurobi version location
export PATH="$PATH:$HOME/julia-3c9d75391c/bin"
export GUROBI_HOME=/opt/gurobi701/linux64

# Julia packages
cd ~/.julia/v0.5/Pajarito; git checkout master; git pull; cd -
cd ~/.julia/v0.5/WoodburyMatrices; git checkout master; git pull; cd -
# cd ~/.julia/v0.5/Gurobi; git checkout master; git pull; cd -
# cd ~/.julia/v0.5/Mosek; git checkout master; git pull; cd -
cd ~/.julia/v0.5/MathProgBase; git checkout master; git pull; cd -
cd ~/.julia/v0.5/JuMP; git checkout master; git pull; cd -
# cd ~/.julia/v0.5/ConicNonlinearBridge; git checkout master; git pull; cd -
# cd ~/.julia/v0.5/AmplNLWriter; git checkout master; git pull; cd -
julia -e 'Pkg.build("Gurobi"); Pkg.status();' > progress_C_2_$1.txt 2>&1

# Output folder
mkdir output

# Test
julia -e 'using Gurobi; println(Gurobi.version)' > GUROBI_VERSION

# Allow julia to be called after this script
sudo ln -s ~/julia-3c9d75391c/bin/julia /usr/bin/

# Send signal to start job
touch READY
