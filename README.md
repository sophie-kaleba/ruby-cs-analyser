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
