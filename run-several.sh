#!/bin/bash

TRUBY=("Acid"
	  "AsciidoctorConvertSmall" 
	  "AsciidoctorLoadFileSmall"
	  "ImageDemoConv"
	  "ImageDemoSobel"
	  "OptCarrot"
	  "MatrixMultiply"
	  "Pidigits"
 	  "RedBlack" #Bigger benchmark, may need to be run on a more powerful machine
	  "SinatraHello"
)

AWFY=("BinaryTrees"
	  "Bounce"
	  #"CD" see bottom -> Bigger benchmark, may need to be run on a more powerful machine
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

YJIT=("HexaPdfSmall" #Bigger benchmark, may need to be run on a more powerful machine
	  "LiquidCartParse" 
	  "LiquidCartRender" 
	  "LiquidMiddleware"
	  "LiquidParseAll"
	  "LiquidRenderBibs"
	  "MailBench"
	 # "RubykonBench" #Bigger benchmark, may need to be run on a more powerful machine
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
		#"ChunkyOperationsCompose" #Bigger benchmark, may need to be run on a more powerful machine
		#"ChunkyOperationsReplace" #Bigger benchmark, may need to be run on a more powerful machine
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
	#"PsdImagemodeCmykCombineCmykChannel" #Bigger benchmark, may need to be run on a more powerful machine
	 "PsdImagemodeGreyscaleCombineGreyscaleChannel"
	 "PsdImagemodeRgbCombineRgbChannel"
	 #"PsdRendererBlenderCompose" #Bigger benchmark, may need to be run on a more powerful machine
	 #"PsdRendererClippingmaskApply" #Bigger benchmark, may need to be run on a more powerful machine
	 #"PsdRendererMaskApply" #Bigger benchmark, may need to be run on a more powerful machine
	 "PsdUtilClamp"
	 "PsdUtilPad2"
	 "PsdUtilPad4"
)

MEGA=("BlogRailsRoutesTwoRoutesTwoRequests"
	  "ERubiRails"
	  "HexaPdfSmall" #Bigger benchmark, may need to be run on a more powerful machine
	  "LiquidCartParse" 
	  "LiquidCartRender" 
	  "LiquidMiddleware"
	  "LiquidParseAll"
	  "LiquidRenderBibs"
	  "MailBench"
	  "SinatraHello"
)

PROJECT_FOLDER=$(pwd)
SRC_RESULTS=results
FOLDER=$(date "+%d-%m-%y_%H-%M-%S")

make init

for b in ${TRUBY[@]}; do
	make do_run do_analyse benchmark_name=$b iterations="1" inner_iterations="1" run_folder=$FOLDER
	wait $!
done

for b in ${AWFY[@]}; do
	make do_run do_analyse benchmark_name=$b iterations="1" inner_iterations="1" run_folder=$FOLDER
	wait $!
done

for b in ${YJIT[@]}; do
	make do_run do_analyse benchmark_name=$b iterations="1" inner_iterations="1" run_folder=$FOLDER
	wait $!
done

for b in ${RAILS[@]}; do
	make do_run do_analyse benchmark_name=$b iterations="1" inner_iterations="1" run_folder=$FOLDER
	wait $!
done

for b in ${CHUNKY[@]}; do
	make do_run do_analyse benchmark_name=$b iterations="1" inner_iterations="1" run_folder=$FOLDER
	wait $!
done

for b in ${PSD[@]}; do
	make do_run do_analyse benchmark_name=$b iterations="1" inner_iterations="1" run_folder=$FOLDER
	wait $!
done

#must have more memory
#TODO - add the special flag for memory!
make do_run do_analyse benchmark_name="Havlak" iterations="1" inner_iterations="1" run_folder=$FOLDER

# is special regarding the number of inner iterations
make do_run do_analyse benchmark_name="CD" iterations="1" inner_iterations="250" run_folder=$FOLDER

# all the benchmarks have been analysed, generate the summary report
make grouped_report run_folder=$FOLDER