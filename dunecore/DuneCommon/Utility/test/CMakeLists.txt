# dunetpc/dune/DuneCommon/Utility/test/Utility/CMakeLists.txt

include(CetTest)

cet_enable_asserts()

cet_transitive_paths(FHICL_DIR BINARY IN_TREE)
cet_test_env_prepend(FHICL_FILE_PATH "." ${TRANSITIVE_PATHS_WITH_FHICL_DIR})
cet_transitive_paths(LIBRARY_DIR BINARY IN_TREE)
cet_test_env_prepend(CET_PLUGIN_PATH ${TRANSITIVE_PATHS_WITH_LIBRARY_DIR})
cet_test_env_prepend(FW_SEARCH_PATH ".")
cet_test_env_prepend(ROOT_INCLUDE_PATH ".")
cet_test_env_prepend(ROOT_LIBRARY_PATH "." ${PROJECT_BINARY_DIR}/lib)

cet_test(test_LineColors SOURCE test_LineColors.cxx
  LIBRARIES
  ROOT::Gpad
)


#cet_test(test_DuneTimeConverter SOURCE test_DuneTimeConverter.cxx
#  LIBRARIES
#    art::Persistency_Provenance canvas
#)

cet_test(test_StringManipulator SOURCE test_StringManipulator.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
  )

cet_test(test_TPadManipulator SOURCE test_TPadManipulator.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_RootPalette SOURCE test_RootPalette.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_CompactRealDftData SOURCE test_CompactRealDftData.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_DuneFFT SOURCE test_DuneFFT.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_FwFFT SOURCE test_FwFFT.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_Fw2dFFT SOURCE test_Fw2dFFT.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_coldelecResponse SOURCE test_coldelecResponse.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_gausTF1 SOURCE test_gausTF1.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_offsetLine SOURCE test_offsetLine.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_GausStepFitter SOURCE test_GausStepFitter.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_GausRmsFitter SOURCE test_GausRmsFitter.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_SampleTailer SOURCE test_SampleTailer.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_shiftHistFit SOURCE test_shiftHistFit.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_RootParFormula SOURCE test_RootParFormula.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_DuneContextToolRedirector SOURCE test_DuneContextToolRedirector.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_DuneContextManager
  SOURCE
      test_DuneContextManager.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

