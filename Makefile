all: worker master

worker:
	dub build nogcov:worker

master:
	dub build nogcov:master

translator:
	dub build nogcov:translator

clean:
	rm -rf nogcov_* results/
	rm -rf combined.json

run_phobos:
	./nogcov_master ../phobos/std/ ../phobos/ ../druntime/import/

run_test:
	./nogcov_master tests/ tests/ ../druntime/import/

tutorial:
	@echo "Run: ./nogcov_master target target_imports druntimeImports \n\n \
	target = file or directory to analyze \n \
	target_imports = directory where files imported by @target are placed \n \
	druntimeImports = path to the imports/ folder of the druntime \n"

