RELEASE_ARGS=$(filter-out $@,$(MAKECMDGOALS))
#RELEASE_TARBALL=$(shell ls | grep -F ompcloud | grep -F linux-amd64.tar.gz)
#RELEASE_FOLDER=$(firstword $(subst .tar, , ${RELEASE_TARBALL}))

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))

all: ompcloud-install-dep.sh ompcloud-install-release.sh
	./ompcloud-install-dep.sh
	./ompcloud-install-release.sh -i ${RELEASE_ARGS}

release-linux64: ompcloud-install-dep.sh ompcloud-install-release.sh
	docker run -t -i --rm -v $(current_dir):/io ubuntu:latest /bin/bash -c "/io/ompcloud-install-dep.sh; /io/ompcloud-install-release.sh -r ${RELEASE_ARGS}"

#install: ${RELEASE_TARBALL}
#	mkdir ${RELEASE_FOLDER}
#	tar -xvzf ${RELEASE_TARBALL} -C ${RELEASE_FOLDER}
#	${RELEASE_FOLDER}/ompcloud-release-install-ubuntu.sh
