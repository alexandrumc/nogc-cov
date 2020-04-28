all: worker master

worker:
	dub build nogcov:worker

master:
	dub build nogcov:master

clean:
	rm -rf nogcov_* results/

tutorial:
	@echo "Run: ./nogcov_master target target_imports druntimeImports \n\n \
	target = file or directory to analyze \n \
	target_imports = directory where files imported by @target are placed \n \
	druntimeImports = path to the imports/ folder of the druntime \n"

