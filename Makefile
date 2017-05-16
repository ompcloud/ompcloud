RELEASE_ARGS=$(filter-out $@,$(MAKECMDGOALS))

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))

all: ompcloud-install-dep.sh ompcloud-install-release.sh
	./ompcloud-install-dep.sh
	./ompcloud-install-release.sh -i ${RELEASE_ARGS}

release-linux64: ompcloud-install-dep.sh ompcloud-install-release.sh
	docker run -t -i --rm -v $(current_dir):/io ubuntu:16.04 /bin/bash -c "/io/ompcloud-install-dep.sh; /io/ompcloud-install-release.sh -r ${RELEASE_ARGS}"
