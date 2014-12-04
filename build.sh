#!/bin/bash

# Yay shell scripting! This script builds a static version of
# OpenSSL ${OPENSSL_VERSION} for iOS and OSX that contains code for armv6, armv7, armv7s, arm64, i386 and x86_64.

set -x

# Setup paths to stuff we need

OPENSSL_VERSION="1.0.1j"

DEVELOPER=$(xcode-select --print-path)

IOS_SDK_VERSION=$(xcrun --sdk iphoneos --show-sdk-version)
IOS_DEPLOYMENT_VERSION="6.0"
OSX_SDK_VERSION=$(xcrun --sdk macosx --show-sdk-version)
OSX_DEPLOYMENT_VERSION="10.8"

IPHONEOS_PLATFORM=$(xcrun --sdk iphoneos --show-sdk-platform-path)
IPHONEOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)

IPHONESIMULATOR_PLATFORM=$(xcrun --sdk iphonesimulator --show-sdk-platform-path)
IPHONESIMULATOR_SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)

OSX_PLATFORM=$(xcrun --sdk macosx --show-sdk-platform-path)
OSX_SDK=$(xcrun --sdk macosx --show-sdk-path)

OPENSSL_BUILD_TMP_DIR="/tmp/openssl-build"

BUILD_IOS=0
BUILD_OSX=0
INSTALL_PREFIX=""
OPENSSL_TAR_BALL_DIR="."

OPTIND=1         # Reset in case getopts has been used previously in the shell.

while getopts "h?iop:t:" opt; do
    case "$opt" in
    h|\?)
        echo "-h or -? to show this help text"
        echo "-p <full path> ; install prefix. Defaults to ${INSTALL_PREFIX}"
        echo "               ; will place files like a typical OpenSSL install prefix/lib prefix/include/openssl"
        echo "-i             ; build iOS"
        echo "-o             ; build OS-X"
        

        exit -1
        ;;
	p)  INSTALL_PREFIX="${OPTARG}"
		;;
	i)  BUILD_IOS=1
		;;
	o)  BUILD_OSX=1
		;;
	t)  OPENSSL_TAR_BALL_DIR="${OPTARG}"
		;;
	
    esac
done

shift $((OPTIND-1))

set -e

if [ ! -f "${OPENSSL_TAR_BALL_DIR}/openssl-${OPENSSL_VERSION}.tar.gz" ]
then
	echo "Could not find openssl-${OPENSSL_VERSION}.tar.gz in ${OPENSSL_TAR_BALL_DIR}"
	echo "Use the -t option to specify the directory where the tar ball can be found."
	echo "Use the -h option to show help."
	exit -1
fi

if [ $BUILD_IOS -eq 0 ] && [ $BUILD_OSX -eq 0 ]
then
	echo "Must specify at least one build type, iOS or OSX."
	echo "Use the -h option to show help."
	exit -1
fi

