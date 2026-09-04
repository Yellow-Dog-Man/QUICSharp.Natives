#!/bin/bash


# Quick way to get the script path as well as the directory it's being run from.
SELF_FILE="$(realpath "$0")"
SELF_DIR="$(dirname "$SELF_FILE")"

BUILD_FOLDER_PATH="$SELF_DIR/msquic/build"
BUILD_ARTIFACT_FILENAME='libmsquic.so'

BUILD_ARTIFACT_DIR="$BUILD_FOLDER_PATH/bin/Release"
BUILD_ARTIFACT_FILEPATH="$BUILD_ARTIFACT_DIR/$BUILD_ARTIFACT_FILENAME"

PACKAGE_RUNTIMES_FOLDER="$SELF_DIR/runtimes"
LINUX_X64_ARTIFACT_DESTINATION="$PACKAGE_RUNTIMES_FOLDER/linux-x64/native"


# Apparently the internet can't tell me how to bundle shared libs with a GCC build.
LIBNUMA_SOURCE_FILEPATH="/usr/lib/libnuma.so.1"


# The RUNPATH is embedded into the build file
export LD_RUN_PATH='$ORIGIN:$ORIGIN/runtimes/linux-x64/native'
export CFLAGS="$CFLAGS $RPATH_FLAG"
export CXXFLAGS="$CXXFLAGS $RPATH_FLAG"


# Make sure git submodules are updated.
git submodule update --init --recursive --depth 1

# Remove the build folder if it exists already.
if [[ -d "$BUILD_FOLDER_PATH" ]]; then
	rm -rf "$BUILD_FOLDER_PATH"
fi

# Create the native runtimes folder hierarchy for the nuget package.
if [[ ! -d "$LINUX_X64_ARTIFACT_DESTINATION" ]]; then
    mkdir -p "$LINUX_X64_ARTIFACT_DESTINATION"
fi


# Path to the msquic version json.
VERSION_FILEPATH="$SELF_DIR/msquic/version.json"

# Read the json file into a variable.
VERSION_DATA="$(cat "$VERSION_FILEPATH")"

# Print the version data into grep with a regex to parse the version numbers.
VERSION_NUMBERS="$(printf '%b' "$VERSION_DATA" | grep -Po '("[[:alnum:]]+":[[:space:]]*\K)[[:digit:]]+')"

# Grep prints matches on their own lines, so use bash parameter expansion to
# replace the newlines with periods (.) to yield a version number like '1.2.3'.
PACKAGE_VERSION="$(printf '%b' "${VERSION_NUMBERS//$'\n'/\.}")"



mkdir "$BUILD_FOLDER_PATH"
cd "$BUILD_FOLDER_PATH" || exit

cmake -G 'Unix Makefiles' ..
cmake --build .


readelf -d "$BUILD_ARTIFACT_FILEPATH" # Print the ELF info for debugging.

# Copy the build artifacts to the runtimes folder for the nuget package.
cp "$BUILD_ARTIFACT_DIR/"*.so* "$LINUX_X64_ARTIFACT_DESTINATION"

# Copy libnuma.so.1 from the host system. :(
cp "$LIBNUMA_SOURCE_FILEPATH" "$LINUX_X64_ARTIFACT_DESTINATION"

# Go back into the package directory and build the nuget package with the msquic version number.
cd "$SELF_DIR" || exit
dotnet build -c Release /p:Version="$PACKAGE_VERSION"
