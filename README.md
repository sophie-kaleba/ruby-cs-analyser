# Structure
- truffleruby (submodule)
Holds an instrumented version of TruffleRuby. Can output an execution trace that track most of method and block calls.
- graal (submodule)
Holds a variation of GraalVM that uses a unique ID to identify call targets
- behaviour-analysis (submodule)
Holds the scripts necessary to analyse execution traces and output an analysis report.
Also output summary tables usable in tex files
- results
Holds the execution traces and the analysis results

# How to use
The Makefile contains all necessary targets to run ruby programs and analyse execution traces

    make all benchmark_name="---" iterations="---" inner_iterations="---"

should do the trick

### Makefile targets

TODO

fetch_deps:


build_tr: 

     
run_and_log:


parse_coverage:


parse_trace:


analyse_trace:

		  
report:


reorganize:


clean:


pdf:


# TODO
- [ ] Make sure the input for the java splitting analyzer is written in the currnent benchmark folder
- [ ] R performance: str_trim when python parsing rather than in the R script
- [x] Analysis takes time, and most of it is spent on the java part of the process. Improve the java splitting analyser.
- [ ] Generate the execution plots and store them in the benchmark folder
- [ ] Clean the behaviour-analysis repository
- [ ] Make it possible to run a list of programs, analyse all the traces and aggregate all the results
- [ ] Generate a target lifetime plot (y-axis is target ID), color coded depending on the receiver set
