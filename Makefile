PROJECT_FOLDER := $(PWD)
SRC_TR := truffleruby
SRC_MX := mx
SRC_GRAAL := graal
SRC_ANALYZER := behaviour-analysis
SRC_RESULTS := results

JT = $(PROJECT_FOLDER)/$(SRC_TR)/bin/jt
#JT := $(PROJECT_FOLDER)/$(SRC_TR)/tool/jt.rb
GRAAL_BRANCH := "dls/fetchID"
TR_BRANCH := "update-truby"
ANALYZER_BRANCH := "switch-to-data-table"

EXE_FLAGS := --splitting --coverage --coverage.Output=lcov --coverage.OutputFile=./coverage/${benchmark_name}.info

CURRENT_FOLDER := $(PROJECT_FOLDER)/$(SRC_RESULTS)/$(shell date "+%d-%m-%y_%H-%M-%S")/${benchmark_name}
COV_FOLDER := $(CURRENT_FOLDER)/Coverage
LATEST_FOLDER := $(PROJECT_FOLDER)/$(SRC_RESULTS)/latest
LATEST_COV_FOLDER := $(LATEST_FOLDER)/Coverage
REPORT_FOLDER := $(LATEST_FOLDER)/report
PLOTS_FOLDER := $(LATEST_FOLDER)/plots
SYSTEM_RUBY := /home/sopi/.rbenv/versions/3.0.0/bin/ruby
RAW_INPUT := raw_${benchmark_name}.log
PARSED_INPUT := parsed_${benchmark_name}.log

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
		cd $(PROJECT_FOLDER)/$(SRC_TR) ; $(SYSTEM_RUBY) ${JT} build --sforceimports --env jvm-ce

		cd $(PROJECT_FOLDER)/$(SRC_ANALYZER)/splitting-transition/src ; javac *.java
     
run_and_log:
		$(info [RUNNING ${benchmark_name} ...])

		(cd $(PROJECT_FOLDER)/${SRC_TR} ; git fetch --all || true ; git checkout $(TR_BRANCH))
		
		mkdir -p $(CURRENT_FOLDER)
		mkdir -p $(COV_FOLDER)
		ln -vfns $(CURRENT_FOLDER) $(LATEST_FOLDER)

		export SYSTEM_RUBY=$(SYSTEM_RUBY) ; $(JT) --use jvm-ce ruby --vm.Dpolyglot.log.file="$(CURRENT_FOLDER)/raw_${benchmark_name}.log"  $(EXE_FLAGS) --coverage.OutputFile=$(COV_FOLDER)/${benchmark_name}.info $(PROJECT_FOLDER)/$(SRC_TR)/bench/phase/harness-behaviour.rb ${benchmark_name} ${iterations} ${inner_iterations} 

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

		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript analyse_and_generate_csv.Rnw ${benchmark_name} $(LATEST_FOLDER) $(LATEST_FOLDER)/$(PARSED_INPUT)
#		arg1: benchmark name arg2: output folder for generated files arg3:trace file to analyse
		cd $(LATEST_FOLDER) ; tar --remove-files -I lz4 -cf $(PARSED_INPUT).tar.lz4 $(PARSED_INPUT)
		  
report:
		$(info [GENERATING analysis reports at $(REPORT_FOLDER)...])

		mkdir -p $(REPORT_FOLDER)
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript knit.R generate_report.Rnw tables.tex $(LATEST_FOLDER)/General $(LATEST_COV_FOLDER)/Global $(REPORT_FOLDER)
#arg1: csv files location arg2: report location
#will generate the report in place, it will need to be moved in the relevant folder
#it also generates all the tex tables
		mv $(PROJECT_FOLDER)/${SRC_ANALYZER}/tables.tex $(REPORT_FOLDER)/tables.tex
		cp $(PROJECT_FOLDER)/${SRC_ANALYZER}/acmart.cls $(REPORT_FOLDER)/acmart.cls 
		cp $(PROJECT_FOLDER)/${SRC_ANALYZER}/paper.tex $(REPORT_FOLDER)/${benchmark_name}_report.tex	

		cd $(REPORT_FOLDER) ; pdflatex $(REPORT_FOLDER)/${benchmark_name}_report.tex ; pdflatex $(REPORT_FOLDER)/${benchmark_name}_report.tex

plots:
		$(info [GENERATING analysis reports at $(REPORT_FOLDER)...])

		mkdir -p $(PLOTS_FOLDER)
		cd $(LATEST_FOLDER) ; tar -I lz4 -xf $(PARSED_INPUT).tar.lz4
		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript generate_plots.Rnw ${benchmark_name} $(PLOTS_FOLDER) $(LATEST_FOLDER)/$(PARSED_INPUT)
		cd $(LATEST_FOLDER) ; tar --remove-files -I lz4 -cf $(PARSED_INPUT).tar.lz4 $(PARSED_INPUT)

reorganize:
#	mkdir ./${FOLDER}/${benchmark_name}
		tar --remove-files -I lz4 -cf $(PARSED_INPUT).mylog.tar.lz4 $(PARSED_INPUT).mylog
		mv $(SPLIT_SUMMARY).mylog ${FOLDER}/${benchmark_name}/$(SPLIT_SUMMARY).mylog
#	mv $(PARSED_INPUT).tex latest/$(PARSED_INPUT).tex
		mv $(RAW_INPUT).tar.lz4 ${FOLDER}/${benchmark_name}/$(RAW_INPUT).tar.lz4
		mv $(PARSED_INPUT).mylog.tar.lz4 ${FOLDER}/${benchmark_name}/$(PARSED_INPUT).mylog.tar.lz4
#	mv $(PARSED_INPUT).pdf latest/$(PARSED_INPUT).pdf
#	mv gen-eval.tex latest/gen-eval.tex
#	mv ${benchmark_name}_splitting_data.csv latest/${benchmark_name}_splitting_data.csv
#	mv out_${benchmark_name}_splitting_data.csv latest/out_${benchmark_name}_splitting_data.csv

clean:
		cd $(REPORT_FOLDER) ; rm *.aux *.out *.log

