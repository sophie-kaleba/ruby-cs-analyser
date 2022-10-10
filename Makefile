PROJECT_FOLDER := $(PWD)
SRC_TR := truffleruby
SRC_MX := mx
SRC_GRAAL := graal
SRC_ANALYZER := behaviour-analysis
SRC_RESULTS := results

#JT = $(PROJECT_FOLDER)/$(SRC_TR)/bin/jt
JT := $(PROJECT_FOLDER)/$(SRC_TR)/tool/jt.rb
GRAAL_BRANCH := "dls/test-fail"
TR_BRANCH := "update-truby"
ANALYZER_BRANCH := "switch-to-data-table"

EXE_FLAGS := --monitor-calls=true --monitor-startup=true --splitting --yield-always-clone=false --coverage --coverage.Output=histogram --coverage.OutputFile=./coverage/${benchmark_name}.info --vm.Xss6m

RUN_FOLDER := $(PROJECT_FOLDER)/$(SRC_RESULTS)/${run_folder}
CURRENT_FOLDER := ${RUN_FOLDER}/${benchmark_name}
LATEST_FOLDER := $(PROJECT_FOLDER)/$(SRC_RESULTS)/latest
LATEST_COV_FOLDER := $(LATEST_FOLDER)/Coverage
COV_FOLDER := $(LATEST_FOLDER)/Coverage
REPORT_FOLDER := $(LATEST_FOLDER)/report
PLOTS_FOLDER := $(LATEST_FOLDER)/plots
SYSTEM_RUBY := "/home/sopi/.rbenv/versions/3.0.0/bin/ruby"
RAW_INPUT := raw_${benchmark_name}.log
PARSED_INPUT := parsed_${benchmark_name}.log

METHODS := "FALSE"
BLOCKS := "TRUE"

KEEP_STARTUP := "TRUE"
NO_STARTUP := "FALSE"

do_run: run_and_trace parse_coverage parse_trace 
do_analyse: analyse_trace 
do_report: report plots clean
init: fetch_deps build_tr
all: fetch_deps build_tr run_and_trace parse_coverage parse_trace analyse_trace report plots clean

fetch_deps:
		$(info [FETCHING graal anx mx...])
		git submodule update --init

		cd $(PROJECT_FOLDER)/${SRC_GRAAL} ; git -C $(PROJECT_FOLDER)/$(SRC_GRAAL) fetch --all || true ; git checkout $(GRAAL_BRANCH)
		git -C $(PROJECT_FOLDER)/$(SRC_MX) fetch || true

		$(info [FETCHING truffleruby ...])
		cd $(PROJECT_FOLDER)/${SRC_TR} ; git -C $(PROJECT_FOLDER)/$(SRC_TR) fetch --all || true ; git checkout $(TR_BRANCH)

		$(info [FETCHING Ruby analyser ...])
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; git -C $(PROJECT_FOLDER)/$(SRC_ANALYZER) fetch --all || true ; git checkout $(ANALYZER_BRANCH)

build_tr: 
		$(info [BUILDING TruffleRuby and Java splitting analyser ...])
		
		export GIT_DIR=$(PROJECT_FOLDER)/${SRC_TR}/.git ; git checkout $(TR_BRANCH)	
		cd $(PROJECT_FOLDER)/$(SRC_TR) ; ${JT} build --sforceimports --env jvm-ce

		cd $(PROJECT_FOLDER)/$(SRC_ANALYZER)/splitting-transition/src ; javac *.java
     
run_and_trace:
		$(info [RUNNING ${benchmark_name} ...])

		(cd $(PROJECT_FOLDER)/${SRC_TR} ; git fetch --all || true ; git checkout $(TR_BRANCH))
		
		mkdir -p $(CURRENT_FOLDER)
		ln -vfns $(CURRENT_FOLDER) $(LATEST_FOLDER)
		mkdir -p $(COV_FOLDER)

		export SYSTEM_RUBY=$(SYSTEM_RUBY) ; $(SYSTEM_RUBY) $(JT) --use jvm-ce ruby --vm.Dpolyglot.log.file="$(CURRENT_FOLDER)/raw_${benchmark_name}.log"  $(EXE_FLAGS) --coverage.OutputFile=$(COV_FOLDER)/${benchmark_name}.info $(PROJECT_FOLDER)/$(SRC_TR)/bench/phase/harness-behaviour-aux.rb ${benchmark_name} ${iterations} ${inner_iterations}

parse_coverage:
		$(info [REPORT COVERAGE...])

		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; git fetch --all || true ; git checkout $(ANALYZER_BRANCH) ; git pull

		python3 $(PROJECT_FOLDER)/$(SRC_ANALYZER)/parse_simple_cov.py $(COV_FOLDER)/${benchmark_name}.info $(COV_FOLDER)/${benchmark_name}_global.csv ${benchmark_name}

parse_trace:
		$(info [PARSING execution trace ...])

		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; git fetch --all || true ; git checkout $(ANALYZER_BRANCH) ; git pull

		cd $(LATEST_FOLDER) ; python3 $(PROJECT_FOLDER)/$(SRC_ANALYZER)/parse_execution_trace.py $(RAW_INPUT) $(PARSED_INPUT)

		$(info [COMPRESS execution trace ...])
		cd $(LATEST_FOLDER) ; tar --remove-files -I lz4 -cf $(RAW_INPUT).tar.lz4 $(RAW_INPUT)

