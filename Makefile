all: worker master

worker:
	dub build nogcov:worker

master:
	dub build nogcov:master

translator:
	dub build nogcov:translator
# To use the translator, you first have to clone this https://github.com/dlang/dlang.org.git repo

clean:
	rm -rf nogcov_* results/
	rm -rf combined.json

run_phobos:
	./nogcov_master ../phobos/std/ ../phobos/ ../dmd/druntime/src

run_test:
	./nogcov_master tests/ tests/ ../dmd/druntime/src

run_file_example:
	./nogcov_master ../phobos/std/algorithm/comparison.d ../phobos/ ../dmd/druntime/src
# Then look into 'combined.json' or 'results/std.algorithm.comparison.json'.
# 'combined.json' aggregates the results from multiple files, while in the 'results' directory one can see
# the resulted .json file for each D module.

tutorial:
	@echo "Run: ./nogcov_master target target_imports druntimeImports \n\n \
	target = file or directory to analyze \n \
	target_imports = directory where files imported by @target are placed \n \
	druntimeImports = path to the imports/ folder of the druntime \n"

