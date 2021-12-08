# dunetpc/dune/DuneInterface/Tool/test/CMakeLists.txt

# David Adams
# April 2018

# Build test for each tool interface.

include(CetTest)

cet_test(test_AdcChannelTool SOURCES test_AdcChannelTool.cxx
  LIBRARIES
    dune_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp
    cetlib::cetlib cetlib_except
    cetlib_except::cetlib_except
    SQLITE3
    Boost::filesystem
)

cet_test(test_TpcDataTool SOURCES test_TpcDataTool.cxx
  LIBRARIES
    dune_DuneInterface_Data
    dune_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp
    cetlib::cetlib cetlib_except
    cetlib_except::cetlib_except
    SQLITE3
    Boost::filesystem
)
