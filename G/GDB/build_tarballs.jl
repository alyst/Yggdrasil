# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GDB"
version = v"12.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/gdb/gdb-$(version.major).$(version.minor).tar.xz",
                  "0e1793bf8f2b54d53f46dea84ccfd446f48f81b297b28c4f7fc017b818d69fed"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
apk add texinfo
cd $WORKSPACE/srcdir/gdb-*/
CONFIGURE_FLAGS=(--prefix=${prefix} --build=${MACHTYPE} --host=${target})
CONFIGURE_FLAGS+=(--with-expat)
if [[ ${target} != *mingw* ]]; then
    # Python_jll is not yet available for Windows
    CONFIGURE_FLAGS+=(--with-python=${WORKSPACE}/srcdir/python-cross-configure.sh)
fi
./configure ${CONFIGURE_FLAGS[@]}
make -j${nproc} all
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("gdbserver", :gdbserver),
    ExecutableProduct("gdb", :gdb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d")),
    Dependency("Expat_jll"),
    Dependency("Python_jll"; compat="~3.8.8"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"8.1.0")
