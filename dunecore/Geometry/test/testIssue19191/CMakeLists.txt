cet_build_plugin(issue19191           art::module  NO_INSTALL cetlib_except::cetlib_except larcorealg::Geometry larcore::Geometry_Geometry_service dunecore::ArtSupport)

cet_test(test_issue19191 HANDBUILT
  TEST_EXEC art 
  TEST_ARGS --rethrow-all --config test_issue19191.fcl
  DATAFILES test_issue19191.fcl
)
