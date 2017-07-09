#!/bin/bash

#/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl Port_noconic 3600 50000000 instancedata/portcbf/soc/ instancesets/port_soc.txt
#/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl Port_MOSEK 3600 50000000 instancedata/portcbf/soc/ instancesets/port_soc.txt
#/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl Port_noconic 3600 50000000 instancedata/portcbf/socpsd/ instancesets/port_socpsd.txt
#/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl Port_MOSEK 3600 50000000 instancedata/portcbf/socpsd/ instancesets/port_socpsd.txt
#/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl Port_noconic 3600 50000000 instancedata/portcbf/socexp/ instancesets/port_socexp.txt
#/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl Port_ECOS 3600 50000000 instancedata/portcbf/socexp/ instancesets/port_socexp.txt
#/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl Port_noconic 3600 50000000 instancedata/portcbf/socexppsd/ instancesets/port_socexppsd.txt
#/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl Port_SCS_warm 3600 50000000 instancedata/portcbf/socexppsd/ instancesets/port_socexppsd.txt
#/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl Port_SCS_nowarm 3600 50000000 instancedata/portcbf/socexppsd/ instancesets/port_socexppsd.txt


/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl MOSEK 3600 50000000 continstancedata/soc/ instancesets/contport_soc.txt
/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl ECOS 3600 50000000 continstancedata/soc/ instancesets/contport_soc.txt
/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl SCS 3600 50000000 continstancedata/soc/ instancesets/contport_soc.txt

/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl MOSEK 3600 50000000 continstancedata/socpsd/ instancesets/contport_socpsd.txt
/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl SCS 3600 50000000 continstancedata/socpsd/ instancesets/contport_socpsd.txt

/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl ECOS 3600 50000000 continstancedata/socexp/ instancesets/contport_socexp.txt
/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl SCS 3600 50000000 continstancedata/socexp/ instancesets/contport_socexp.txt

/home/coey/julia-903644385b/bin/julia scripts/runmeta.jl SCS 3600 50000000 continstancedata/socexppsd/ instancesets/contport_socexppsd.txt
