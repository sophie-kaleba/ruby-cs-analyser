PROJECT_FOLDER := $(PWD)
SRC_TR := truffleruby
SRC_MX := mx
SRC_GRAAL := graal
SRC_ANALYZER := behaviour-analysis
SRC_RESULTS := results

JT = $(PROJECT_FOLDER)/$(SRC_TR)/bin/jt
#JT := $(PROJECT_FOLDER)/$(SRC_TR)/tool/jt.rb
GRAAL_BRANCH := "dls/test-fail"
TR_BRANCH := "update-truby"
ANALYZER_BRANCH := "switch-to-data-table"

EXE_FLAGS := --monitor-calls=true --monitor-startup=true --splitting --yield-always-clone=false --coverage --coverage.Output=lcov --coverage.OutputFile=./coverage/${benchmark_name}.info

CURRENT_FOLDER := $(PROJECT_FOLDER)/$(SRC_RESULTS)/$(shell date "+%d-%m-%y_%H-%M-%S")/${benchmark_name}
COV_FOLDER := $(CURRENT_FOLDER)/Coverage
LATEST_FOLDER := $(PROJECT_FOLDER)/$(SRC_RESULTS)/latest
LATEST_COV_FOLDER := $(LATEST_FOLDER)/Coverage
REPORT_FOLDER := $(LATEST_FOLDER)/report
PLOTS_FOLDER := $(LATEST_FOLDER)/plots
#SYSTEM_RUBY := /home/sopi/.rbenv/versions/3.0.0/bin/ruby
RAW_INPUT := raw_${benchmark_name}.log
PARSED_INPUT := parsed_${benchmark_name}.log

METHODS := "FALSE"
BLOCKS := "TRUE"

KEEP_STARTUP := "TRUE"
NO_STARTUP := "FALSE"

do_run: run_and_log parse_coverage parse_trace 
do_analyse: analyse_trace 
do_report: report plots clean
init: fetch_deps build_tr
all: fetch_deps build_tr run_and_log parse_coverage parse_trace analyse_trace report plots clean

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
     
run_and_log:
		$(info [RUNNING ${benchmark_name} ...])

		(cd $(PROJECT_FOLDER)/${SRC_TR} ; git fetch --all || true ; git checkout $(TR_BRANCH))
		
		mkdir -p $(CURRENT_FOLDER)
		mkdir -p $(COV_FOLDER)
		ln -vfns $(CURRENT_FOLDER) $(LATEST_FOLDER)

		export SYSTEM_RUBY=${system_ruby} ; $(JT) --use jvm-ce ruby --vm.Dpolyglot.log.file="$(CURRENT_FOLDER)/raw_${benchmark_name}.log"  $(EXE_FLAGS) --coverage.OutputFile=$(COV_FOLDER)/${benchmark_name}.info $(PROJECT_FOLDER)/$(SRC_TR)/bench/phase/harness-behaviour-aux.rb ${benchmark_name} ${iterations} ${inner_iterations} 

parse_coverage:
		$(info [REPORT COVERAGE...])

		lcov --summary $(COV_FOLDER)/${benchmark_name}.info >> $(COV_FOLDER)/${benchmark_name}_cov.txt 2>&1
		lcov --list $(COV_FOLDER)/${benchmark_name}.info >> $(COV_FOLDER)/${benchmark_name}_cov.txt 2>&1

		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; git fetch --all || true ; git checkout $(ANALYZER_BRANCH) ; git pull

		mkdir -p $(COV_FOLDER)/Global
		mkdir -p $(COV_FOLDER)/Detailed
		python3 $(PROJECT_FOLDER)/$(SRC_ANALYZER)/parse_cov_file.py $(COV_FOLDER)/${benchmark_name}_cov.txt $(COV_FOLDER)/Global/${benchmark_name}_global.csv $(COV_FOLDER)/Detailed/${benchmark_name}_detailed.csv

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
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript BLOCK_analyse_and_generate_csv.Rnw ${benchmark_name} $(LATEST_FOLDER)/$(PARSED_INPUT) $(LATEST_FOLDER) ${KEEP_STARTUP} $(BLOCKS)
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript BLOCK_analyse_and_generate_csv.Rnw ${benchmark_name} $(LATEST_FOLDER)/$(PARSED_INPUT) $(LATEST_FOLDER) ${NO_STARTUP} $(BLOCKS)

