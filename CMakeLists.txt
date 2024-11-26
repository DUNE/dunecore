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

cmake_minimum_required(VERSION 3.20 FATAL_ERROR)
# cmake_policy(VERSION 3.19)

# cetbuildtools contains our cmake modules
find_package(cetmodules REQUIRED)

#project(dunecore VERSION 09.48.00d00 LANGUAGES CXX)
project(dunecore LANGUAGES CXX)
set(${PROJECT_NAME}_CMAKE_PROJECT_VERSION_STRING 10.01.03d00)
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

cet_report_compiler_flags()

# these are minimum required versions, not the actual product versions
find_package( Boost REQUIRED COMPONENTS system) # Needs to be first to cover for a missing transitive
                  # dependency from artdaq_core.
find_package( Geant4 REQUIRED )
find_package( ROOT REQUIRED )

find_package( Eigen3 REQUIRED )
#include_directories( $ENV{EIGEN_INC} )

find_package( art 3.09.00 REQUIRED )
find_package( art_root_io REQUIRED )
find_package( artdaq_core REQUIRED )#v01_03_6 )
find_package( TRACE REQUIRED )
find_package( canvas REQUIRED )
find_package( canvas_root_io REQUIRED )
find_package( cetlib_except REQUIRED )
find_package( cetlib REQUIRED )
find_package( CLHEP 2.1.3.0 REQUIRED )
find_package( dunepdlegacy REQUIRED )
find_package( fhiclcpp REQUIRED )
find_package( nufinder REQUIRED )
find_package( GENIE REQUIRED )
find_package( hep_concurrency REQUIRED )
find_package( ifdh_art REQUIRED )
find_package( ifdhc REQUIRED )
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
find_package( messagefacility 1.10.00 REQUIRED EXPORT )
find_package( nuevdb REQUIRED EXPORT )
find_package( nug4 REQUIRED EXPORT )
find_package( nugen REQUIRED EXPORT )
find_package( nurandom REQUIRED EXPORT )
find_package( nusimdata REQUIRED EXPORT )
find_package( nutools REQUIRED EXPORT )
find_package( dunedaqdataformats REQUIRED EXPORT )
find_package( dunedetdataformats REQUIRED EXPORT )
find_package( PostgreSQL 9.1.5 REQUIRED )
find_package( FFTW3 REQUIRED EXPORT )
find_package(  SQLite3 REQUIRED )
find_package( nlohmann_json REQUIRED )
find_package( HDF5 REQUIRED)
find_package( HighFive REQUIRED )
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
