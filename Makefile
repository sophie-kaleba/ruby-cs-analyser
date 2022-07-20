PROJECT_FOLDER := $(PWD)
SRC_TR := truffleruby
SRC_MX := mx
SRC_GRAAL := graal
SRC_ANALYZER := behaviour-analysis
SRC_RESULTS := results

#JT = $(SRC_TR)/bin/jt
JT := $(PROJECT_FOLDER)/$(SRC_TR)/tool/jt.rb
TR_BRANCH := "update-truby"
ANALYZER_BRANCH := "switch-to-data-table"
EXE_FLAGS := --splitting

CURRENT_FOLDER := $(PROJECT_FOLDER)/$(SRC_RESULTS)/$(shell date "+%d-%m-%y_%H-%M-%S")
LATEST_FOLDER := $(PROJECT_FOLDER)/$(SRC_RESULTS)/latest
REPORT_FOLDER := $(LATEST_FOLDER)/report
SYSTEM_RUBY := /home/sopi/.rbenv/versions/3.0.0/bin/ruby
RAW_INPUT := raw_${benchmark_name}.log
PARSED_INPUT := parsed_${benchmark_name}.log

fetch_deps:
		$(info [FETCHING graal anx mx...])
		cd $(PROJECT_FOLDER)/$(SRC_GRAAL) || git clone https://github.com/oracle/graal.git
		cd $(PROJECT_FOLDER)/$(SRC_MX) || git clone https://github.com/graalvm/mx.git

		export GIT_DIR=$(PROJECT_FOLDER)/$(SRC_GRAAL)/.git ; git config remote.custom-graal.url >&- || git remote add custom-graal https://github.com/sophie-kaleba/truffle.git
		git -C $(PROJECT_FOLDER)/$(SRC_GRAAL) fetch --all || true
		git -C $(PROJECT_FOLDER)/$(SRC_MX) pull || true

		$(info [FETCHING truffleruby ...])
		cd $(PROJECT_FOLDER)/$(SRC_TR) || git clone https://github.com/oracle/truffleruby.git
		export GIT_DIR=$(PROJECT_FOLDER)/$(SRC_TR)/.git ; git config remote.custom-tr.url >&- || git remote add custom-tr https://github.com/sophie-kaleba/truffleruby.git
		git -C $(PROJECT_FOLDER)/$(SRC_TR) fetch --all || true

		$(info [FETCHING Ruby analyser ...])
		cd $(PROJECT_FOLDER)/$(SRC_ANALYZER) || git clone https://github.com/sophie-kaleba/behaviour-analysis.git
		git -C $(PROJECT_FOLDER)/$(SRC_ANALYZER) fetch --all || true

build_tr: 
		$(info [BUILDING TruffleRuby and Java splitting analyser ...])
		
		export GIT_DIR=$(PROJECT_FOLDER)/${SRC_TR}/.git ; git checkout $(TR_BRANCH)	
		cd $(PROJECT_FOLDER)/$(SRC_TR) ; $(SYSTEM_RUBY) ${JT} build --sforceimports --env jvm-ce

		cd $(PROJECT_FOLDER)/$(SRC_ANALYZER)/splitting-transition/src ; javac *.java
     
run_and_log:
		$(info [RUNNING ${benchmark_name} ...])

		(cd $(PROJECT_FOLDER)/${SRC_TR} ; git fetch --all || true ; git checkout $(TR_BRANCH))
		
		mkdir -p $(CURRENT_FOLDER)
		ln -vfns $(CURRENT_FOLDER) $(LATEST_FOLDER)

		$(SYSTEM_RUBY) $(JT) --use jvm-ce ruby --vm.Dpolyglot.log.file="$(CURRENT_FOLDER)/raw_${benchmark_name}.log"  $(EXE_FLAGS) $(PROJECT_FOLDER)/$(SRC_TR)/bench/phase/harness-behaviour.rb ${benchmark_name} ${iterations} ${inner_iterations} 

parse_trace:
		$(info [PARSING execution trace ...])

		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; git fetch --all || true ; git checkout $(ANALYZER_BRANCH)

		cd $(LATEST_FOLDER) ; python3 $(PROJECT_FOLDER)/$(SRC_ANALYZER)/parse_execution_trace.py $(RAW_INPUT) $(PARSED_INPUT)

		$(info [COMPRESS execution trace ...])
		cd $(LATEST_FOLDER) ; tar --remove-files -I lz4 -cf $(RAW_INPUT).tar.lz4 $(RAW_INPUT)

analyse_trace:
		$(info [ANALYSING execution trace, summary tables saved in $(LATEST_FOLDER)...])

		cd $(PROJECT_FOLDER)/${SRC_ANALYZER} ; Rscript analyse_and_generate_csv.Rnw ${benchmark_name} $(LATEST_FOLDER) $(LATEST_FOLDER)/$(PARSED_INPUT)
#		arg1: benchmark name arg2: output folder for generated files arg3:trace file to analyse
		  
report:
		$(info [GENERATING analysis report at ...])

		cd $(PROJECT_FOLDER)/${SRC_ANALYZER}
#arg1: csv files location arg2: report location
#will generate the report in place, it will need to be moved in the relevant folder
		Rscript knit.R generate_report.Rnw gen-eval.tex $(LATEST_FOLDER) $(REPORT_FOLDER)
		cp paper.tex $(LATEST_FOLDER)/$(PARSED_INPUT).tex

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
		rm *.aux
		rm *.out
		rm *.log

pdf:
	pdflatex $(PARSED_INPUT).tex
	pdflatex $(PARSED_INPUT).tex