build()
{
   ARCH=$1
   SDK=$2
   TYPE=$3

   export BUILD_TOOLS="${DEVELOPER}"
   export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"

   mkdir -p "${OPENSSL_BUILD_TMP_DIR}/lib-${TYPE}"

   if [ -d "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}" ]
   then
      set +e
      make clean &> "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}.log"
      set -e
   else
	   tar xfz "${OPENSSL_TAR_BALL_DIR}/openssl-${OPENSSL_VERSION}.tar.gz"
   fi
   pushd .
   cd "openssl-${OPENSSL_VERSION}"

   #fix header for Swift

   sed -ie "s/BIGNUM \*I,/BIGNUM \*i,/g" crypto/rsa/rsa.h

   if [ "$TYPE" == "ios" ]; then
      # IOS
      if [ "$ARCH" == "x86_64" ]; then
         # Simulator
         export CROSS_TOP="${IPHONESIMULATOR_PLATFORM}/Developer"
         export CROSS_SDK="iPhoneSimulator${IOS_SDK_VERSION}.sdk"
         ./Configure darwin64-x86_64-cc --openssldir="${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}" &> "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}.log"
         sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -arch $ARCH -mios-simulator-version-min=${IOS_DEPLOYMENT_VERSION} !" "Makefile"
      elif [ "$ARCH" == "i386" ]; then
         # Simulator
         export CROSS_TOP="${IPHONESIMULATOR_PLATFORM}/Developer"
         export CROSS_SDK="iPhoneSimulator${IOS_SDK_VERSION}.sdk"
         ./Configure iphoneos-cross -no-asm --openssldir="${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}" &> "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}.log"
         sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -arch $ARCH -mios-simulator-version-min=${IOS_DEPLOYMENT_VERSION} !" "Makefile"
      else
         # iOS
         export CROSS_TOP="${IPHONEOS_PLATFORM}/Developer"
         export CROSS_SDK="iPhoneOS${IOS_SDK_VERSION}.sdk"
         ./Configure iphoneos-cross -no-asm --openssldir="${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}" &> "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}.log"
         perl -i -pe 's|static volatile sig_atomic_t intr_signal|static volatile int intr_signal|' crypto/ui/ui_openssl.c
         sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -arch $ARCH -miphoneos-version-min=${IOS_DEPLOYMENT_VERSION} !" "Makefile"
      fi
   else
      #OSX
      if [ "$ARCH" == "x86_64" ]; then
         ./Configure darwin64-x86_64-cc --openssldir="${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}" &> "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}.log"
         sed -ie "s!^CFLAG=!CFLAG=-isysroot ${SDK} -arch $ARCH -mmacosx-version-min=${OSX_DEPLOYMENT_VERSION} !" "Makefile"
      elif [ "$ARCH" == "i386" ]; then
         ./Configure darwin-i386-cc --openssldir="${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}" &> "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}.log"
         sed -ie "s!^CFLAG=!CFLAG=-isysroot ${SDK} -arch $ARCH -mmacosx-version-min=${OSX_DEPLOYMENT_VERSION} !" "Makefile"
      fi
   fi

   make build_libs build_apps openssl.pc libssl.pc libcrypto.pc &> "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}.log"
   make install_sw &> "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}.log"
   popd
   rm -rf "openssl-${OPENSSL_VERSION}"

   # Add arch to library
   if [ -f "${OPENSSL_BUILD_TMP_DIR}/lib-${TYPE}/libcrypto.a" ]; then
      xcrun lipo "${OPENSSL_BUILD_TMP_DIR}/lib-${TYPE}/libcrypto.a" "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}/lib/libcrypto.a" -create -output "${OPENSSL_BUILD_TMP_DIR}/lib-${TYPE}/libcrypto.a"
      xcrun lipo "${OPENSSL_BUILD_TMP_DIR}/lib-${TYPE}/libssl.a" "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}/lib/libssl.a" -create -output "${OPENSSL_BUILD_TMP_DIR}/lib-${TYPE}/libssl.a"
   else
      cp "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}/lib/libcrypto.a" "${OPENSSL_BUILD_TMP_DIR}/lib-${TYPE}/libcrypto.a"
      cp "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-${ARCH}/lib/libssl.a" "${OPENSSL_BUILD_TMP_DIR}/lib-${TYPE}/libssl.a"
   fi
}

# Clean up whatever was left from our previous build
rm -rf "${OPENSSL_BUILD_TMP_DIR}"

if [ "${INSTALL_PREFIX}" != "" ]
then
	mkdir -p ${INSTALL_PREFIX}/lib
	mkdir -p ${INSTALL_PREFIX}/include
fi

if [ $BUILD_IOS -eq 1 ]
then
	build "armv7" "${IPHONEOS_SDK}" "ios"
	build "armv7s" "${IPHONEOS_SDK}" "ios"
	build "arm64" "${IPHONEOS_SDK}" "ios"
	build "i386" "${IPHONESIMULATOR_SDK}" "ios"
	build "x86_64" "${IPHONESIMULATOR_SDK}" "ios"

	if [ "${INSTALL_PREFIX}" != "" ]
	then
		cp -rf "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-i386/include/openssl" "${INSTALL_PREFIX}/include/"
		cp -f "${OPENSSL_BUILD_TMP_DIR}/lib-ios/"*.a "${INSTALL_PREFIX}/lib/"
	else
		mkdir -p "${OPENSSL_BUILD_TMP_DIR}/include-ios"
		cp -r "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-i386/include/openssl" "${OPENSSL_BUILD_TMP_DIR}/include-ios/"
	fi
fi

if [ $BUILD_OSX -eq 1 ]
then
	build "i386" "${OSX_SDK}" "osx"
	build "x86_64" "${OSX_SDK}" "osx"

	if [ "${INSTALL_PREFIX}" != "" ]
	then
		cp -rf "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-i386/include/openssl" "${INSTALL_PREFIX}/include/"
		cp -f "${OPENSSL_BUILD_TMP_DIR}/lib-osx/"*.a "${INSTALL_PREFIX}/lib/"
	else
		mkdir -p "${OPENSSL_BUILD_TMP_DIR}/include-osx"
		cp -r "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-i386/include/openssl" "${OPENSSL_BUILD_TMP_DIR}/include-osx/"
	fi
fi

rm -rf "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-*"
rm -rf "${OPENSSL_BUILD_TMP_DIR}/openssl-${OPENSSL_VERSION}-*.log"

