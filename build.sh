#!/bin/bash -eu
ARCH="${BOOTMAKER_ARCH:-$(uname -m)}"
DOCKERIMAGE="${BOOTMAKER_DOCKERIMAGE:-ipmitool_builder}"
WORKDIR="${BOOTMAKER_WORKDIR:-.}"

. "assets/init/functions"

einfo "Starting Image Builder"

case "${ARCH}" in
    x86_64)
        CROSS_TRIPLE="x86_64-linux-gnu"
        ALPINE_VERSION="latest-stable"
        DEB_ARCH="amd64"
        DI_DIST="xenial"
        ;;
    aarch64)
        CROSS_TRIPLE="aarch64-linux-gnu"
        ALPINE_VERSION="v3.5"
        DEB_ARCH="arm64"
        DI_DIST="xenial"
        ;;
    armhf)
        CROSS_TRIPLE="arm-linux-gnueabihf"
        ALPINE_VERSION="latest-stable"
        DEB_ARCH="armhf"
        DI_DIST="xenial"
        ;;
    *)
        eerror "Architecture not supported: ${ARCH}"
        exit 1
        ;;
esac
esuccess "Build Architecture: ${ARCH}"

einfo "Generating Dockerfile"
cat Dockerfile.template \
    | sed -e "s/%%ARCH%%/${ARCH}/g" \
          -e "s/%%CROSS_TRIPLE%%/${CROSS_TRIPLE}/g" \
          -e "s/%%ALPINE_VERSION%%/${ALPINE_VERSION}/g" \
          -e "s/%%DEB_ARCH%%/${DEB_ARCH}/g" \
          -e "s/%%DI_DIST%%/${DI_DIST}/g" \
    > Dockerfile."${ARCH}"

einfo "Creating build dir"
output_dir="${WORKDIR}/ipmitool-${ARCH}"
[ -d "${output_dir}" ] || mkdir "${output_dir}"

einfo "Building container"
BUILD_ARGS=""

docker build \
    $BUILD_ARGS \
    -f "Dockerfile.${ARCH}" -t "${DOCKERIMAGE}:${ARCH}" .

einfo "Starting container"
container_id=$(docker run --rm -v "$(pwd)/${output_dir}:/workdir" "${DOCKERIMAGE}:${ARCH}")

einfo "Removing temporary files"
rm -f "Dockerfile.${ARCH}"

einfo "Finished"
