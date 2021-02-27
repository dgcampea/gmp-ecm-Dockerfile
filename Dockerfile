# Dockerfile for gmp-ecm
# These images are NOT portable

#
#### compile time image
#
FROM registry.fedoraproject.org/fedora-minimal:33 AS build

ARG BUILDER_THREADS=1
ARG PREFIX=/app

ARG GMP_VER
ARG ECM_COMMIT

ARG REDISTRIBUTABLE=yes
ARG GWNUM_VER=303b6


RUN microdnf -y update && microdnf -y install git gcc-c++ libgomp \
                make autoconf libtool m4 xz unzip \
        && microdnf clean all \
        && mkdir ${PREFIX}

# gmp-ecm source
WORKDIR /tmp
RUN git clone --depth 1 https://gitlab.inria.fr/zimmerma/ecm.git

# gmplib
WORKDIR /tmp
ADD https://gmplib.org/download/gmp/gmp-${GMP_VER}.tar.xz gmp-${GMP_VER}.tar.xz
RUN tar -xf gmp-${GMP_VER}.tar.xz && cd gmp-${GMP_VER} \
        && mkdir builddir && cd builddir \
        && ../configure --prefix=${PREFIX} \
        && make -j ${BUILDER_THREADS} && make check \
        && make install

# gmp-ecm (redistributable)
WORKDIR /tmp/ecm
RUN git checkout ${ECM_COMMIT} \
        && autoreconf -vfi \
        && CFLAGS='-flto -mtune=native -march=native' ./configure --prefix=${PREFIX} \
                --with-gmp=${PREFIX} --enable-openmp --disable-assert \
        && make -j ${BUILDER_THREADS} && make check \
        && make install && make distclean

######## GWNUM + GMP-ECM section ########

# gwnum
# sed to insert location for gmplib
WORKDIR /tmp
RUN \
        if [ ${REDISTRIBUTABLE} != "yes" ] ; then \
                curl -O https://www.mersenne.org/ftp_root/gimps/p95v${GWNUM_VER}.source.zip \
                && unzip -q -d p95v${GWNUM_VER}.source p95v${GWNUM_VER}.source.zip \
                && cd p95v${GWNUM_VER}.source/gwnum \
                && sed -r -i "s#^(CFLAGS =)#\1 -I${PREFIX}/include#" make64 \
                && make -f make64 ; \
        fi

# gmp-ecm + gwnum (non-redistributable)
WORKDIR /tmp/ecm
RUN \
        if [ ${REDISTRIBUTABLE} != "yes" ] ; then \
        autoreconf -vfi \
        && CFLAGS='-flto -mtune=native -march=native' ./configure --prefix=${PREFIX} \
                --with-gmp=${PREFIX} --with-gwnum="/tmp/p95v${GWNUM_VER}.source/gwnum" \
                --program-prefix="gwnum-" --disable-assert \
        && make -j ${BUILDER_THREADS}; make libecm-la; make \
        && make install ; \
        fi
######## END GWNUM + GMP-ECM section ########


#
#### runtime image
#
FROM registry.fedoraproject.org/fedora-minimal:33

RUN microdnf -y update && microdnf -y install libgomp && microdnf clean all

ARG PREFIX=/app

COPY --from=build ${PREFIX} ${PREFIX}

WORKDIR /host
ENTRYPOINT ["/app/bin/ecm"]
CMD ["-h"]
