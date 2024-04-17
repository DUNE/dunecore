# dunetpc/dune/DuneCommon/Service/ToolBasedChannelStatus/test/CMakeLists.txt

# David Adams
# Januarey 2023

# Build test for each service.

include(CetTest)

cet_enable_asserts()

cet_test(test_ToolBasedChannelStatusService 
  SOURCES
    test_ToolBasedChannelStatusService.cxx
  LIBRARIES
    larcore::headers
    larcorealg::Geometry
    lardataalg::DetectorInfo
    dunecore::ArtSupport
    larevt::CalibrationDBI_Providers 
)

