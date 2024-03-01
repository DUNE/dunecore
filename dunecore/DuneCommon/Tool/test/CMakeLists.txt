# dunetpc/dune/DuneCommon/Tool/test/CMakeLists.txt

# David Adams
# August 2017

# Build test for each tool.

include(CetTest)

cet_test(test_FclRunDataTool SOURCES test_FclRunDataTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_FclIndexRangeTool SOURCES test_FclIndexRangeTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_FclIndexVectorMapTool SOURCES test_FclIndexVectorMapTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_FixedTimeOffsetTool SOURCES test_FixedTimeOffsetTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_TimingRawDecoderOffsetTool SOURCES test_TimingRawDecoderOffsetTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_SimpleHistogramManager SOURCES test_SimpleHistogramManager.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
    ROOT::Hist
)

cet_test(test_FclFloatArray SOURCES test_FclFloatArray.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)
cet_test(test_FclFileFloatArray SOURCES test_FclFileFloatArray.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_ChannelStatusServiceTool SOURCES test_ChannelStatusServiceTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_ChannelStatusConfigTool SOURCES test_ChannelStatusConfigTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_BlockIndexMapTool SOURCES test_BlockIndexMapTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_TextIndexMapTool SOURCES test_TextIndexMapTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    dunecore_DuneCommon_Utility
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_DuneRunToolRedirector SOURCES test_DuneRunToolRedirector.cxx
  LIBRARIES
    dunecore_DuneCommon_Utility
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