analyse_trace:
		$(info [ANALYSING execution trace, summary tables saved in $(LATEST_FOLDER)...])

		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript analyse_and_generate_csv.Rnw ${benchmark_name} $(LATEST_FOLDER)/$(PARSED_INPUT) $(LATEST_FOLDER) ${KEEP_STARTUP} $(METHODS)
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript analyse_and_generate_csv.Rnw ${benchmark_name} $(LATEST_FOLDER)/$(PARSED_INPUT) $(LATEST_FOLDER) ${NO_STARTUP} $(METHODS)
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript analyse_and_generate_csv.Rnw ${benchmark_name} $(LATEST_FOLDER)/$(PARSED_INPUT) $(LATEST_FOLDER) ${KEEP_STARTUP} $(BLOCKS)
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript analyse_and_generate_csv.Rnw ${benchmark_name} $(LATEST_FOLDER)/$(PARSED_INPUT) $(LATEST_FOLDER) ${NO_STARTUP} $(BLOCKS)

#		arg1: benchmark name arg2: output folder for generated files arg3:trace file to analyse
		cd $(LATEST_FOLDER) ; tar --remove-files -I lz4 -cf $(PARSED_INPUT).tar.lz4 $(PARSED_INPUT)
		cd $(LATEST_FOLDER) ; tar --remove-files -I lz4 -cf ${benchmark_name}_splitting_data.csv.tar.lz4 ${benchmark_name}_splitting_data.csv
		  
report:
		$(info [GENERATING analysis reports at $(REPORT_FOLDER)...])

		mkdir -p $(REPORT_FOLDER)

#		will generate tex tables and tax nacros in the one_bench_tables tex file
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript knit-merge.R merge_tables.Rnw one_bench_tables.tex $(LATEST_FOLDER) Methods Blocks
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; python3 process_table_header.py one_bench_tables.tex parsed_one_bench_tables.tex ; rm one_bench_tables.tex

		mv $(PROJECT_FOLDER)/${SRC_ANALYZER}/parsed_one_bench_tables.tex $(REPORT_FOLDER)/parsed_one_bench_tables.tex
		cp $(PROJECT_FOLDER)/${SRC_ANALYZER}/acmart.cls $(REPORT_FOLDER)/acmart.cls 
		cp $(PROJECT_FOLDER)/${SRC_ANALYZER}/paper_template_one.tex $(REPORT_FOLDER)/${benchmark_name}_report.tex

		cd $(REPORT_FOLDER) ; pdflatex $(REPORT_FOLDER)/${benchmark_name}_report.tex ; bibtex *.aux ; bibtex *.aux ; pdflatex $(REPORT_FOLDER)/${benchmark_name}_report.tex

grouped_report:
		$(info [GENERATING analysis reports at $(RUN_FOLDER)...])

		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript knit-merge.R merge_tables.Rnw all_benchs_table.tex $(RUN_FOLDER) Methods Blocks
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; python3 process_table_header.py all_benchs_table.tex parsed_all_benchs_tables.tex ; rm all_benchs_table.tex

		mv $(PROJECT_FOLDER)/${SRC_ANALYZER}/parsed_all_benchs_tables.tex $(RUN_FOLDER)/parsed_all_benchs_tables.tex
		cp $(PROJECT_FOLDER)/${SRC_ANALYZER}/acmart.cls $(RUN_FOLDER)/acmart.cls 
		cp $(PROJECT_FOLDER)/${SRC_ANALYZER}/paper_template_all.tex $(RUN_FOLDER)/all_benchs_report.tex

		cd $(RUN_FOLDER) ; pdflatex $(RUN_FOLDER)/all_benchs_report.tex ; bibtex *.aux ; bibtex *.aux ; pdflatex $(RUN_FOLDER)/all_benchs_report.tex
		cd $(RUN_FOLDER) ; rm *.aux *.out *.log *.bbl *.blg

plots:
		$(info [GENERATING analysis reports at $(REPORT_FOLDER)...])

		mkdir -p $(PLOTS_FOLDER)
		cd $(LATEST_FOLDER) ; tar -I lz4 -xf $(PARSED_INPUT).tar.lz4

		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript generate_plots.Rnw ${benchmark_name} $(PLOTS_FOLDER) $(LATEST_FOLDER)/$(PARSED_INPUT) ${KEEP_STARTUP} $(METHODS)
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript BLOCK_generate_plots.Rnw ${benchmark_name} $(PLOTS_FOLDER)/Blocks $(LATEST_FOLDER)/$(PARSED_INPUT) ${KEEP_STARTUP} $(BLOCKS)

		cd $(LATEST_FOLDER) ; tar --remove-files -I lz4 -cf $(PARSED_INPUT).tar.lz4 $(PARSED_INPUT)


clean:
		cd $(REPORT_FOLDER) ; rm *.aux *.out *.log *.bbl *.blg
		

