# dunetpc/dune/DuneCommon/Service/test/CMakeLists.txt

# David Adams
# October 2016

# Build test for each service.

include(CetTest)

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
