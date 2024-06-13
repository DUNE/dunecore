# dunecore/dunecore/DuneInterface/Tool/test/CMakeLists.txt

# David Adams
# April 2018

# Build test for each tool interface.

include(CetTest)

cet_test(test_AdcChannelTool SOURCES test_AdcChannelTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_TpcDataTool SOURCES test_TpcDataTool.cxx
  LIBRARIES
    dunecore_DuneInterface_Data
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)
