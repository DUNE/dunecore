# dune/DuneServiceAccess/CMakeLists.txt
#
# David Adams
# January 2017
#
# CMake instructions for the dune_DuneServices library which holds
# helper classes for dealing with art services.

FILE( GLOB src_files *.cxx )

art_make_library(
  LIBRARY_NAME dunecore_DuneServiceAccess
  SOURCE ${src_files}
  LIBRARIES
    dunecore::SignalShapingServiceDUNE_service
    art::Framework_Services_Registry
    art::Framework_Core
    art::Framework_Principal
    art::Utilities
    canvas::canvas
    cetlib::cetlib
    cetlib_except::cetlib_except
    larevt::CalibrationDBI_Providers
    larcoreobj::headers
)

install_headers()
