# art_extensions/test/AXService/CMakeLists.txt

include(CetTest)

cet_enable_asserts()

cet_test(test_make_tool SOURCES test_make_tool.cxx
  LIBRARIES
    dune_ArtSupport_Tool_TestTool_tool
    art::Utilities canvas
    fhiclcpp
    cetlib::cetlib cetlib_except
    
)

cet_test(test_ArtServiceHelper SOURCES test_ArtServiceHelper.cxx
  LIBRARIES
    dune_ArtSupport
    art_root_io_TFileService_service
    art::Framework_Services_Optional_RandomNumberGenerator_service
    ROOT_BASIC_LIB_LIST
)

cet_test(test_DuneToolManager SOURCES test_DuneToolManager.cxx
  LIBRARIES
    dune_ArtSupport
    dune_ArtSupport_Tool_TestTool_tool
)

install_source()