#		arg1: benchmark name arg2: output folder for generated files arg3:trace file to analyse
		cd $(LATEST_FOLDER) ; tar --remove-files -I lz4 -cf $(PARSED_INPUT).tar.lz4 $(PARSED_INPUT)
		  
report:
		$(info [GENERATING analysis reports at $(REPORT_FOLDER)...])

		mkdir -p $(REPORT_FOLDER)
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript knit.R generate_report.Rnw withstartup_method_tables.tex $(LATEST_COV_FOLDER)/Global $(LATEST_FOLDER)/Methods/General $(LATEST_FOLDER)/Methods/Details $(REPORT_FOLDER) ${KEEP_STARTUP} $(METHODS)
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript knit.R generate_report.Rnw method_tables.tex $(LATEST_COV_FOLDER)/Global $(LATEST_FOLDER)/Methods/NoStartup/General $(LATEST_FOLDER)/Methods/NoStartup/Details $(REPORT_FOLDER) ${NO_STARTUP} $(METHODS)

		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript knit.R BLOCK_generate_report.Rnw withstartup_block_tables.tex $(LATEST_COV_FOLDER)/Global $(LATEST_FOLDER)/Blocks/General $(LATEST_FOLDER)/Blocks/Details $(REPORT_FOLDER)
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript knit.R BLOCK_generate_report.Rnw block_tables.tex $(LATEST_COV_FOLDER)/Global $(LATEST_FOLDER)/Blocks/NoStartup/General $(LATEST_FOLDER)/Blocks/NoStartup/Details $(REPORT_FOLDER)  
#		arg1: csv files location arg2: report location
#		will generate the report in place, it will need to be moved in the relevant folder, and also generates the tex tables

		mv $(PROJECT_FOLDER)/${SRC_ANALYZER}/method_tables.tex $(REPORT_FOLDER)/method_tables.tex
		mv $(PROJECT_FOLDER)/${SRC_ANALYZER}/withstartup_method_tables.tex $(REPORT_FOLDER)/withstartup_method_tables.tex
		mv $(PROJECT_FOLDER)/${SRC_ANALYZER}/block_tables.tex $(REPORT_FOLDER)/block_tables.tex
		mv $(PROJECT_FOLDER)/${SRC_ANALYZER}/withstartup_block_tables.tex $(REPORT_FOLDER)/withstartup_block_tables.tex

		cp $(PROJECT_FOLDER)/${SRC_ANALYZER}/acmart.cls $(REPORT_FOLDER)/acmart.cls 
		cp $(PROJECT_FOLDER)/${SRC_ANALYZER}/paper.tex $(REPORT_FOLDER)/${benchmark_name}_report.tex

		cd $(REPORT_FOLDER) ; pdflatex $(REPORT_FOLDER)/${benchmark_name}_report.tex ; bibtex *.aux ; bibtex *.aux ; pdflatex $(REPORT_FOLDER)/${benchmark_name}_report.tex

plots:
		$(info [GENERATING analysis reports at $(REPORT_FOLDER)...])

		mkdir -p $(PLOTS_FOLDER)
		cd $(LATEST_FOLDER) ; tar -I lz4 -xf $(PARSED_INPUT).tar.lz4

		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript generate_plots.Rnw ${benchmark_name} $(PLOTS_FOLDER) $(LATEST_FOLDER)/$(PARSED_INPUT) ${KEEP_STARTUP} $(METHODS)
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript BLOCK_generate_plots.Rnw ${benchmark_name} $(PLOTS_FOLDER)/Blocks $(LATEST_FOLDER)/$(PARSED_INPUT) ${KEEP_STARTUP} $(BLOCKS)

		cd $(LATEST_FOLDER) ; tar --remove-files -I lz4 -cf $(PARSED_INPUT).tar.lz4 $(PARSED_INPUT)

clean:
		cd $(REPORT_FOLDER) ; rm *.aux *.out *.log *.bbl *.blg

