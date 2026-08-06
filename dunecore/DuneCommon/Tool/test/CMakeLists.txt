# dunetpc/dune/DuneCommon/Tool/test/CMakeLists.txt

# David Adams
# August 2017

# Build test for each tool.

include(CetTest)

cet_transitive_paths(FHICL_DIR BINARY IN_TREE)
cet_test_env_prepend(FHICL_FILE_PATH "." ${PROJECT_BINARY_DIR}/fcl ${TRANSITIVE_PATHS_WITH_FHICL_DIR} ${PROJECT_BINARY_DIR}/../dunesim/fcl ${PROJECT_BINARY_DIR}/../duneopdet/fcl ${PROJECT_BINARY_DIR}/../duneprototypes/fcl ${PROJECT_BINARY_DIR}/../dunedataprep/fcl ${PROJECT_BINARY_DIR}/../dunecalib/fcl)
cet_transitive_paths(LIBRARY_DIR BINARY IN_TREE)
cet_test_env_prepend(CET_PLUGIN_PATH ${TRANSITIVE_PATHS_WITH_LIBRARY_DIR})
cet_transitive_paths(GDML_DIR BINARY IN_TREE)
cet_test_env_prepend(FW_SEARCH_PATH ${TRANSITIVE_PATHS_WITH_GDML_DIR} ${PROJECT_BINARY_DIR}/gdml)

cet_test(test_FclRunDataTool SOURCE test_FclRunDataTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_FclIndexRangeTool SOURCE test_FclIndexRangeTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_FclIndexVectorMapTool SOURCE test_FclIndexVectorMapTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_FixedTimeOffsetTool SOURCE test_FixedTimeOffsetTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_TimingRawDecoderOffsetTool SOURCE test_TimingRawDecoderOffsetTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_SimpleHistogramManager SOURCE test_SimpleHistogramManager.cxx
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

cet_test(test_FclFloatArray SOURCE test_FclFloatArray.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)
cet_test(test_FclFileFloatArray SOURCE test_FclFileFloatArray.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_ChannelStatusServiceTool SOURCE test_ChannelStatusServiceTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_ChannelStatusConfigTool SOURCE test_ChannelStatusConfigTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_BlockIndexMapTool SOURCE test_BlockIndexMapTool.cxx
  LIBRARIES
    dunecore_ArtSupport
    art::Utilities
    canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib
    cetlib_except::cetlib_except
    Boost::filesystem
)

cet_test(test_TextIndexMapTool SOURCE test_TextIndexMapTool.cxx
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

cet_test(test_DuneRunToolRedirector SOURCE test_DuneRunToolRedirector.cxx
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

