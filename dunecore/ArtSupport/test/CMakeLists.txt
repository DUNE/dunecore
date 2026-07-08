# art_extensions/test/AXService/CMakeLists.txt

include(CetTest)

cet_enable_asserts()

cet_transitive_paths(FHICL_DIR BINARY IN_TREE)
cet_test_env_prepend(FHICL_FILE_PATH "." ${TRANSITIVE_PATHS_WITH_FHICL_DIR})
cet_transitive_paths(LIBRARY_DIR BINARY IN_TREE)
cet_test_env_prepend(CET_PLUGIN_PATH ${TRANSITIVE_PATHS_WITH_LIBRARY_DIR})

cet_test(test_make_tool
  SOURCES
    test_make_tool.cxx
  LIBRARIES
    dunecore::ArtSupport_Tool_TestTool_tool
    art::Utilities canvas::canvas
    fhiclcpp::fhiclcpp
    cetlib::cetlib 
    cetlib_except::cetlib_except
    
)

cet_test(test_ArtServiceHelper
  SOURCES
    test_ArtServiceHelper.cxx
  LIBRARIES
    dunecore_ArtSupport
    art_root_io::TFileService_service
    art::Framework_Services_Optional_RandomNumberGenerator_service
)

cet_test(test_DuneToolManager
  SOURCES
    test_DuneToolManager.cxx
  LIBRARIES
    dunecore::ArtSupport
    dunecore::ArtSupport_Tool_TestTool_tool
)

install_source()
