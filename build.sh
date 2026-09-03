#!/bin/bash


SELF_FILE="$(realpath "$0")"
SELF_DIR="$(dirname "$SELF_FILE")"

BUILD_FOLDER_PATH="$SELF_DIR/msquic/build"
BUILD_ARTIFACT_FILENAME='libmsquic.so'

BUILD_ARTIFACT_DIR="$BUILD_FOLDER_PATH/bin/Release"
BUILD_ARTIFACT_FILEPATH="$BUILD_ARTIFACT_DIR/$BUILD_ARTIFACT_FILENAME"
BUILD_ARTIFACT_DESTINATION="$SELF_DIR/runtimes/linux-x64/native"



export LD_RUN_PATH='$ORIGIN:$ORIGIN/runtimes/linux-x64/native'
export CFLAGS="$CFLAGS $RPATH_FLAG"
export CXXFLAGS="$CXXFLAGS $RPATH_FLAG"



git submodule update --init

if [[ -d "$BUILD_FOLDER_PATH" ]]; then
	rm -rf "$BUILD_FOLDER_PATH"
fi

mkdir "$BUILD_FOLDER_PATH"
cd "$BUILD_FOLDER_PATH" || exit

cmake -G 'Unix Makefiles' ..
cmake --build .


readelf -d "$BUILD_ARTIFACT_FILEPATH"


cp "$BUILD_ARTIFACT_DIR/"*.so* "$BUILD_ARTIFACT_DESTINATION"


cd "$SELF_DIR" || exit

dotnet build -c Release
