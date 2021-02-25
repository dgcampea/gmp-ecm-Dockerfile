GMP_VER=6.2.1
GWNUM_VER=303b6

ifdef ECM_COMMIT
	LATEST=no
else
	LATEST=yes
	ECM_COMMIT=$(shell git ls-remote https://gitlab.inria.fr/zimmerma/ecm.git HEAD | awk '{ print $$1 }')
	ifeq ($(ECM_COMMIT),)
		ECM_COMMIT = HEAD
	endif
endif

BUILDER_THREADS=$(shell grep -c ^processor /proc/cpuinfo)
ifeq ($(BUILDER_THREADS),)
	BUILDER_THREADS=1
endif

.PHONY: redistrib non-redistrib

redistrib:
	podman build  -f Dockerfile --tag gmp-ecm:${ECM_COMMIT} \
	  --build-arg BUILDER_THREADS=${BUILDER_THREADS} \
	  --build-arg ECM_COMMIT=${ECM_COMMIT} \
	  --build-arg GMP_VER=${GMP_VER}
ifeq ($(LATEST),yes)
	podman tag gmp-ecm:${ECM_COMMIT} gmp-ecm:latest
endif
	install -m755 -t "${HOME}"/.local/bin ecm-wrapper.sh

non-redistrib:
	podman build  -f Dockerfile --tag gmp-ecm:${ECM_COMMIT} \
	  --build-arg BUILDER_THREADS=${BUILDER_THREADS} \
	  --build-arg GMP_VER=${GMP_VER} \
	  --build-arg ECM_COMMIT=${ECM_COMMIT} \
	  --build-arg GWNUM_VER=${GWNUM_VER} \
	  --build-arg REDISTRIBUTABLE="no"
ifeq ($(LATEST),yes)
	podman tag gmp-ecm:${ECM_COMMIT} gmp-ecm:latest
endif
	install -m755 -t "${HOME}"/.local/bin ecm-wrapper.sh
	ln -s "${HOME}"/.local/bin/ecm-wrapper.sh "${HOME}"/.local/bin/ecm-gwnum-wrapper.sh
