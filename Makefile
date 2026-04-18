IMAGE ?= blockchain-bitmlx:dev

.PHONY: docker-build bootstrap compile compile-all test clean

docker-build:
	docker build -t $(IMAGE) -f docker/Dockerfile .

bootstrap: docker-build
	IMAGE=$(IMAGE) ./scripts/docker_run.sh ./scripts/bootstrap.sh

compile: docker-build
	@if [ -z "$(EXAMPLE)" ]; then echo "EXAMPLE is required (e.g. EXAMPLE=ReceiverChosenDenomination)"; exit 2; fi
	IMAGE=$(IMAGE) ./scripts/docker_run.sh "./scripts/bootstrap.sh && ./scripts/bitmlx_pipeline.sh $(EXAMPLE)"

compile-all: docker-build
	IMAGE=$(IMAGE) ./scripts/docker_run.sh "./scripts/bootstrap.sh && ./scripts/bitmlx_pipeline.sh all"

test: docker-build
	IMAGE=$(IMAGE) ./scripts/docker_run.sh "./scripts/bootstrap.sh && /home/codex/.local/venv/bin/python -m pytest -q"

clean:
	rm -f vendor/BitMLx/output/*.balzac vendor/BitMLx/output/*_depth.txt vendor/BitMLx/output/statistics.txt
