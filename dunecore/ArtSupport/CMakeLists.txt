# dune/ArtSupport/CMakeLists.txt
#
# David Adams
# September 2015
#
# CMake instructions for the AXServices library which holds
# helper classes for dealing with art services.

art_make(
  LIB_LIBRARIES
    art_Framework_EventProcessor
    art::Framework_Services_Registry
    art::Utilities
    canvas::canvas
    fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    
    ROOT::Core
)

add_subdirectory(Tool)
add_subdirectory(test)
add_subdirectory(exe)

install_headers()
install_fhicl()
install_source()
