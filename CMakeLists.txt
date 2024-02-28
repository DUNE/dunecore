# ======================================================================
#  larsoft main build file
#
#  cd .../path/to/build/directory
#  source .../path/to/larsoft/ups/setup_for_development <-d|-p>
#  cmake [-DCMAKE_INSTALL_PREFIX=/install/path]
#        -DCMAKE_BUILD_TYPE=$CETPKG_TYPE
#        $CETPKG_SOURCE
#  make
#  make test
#  make install
#  make package (builds distribution tarfile)
# ======================================================================
# LarSoft is an empty product
# It sets up all of the larsoft ups products (lardata, larsim, larreco, etc.)
# ======================================================================

cmake_minimum_required(VERSION 3.20 FATAL_ERROR) ### MIGRATE-CHANGED (migrate-3.22.02) - VERSION 3.19 -> 3.20
# cmake_policy(VERSION 3.19) ### MIGRATE-ACTION-COMPATIBILITY (migrate-3.22.02) - Uncomment to preserve compatibility with older CMake versions

# cetbuildtools contains our cmake modules
find_package(cetmodules REQUIRED) ### MIGRATE-CHANGED (migrate-3.22.02) - cetbuildtools -> cetmodules

#project(dunecore VERSION 09.48.00d00 LANGUAGES CXX)
project(dunecore LANGUAGES CXX)
set(${PROJECT_NAME}_CMAKE_PROJECT_VERSION_STRING 09.83.01d00)
set(${PROJECT_NAME}_FW_DIR "config_data")

## Make target names shorter (dunecore::X vs dunecore::dune_X).
# set(dunecore_NAMESPACE dune)

# Project variable defaults (_INIT) and overrides.
set(${PROJECT_NAME}_SCRIPTS_DIR_INIT scripts)

include(CetCMakeEnv)
cet_cmake_env()

# Find our own CMake modules, and tell everyone else where to find them.
cet_cmake_module_directories(Modules BINARY)

cet_set_compiler_flags(DIAGS CAUTIOUS
  WERROR
  NO_UNDEFINED
  EXTRA_FLAGS -pedantic -Wno-unused-local-typedefs
)
##add_definitions(-DGENIE_PRE_R3)

cet_report_compiler_flags() ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - add args: REPORT_THRESHOLD VERBOSE

# these are minimum required versions, not the actual product versions
find_package( Boost REQUIRED ) # Needs to be first to cover for a missing transitive ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(...) -> find_package(REQUIRED ...)
                  # dependency from artdaq_core.
