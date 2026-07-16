# dunetpc/dune/Geometry/test/CMakeLists.txt

# David Adams
# November 2016

# Build tests for channel maps.
install_fhicl()
include(CetTest)
add_subdirectory(testIssue19191)

cet_transitive_paths(FHICL_DIR BINARY IN_TREE)
cet_test_env_prepend(FHICL_FILE_PATH "." ${TRANSITIVE_PATHS_WITH_FHICL_DIR})
cet_transitive_paths(LIBRARY_DIR BINARY IN_TREE)
cet_test_env_prepend(CET_PLUGIN_PATH ${TRANSITIVE_PATHS_WITH_LIBRARY_DIR})
cet_transitive_paths(GDML_DIR BINARY IN_TREE)
cet_test_env_prepend(FW_SEARCH_PATH ${TRANSITIVE_PATHS_WITH_GDML_DIR})

cet_enable_asserts()

cet_test(test_GeometryDune35t SOURCES test_GeometryDune35t.cxx
  LIBRARIES
    dunecore::ArtSupport
    larcorealg::Geometry
    larcore::headers
    ROOT::Geom
)

cet_test(test_GeometryDune10kt SOURCES test_GeometryDune10kt.cxx
  LIBRARIES
    dunecore::ArtSupport
    larcorealg::Geometry
    larcore::headers
    ROOT::Geom
)

cet_test(test_GeometryProtoDune SOURCES test_GeometryProtoDune.cxx
  LIBRARIES
    dunecore::ArtSupport
    larcorealg::Geometry
    larcore::headers
    ROOT::Geom
)

cet_test(test_WireSelector SOURCES test_WireSelector.cxx
  LIBRARIES
    dunecore::ArtSupport
    dunecore::Geometry
    dunecore::DuneCommon_Utility
    larcorealg::Geometry
    larcore::headers
    ROOT::Geom
)
