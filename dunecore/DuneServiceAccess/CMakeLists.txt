# dune/DuneServiceAccess/CMakeLists.txt
#
# David Adams
# January 2017
#
# CMake instructions for the dune_DuneServices library which holds
# helper classes for dealing with art services.

FILE( GLOB src_files *.cxx )

art_make_library(
  LIBRARY_NAME dune_DuneServiceAccess
  SOURCE ${src_files}
  LIBRARIES
    SignalShapingServiceDUNE_service
    art::Framework_Services_Registry
    art_Framework_Core
    art::Framework_Principal
    art::Utilities
    canvas::canvas
    cetlib::cetlib cetlib_except
)

install_headers()
