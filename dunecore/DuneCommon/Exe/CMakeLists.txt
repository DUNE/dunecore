# dunetpc/dune/DuneCommon/Exe
#
# David Adams
# May 2018
#
# Instructions to build and install duneRunData

cet_make_exec(duneRunData
  SOURCE duneRunData.cxx
  LIBRARIES
    dunecore::ArtSupport
    fhiclcpp::fhiclcpp
    cetlib::cetlib 
    cetlib_except::cetlib_except
)

install_scripts(
  LIST duneHelp duneTestFcl
)
