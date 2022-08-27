#!/bin/bash

TRUBY=("Acid"
	  "AsciidoctorConvertSmall" 
	  "AsciidoctorLoadFileSmall"
	  "ImageDemoConv"
	  "ImageDemoSobel"
	  "OptCarrot"
	  "MatrixMultiply"
	  "Pidigits"
	  #"RedBlack" slighlty too big for report
	  "SinatraHello"
)

AWFY=("BinaryTrees"
	  "Bounce"
	  #"CD" see bottom -> Should be analyzed on the big boy
	  "DeltaBlue" 
	  "FannkuchRedux"
	  #"Havlak" see bottom: need bigger stack size
	  "Json"
	  "LeeBench"
	  "List"
	  "Mandelbrot"
	  "NBody"
	  "NeuralNet"
	  "Permute"
	  "PsychLoad"
	  "Queens"
	  "Richards"
	  "Sieve"
	  "SpectralNorm"
	  "Storage"
	  "Towers"
)

YJIT=("HexaPdfSmall" #-> Should be analyzed on the big boy
	  "LiquidCartParse" 
	  "LiquidCartRender" 
	  "LiquidMiddleware"
	  "LiquidParseAll"
	  "LiquidRenderBibs"
	  "MailBench"
	 # "RubykonBench" #Too big
)

RAILS=("BlogRailsRoutesTwoRoutesTwoRequests"
	   "ERubiRails" 
)

 CHUNKY=("ChunkyCanvasResamplingBilinear"
	    "ChunkyCanvasResamplingNearestNeighbor"
		"ChunkyCanvasResamplingSteps"
		"ChunkyCanvasResamplingStepsResidues"
		"ChunkyColorA"
		"ChunkyColorB"
		"ChunkyColorComposeQuick"
		"ChunkyColorG"
		"ChunkyColorR"
		"ChunkyDecodePngImagePass"
		#"ChunkyOperationsCompose" -> Should be analyzed on the big boy
		#"ChunkyOperationsReplace"
)

PSD=("PsdColorCmykToRgb"
	 "PsdComposeColorBurn"
	 "PsdComposeColorDodge"
	 "PsdComposeDarken"
	 "PsdComposeDifference"
	 "PsdComposeExclusion"
	 "PsdComposeHardLight"
	 "PsdComposeHardMix"
	 "PsdComposeLighten"
	 "PsdComposeLinearBurn"
	 "PsdComposeLinearDodge"
	 "PsdComposeLinearLight"
	 "PsdComposeMultiply"
	 "PsdComposeNormal"
	 "PsdComposeOverlay"
	 "PsdComposePinLight"
	 "PsdComposeScreen"
	 "PsdComposeSoftLight"
	 "PsdComposeVividLight"
	 "PsdImageformatLayerrawParseRaw"
	 "PsdImageformatRleDecodeRleChannel"
	#"PsdImagemodeCmykCombineCmykChannel" too big
	 "PsdImagemodeGreyscaleCombineGreyscaleChannel"
	 "PsdImagemodeRgbCombineRgbChannel"
	 #"PsdRendererBlenderCompose" -> Should be analyzed on the big boy
	 #"PsdRendererClippingmaskApply" -> Should be analyzed on the big boy
	 #"PsdRendererMaskApply" -> Should be analyzed on the big boy
	 "PsdUtilClamp"
	 "PsdUtilPad2"
	 "PsdUtilPad4"
)


PROJECT_FOLDER=$(pwd)
SRC_RESULTS=results
#FOLDER=$PROJECT_FOLDER/$SRC_RESULTS/$(date "+%d-%m-%y_%H-%M-%S")/
FOLDER=$PROJECT_FOLDER/$SRC_RESULTS/11-08-22_18-49-42/
#mkdir $FOLDER

# for b in ${TRUBY[@]}; do
#     BENCH_FOLDER=$FOLDER/$b
#     mkdir $BENCH_FOLDER
# 	make do_run do_analyse report clean benchmark_name=$b iterations="1" inner_iterations="1" bench_folder=$BENCH_FOLDER
# 	wait $!
# done

# for b in ${AWFY[@]}; do
#     BENCH_FOLDER=$FOLDER/$b
#     mkdir $BENCH_FOLDER
# 	make do_run do_analyse report clean benchmark_name=$b iterations="1" inner_iterations="1" bench_folder=$BENCH_FOLDER
# 	wait $!
# done

# for b in ${YJIT[@]}; do
#     BENCH_FOLDER=$FOLDER/$b
#     mkdir -p $BENCH_FOLDER
# 	make do_run do_analyse report clean benchmark_name=$b iterations="1" inner_iterations="1" bench_folder=$BENCH_FOLDER
# 	wait $!
# done

# for b in ${RAILS[@]}; do
#     BENCH_FOLDER=$FOLDER/$b
#     mkdir -p $BENCH_FOLDER
# 	make do_run do_analyse report clean benchmark_name=$b iterations="1" inner_iterations="1" bench_folder=$BENCH_FOLDER
# 	wait $!
# done

# for b in ${CHUNKY[@]}; do
#     BENCH_FOLDER=$FOLDER/$b
#     mkdir -p $BENCH_FOLDER
# 	make do_run do_analyse report clean benchmark_name=$b iterations="1" inner_iterations="1" bench_folder=$BENCH_FOLDER
# 	wait $!
# done

# for b in ${PSD[@]}; do
#     BENCH_FOLDER=$FOLDER/$b
#     mkdir -p $BENCH_FOLDER
# 	make do_run do_analyse report clean benchmark_name=$b iterations="1" inner_iterations="1" bench_folder=$BENCH_FOLDER
# 	wait $!
# done

#must have more memory
# FOLDER=$PROJECT_FOLDER/$SRC_RESULTS/11-08-22_18-49-42/
# BENCH_FOLDER=$FOLDER/Havlak
# mkdir -p $BENCH_FOLDER
# make do_run do_analyse report clean benchmark_name="Havlak" iterations="1" inner_iterations="1" bench_folder=$BENCH_FOLDER

# is special regarding the number of inner iterations
# FOLDER=$PROJECT_FOLDER/$SRC_RESULTS/11-08-22_18-49-42/
# BENCH_FOLDER=$FOLDER/CD
# mkdir -p $BENCH_FOLDER
# make do_run do_analyse report clean benchmark_name="CD" iterations="1" inner_iterations="250" bench_folder=$BENCH_FOLDER

FOLDER=$PROJECT_FOLDER/$SRC_RESULTS/11-08-22_18-49-42
BENCH_FOLDER=$FOLDER/RecursiveSplitting
mkdir -p $BENCH_FOLDER
make run_and_log parse_trace do_analyse report clean benchmark_name="RecursiveSplitting" bench_folder=$BENCH_FOLDER