# ======================================================================
#  dunecore main build file
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

cmake_minimum_required(VERSION 3.20 FATAL_ERROR) ### MIGRATE-CHANGED (migrate-3.22.02) - VERSION 3.19 -> 3.20

find_package(cetmodules REQUIRED)
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

find_package( Boost COMPONENTS system REQUIRED EXPORT ) # Needs to be first to cover for a missing transitive dependency from artdaq_core.
find_package( Geant4 REQUIRED EXPORT ) 
find_package( ROOT REQUIRED EXPORT ) 
find_package( Eigen3 REQUIRED EXPORT ) 
#include_directories( $ENV{EIGEN_INC} ) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - avoid directory-scope functions: use target_link_libraries() with target semantics or target_include_directories() whenever possible

find_package( art REQUIRED EXPORT )
find_package( art_root_io REQUIRED EXPORT ) 
find_package( artdaq_core REQUIRED EXPORT )
find_package( TRACE REQUIRED EXPORT ) 
find_package( canvas REQUIRED EXPORT ) 
find_package( canvas_root_io REQUIRED EXPORT ) 
find_package( cetlib_except REQUIRED EXPORT ) 
find_package( cetlib REQUIRED EXPORT ) 
find_package( CLHEP REQUIRED EXPORT ) 
find_package( fhiclcpp REQUIRED EXPORT )

find_package(nurandom REQUIRED EXPORT)
find_package(nusimdata REQUIRED EXPORT)
find_package(nutools REQUIRED EXPORT)
find_package(nugen REQUIRED EXPORT)
find_package(nug4 REQUIRED EXPORT)

find_package( GENIE REQUIRED EXPORT )
find_package( CRY REQUIRED EXPORT )
find_package( hep_concurrency REQUIRED EXPORT ) 
find_package( ifdh_art REQUIRED EXPORT ) 
find_package( ifdhc REQUIRED EXPORT ) 
find_package( larana REQUIRED EXPORT ) 
find_package( larcore REQUIRED EXPORT ) 
find_package( larcorealg REQUIRED EXPORT ) 
find_package( larcoreobj REQUIRED EXPORT ) 
find_package( lardata REQUIRED EXPORT ) 
find_package( lardataalg REQUIRED EXPORT ) 
find_package( lardataobj REQUIRED EXPORT ) 
find_package( larevt REQUIRED EXPORT ) 
find_package( larpandora REQUIRED EXPORT ) 
find_package( larreco REQUIRED EXPORT ) 
find_package( larsim REQUIRED EXPORT ) 

find_package( messagefacility REQUIRED EXPORT ) 
find_package( dunedaqdataformats REQUIRED EXPORT ) 
find_package( dunedetdataformats REQUIRED EXPORT ) 
find_package( dunepdlegacy REQUIRED EXPORT ) 
find_package( PostgreSQL 9.1.5 REQUIRED EXPORT ) 
find_package( FFTW3 REQUIRED EXPORT )
find_package( SQLite3 REQUIRED EXPORT ) 
find_package( nlohmann_json REQUIRED EXPORT ) 
find_package( HDF5 REQUIRED EXPORT )
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
cet_cmake_config()
