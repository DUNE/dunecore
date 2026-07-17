# dunetpc/dune/DuneCommon/Service/test/CMakeLists.txt

# David Adams
# October 2016

# Build test for each service.

include(CetTest)

cet_transitive_paths(FHICL_DIR BINARY IN_TREE)
cet_test_env_prepend(FHICL_FILE_PATH "." ${PROJECT_BINARY_DIR}/fcl ${TRANSITIVE_PATHS_WITH_FHICL_DIR})
cet_transitive_paths(LIBRARY_DIR BINARY IN_TREE)
cet_test_env_prepend(CET_PLUGIN_PATH ${TRANSITIVE_PATHS_WITH_LIBRARY_DIR})

cet_enable_asserts()

cet_test(test_GeoRopChannelGroupService
  SOURCES
    test_GeoRopChannelGroupService.cxx
  LIBRARIES
    larcore::headers
    larcorealg::Geometry
    lardataalg::DetectorInfo
    dunecore::ArtSupport
)

cet_test(test_GeoApaChannelGroupService
  SOURCES
    test_GeoApaChannelGroupService.cxx
  LIBRARIES
    larcore::headers
    larcorealg::Geometry
    dunecore::ArtSupport
)

cet_test(test_FixedChannelGroupService
  SOURCES
    test_FixedChannelGroupService.cxx
  LIBRARIES
    dunecore::ArtSupport
    dunecore::DuneServiceAccess
)