find_package( Geant4 REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(...) -> find_package(REQUIRED ...)
find_package( ROOT REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(...) -> find_package(REQUIRED ...)

find_package( Eigen3 REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(eigen ...) -> find_package(eigen REQUIRED ...)
#include_directories( $ENV{EIGEN_INC} ) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - avoid directory-scope functions: use target_link_libraries() with target semantics or target_include_directories() whenever possible

find_package( art 3.09.00 REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(art v3_09_00 ...) -> find_package(art 3.09.00 REQUIRED ...)
find_package( art_root_io REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(art_root_io ...) -> find_package(art_root_io REQUIRED ...)
find_package( artdaq_core REQUIRED )#v01_03_6 ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(artdaq_core ...) -> find_package(artdaq_core REQUIRED ...)
find_package( TRACE REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(TRACE ...) -> find_package(TRACE REQUIRED ...)
find_package( canvas REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(canvas ...) -> find_package(canvas REQUIRED ...)
find_package( canvas_root_io REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(canvas_root_io ...) -> find_package(canvas_root_io REQUIRED ...)
find_package( cetlib_except REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(cetlib_except ...) -> find_package(cetlib_except REQUIRED ...)
find_package( cetlib REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(cetlib ...) -> find_package(cetlib REQUIRED ...)
find_package( CLHEP 2.1.3.0 REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(clhep v2_1_3_0 ...) -> find_package(clhep 2.1.3.0 REQUIRED ...)
find_package( dunepdlegacy REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(dunepdlegacy ...) -> find_package(dunepdlegacy REQUIRED ...)
find_package( fhiclcpp REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(fhiclcpp ...) -> find_package(fhiclcpp REQUIRED ...)
find_package( nufinder REQUIRED )
find_package( GENIE REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(genie ...) -> find_package(genie REQUIRED ...)
find_package( hep_concurrency REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(hep_concurrency ...) -> find_package(hep_concurrency REQUIRED ...)
find_package( ifdh_art REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(ifdh_art ...) -> find_package(ifdh_art REQUIRED ...)
find_package( ifdhc REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(ifdhc ...) -> find_package(ifdhc REQUIRED ...)
find_package( larana REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(larana ...) -> find_package(larana REQUIRED ...)
find_package( larcore REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(larcore ...) -> find_package(larcore REQUIRED ...)
find_package( larcorealg REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(larcorealg ...) -> find_package(larcorealg REQUIRED ...)
find_package( larcoreobj REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(larcoreobj ...) -> find_package(larcoreobj REQUIRED ...)
find_package( lardata REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(lardata ...) -> find_package(lardata REQUIRED ...)
find_package( lardataalg REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(lardataalg ...) -> find_package(lardataalg REQUIRED ...)
find_package( lardataobj REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(lardataobj ...) -> find_package(lardataobj REQUIRED ...)
find_package( larevt REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(larevt ...) -> find_package(larevt REQUIRED ...)
find_package( larpandora REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(larpandora ...) -> find_package(larpandora REQUIRED ...)
find_package( larreco REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(larreco ...) -> find_package(larreco REQUIRED ...)
find_package( larsim REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(larsim ...) -> find_package(larsim REQUIRED ...)
find_package( messagefacility 1.10.00 REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(messagefacility v1_10_00 ...) -> find_package(messagefacility 1.10.00 REQUIRED ...)
find_package( nuevdb REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(nuevdb ...) -> find_package(nuevdb REQUIRED ...)
find_package( nug4 REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(nug4 ...) -> find_package(nug4 REQUIRED ...)
find_package( nugen REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(nugen ...) -> find_package(nugen REQUIRED ...)
find_package( nurandom REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(nurandom ...) -> find_package(nurandom REQUIRED ...)
find_package( nusimdata REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(nusimdata ...) -> find_package(nusimdata REQUIRED ...)
find_package( nutools REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(nutools ...) -> find_package(nutools REQUIRED ...)
find_package( dunedaqdataformats REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(dunedaqdataformats ...) -> find_package(dunedaqdataformats REQUIRED ...)
find_package( dunedetdataformats REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(dunedetdataformats ...) -> find_package(dunedetdataformats REQUIRED ...)
find_package( PostgreSQL 9.1.5 REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(postgresql v9_1_5 ...) -> find_package(postgresql 9.1.5 REQUIRED ...)
find_package(FFTW3 REQUIRED EXPORT)
find_package(  SQLite3 REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(sqlite ...) -> find_package(SQLite3 REQUIRED ...)
find_package( nlohmann_json REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(nlohmann_json ...) -> find_package(nlohmann_json REQUIRED ...)
find_package( HDF5 REQUIRED)
# Define an export set for tool support to enable simpler per-tool build
# call.
cet_register_export_set(SET_NAME PluginTypes NAMESPACE art_plugin_types)

# macros for dictionary and simple_plugin
include(ArtDictionary)
include(ArtMake)
include(BuildPlugins)

# ADD SOURCE CODE SUBDIRECTORIES HERE
add_subdirectory(dunecore)
## release database
# add_subdirectory(releaseDB)
# subdirectory for test code
# add_subdirectory(test)
# CMake Modules
add_subdirectory(Modules)
# ups - table and config files

# packaging utility
cet_cmake_config() ### MIGRATE-ADDED (migrate-3.22.02) - required cmd
