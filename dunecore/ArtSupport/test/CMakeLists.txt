# art_extensions/test/AXService/CMakeLists.txt

include(CetTest)

cet_enable_asserts()

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
