# dunetpc/dune/DuneCommon/Service/ToolBasedChannelStatus/test/CMakeLists.txt

# David Adams
# Januarey 2023

# Build test for each service.

include(CetTest)

cet_transitive_paths(FHICL_DIR BINARY IN_TREE)
cet_test_env_prepend(FHICL_FILE_PATH "." ${TRANSITIVE_PATHS_WITH_FHICL_DIR})
cet_transitive_paths(LIBRARY_DIR BINARY IN_TREE)
cet_test_env_prepend(CET_PLUGIN_PATH ${TRANSITIVE_PATHS_WITH_LIBRARY_DIR})

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

