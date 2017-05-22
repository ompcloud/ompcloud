RELEASE_ARGS=$(filter-out $@,$(MAKECMDGOALS))

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))

all: ompcloud-install-dep.sh ompcloud-install.sh
	./install/ompcloud-install-dep.sh
	./install/ompcloud-install.sh -i ${RELEASE_ARGS}

release-linux64: ompcloud-install-dep.sh ompcloud-install.sh
	docker run -t -i --rm -v $(current_dir):/io ubuntu:16.04 /bin/bash -c "/io/install/ompcloud-install-dep.sh; /io/install/ompcloud-install.sh -r; /io/release/ompcloud-make-release.sh ${RELEASE_ARGS}"
