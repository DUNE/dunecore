# dunetpc/dune/Geometry/test/CMakeLists.txt

# David Adams
# November 2016

# Build tests for channel maps.
install_fhicl()
include(CetTest)
add_subdirectory(testIssue19191)

cet_enable_asserts()

cet_test(test_GeometryDune35t SOURCES test_GeometryDune35t.cxx
  LIBRARIES
    dunecore::ArtSupport
    larcorealg::Geometry
    ROOT::Geom
    ROOT_BASIC_LIB_LIST
)

cet_test(test_GeometryDune10kt SOURCES test_GeometryDune10kt.cxx
  LIBRARIES
    dunecore::ArtSupport
    larcorealg::Geometry
    ROOT::Geom
    ROOT_BASIC_LIB_LIST
)

cet_test(test_GeometryProtoDune SOURCES test_GeometryProtoDune.cxx
  LIBRARIES
    dunecore::ArtSupport
    larcorealg::Geometry
    ROOT::Geom
    ROOT_BASIC_LIB_LIST
)

cet_test(test_WireSelector SOURCES test_WireSelector.cxx
  LIBRARIES
    dunecore::ArtSupport
    dunecore::Geometry
    dunecore::DuneCommon_Utility
    larcorealg::Geometry
    ROOT::Geom
    ROOT_BASIC_LIB_LIST
)
