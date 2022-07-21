# Structure
- truffleruby (submodule)
Holds an instrumented version of TruffleRuby. Can output an execution trace that track most of method and block calls
- graal (submodule)
Holds a variation of GraalVM that uses a unique ID to identify call targets
- behaviour-analysis (submodule)
Holds the scripts necessary to analyse execution traces and output an analysis report.
Also output summary tables usable in tex files
- results
Holds the execution traces and the analysis results

# How to use
The Makefile contains all necessary targets to run ruby programs and analyse execution traces

    make init run analyze

should do the trick

# TODO
- [ ] Stop cloning the repos and install them as submodules, update the targets accordingly
- [ ] Generate the execution plots and store them in the benchmark folder
- [ ] Make it possible to run a list of programs, analyse all the traces and aggregate all the results 
- [ ] Generate a target lifetime plot (y-axis is target ID), color coded depending on the receiver set
