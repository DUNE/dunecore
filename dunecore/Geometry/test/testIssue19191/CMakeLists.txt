cet_build_plugin(issue19191           art::module  NO_INSTALL cetlib_except::cetlib_except larcorealg::Geometry larcore::Geometry_Geometry_service dunecore::ArtSupport)

cet_transitive_paths(FHICL_DIR BINARY IN_TREE)
cet_test_env_prepend(FHICL_FILE_PATH "." ${TRANSITIVE_PATHS_WITH_FHICL_DIR} ${dunesim_BINARY_DIR}/fcl ${duneopdet_BINARY_DIR}/fcl ${duneprototypes_BINARY_DIR}/fcl ${dunedataprep_BINARY_DIR}/fcl ${dunecalib_BINARY_DIR}/fcl)
cet_transitive_paths(LIBRARY_DIR BINARY IN_TREE)
cet_test_env_prepend(CET_PLUGIN_PATH ${TRANSITIVE_PATHS_WITH_LIBRARY_DIR})
cet_transitive_paths(GDML_DIR BINARY IN_TREE)
cet_test_env_prepend(FW_SEARCH_PATH ${TRANSITIVE_PATHS_WITH_GDML_DIR} ${PROJECT_BINARY_DIR}/gdml)

cet_test(test_issue19191 HANDBUILT
  TEST_EXEC art 
  TEST_ARGS --rethrow-all --config test_issue19191.fcl
  DATAFILES test_issue19191.fcl
)
