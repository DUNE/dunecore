# dunetpc/dune/DuneCommon/Service/EventContext/test/CMakeLists.txt

# David Adams
# January 2023

# Build test for each service.

include(CetTest)

cet_enable_asserts()

cet_test(test_EventContextService 
  SOURCES
    test_EventContextService.cxx
  LIBRARIES
    dunecore_DuneCommon_Utility
    dunecore::ArtSupport
    larcoreobj::headers
    lardataobj::RawData
)

