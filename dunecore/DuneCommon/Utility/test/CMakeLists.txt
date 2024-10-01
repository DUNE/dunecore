# dunetpc/dune/DuneCommon/Utility/test/Utility/CMakeLists.txt

include(CetTest)

cet_enable_asserts()

cet_test(test_LineColors SOURCES test_LineColors.cxx
  LIBRARIES
  ROOT::Gpad
)


#cet_test(test_DuneTimeConverter SOURCES test_DuneTimeConverter.cxx
#  LIBRARIES
#    art::Persistency_Provenance canvas
#)

cet_test(test_StringManipulator SOURCES test_StringManipulator.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
  )

cet_test(test_TPadManipulator SOURCES test_TPadManipulator.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_RootPalette SOURCES test_RootPalette.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_CompactRealDftData SOURCES test_CompactRealDftData.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_DuneFFT SOURCES test_DuneFFT.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_FwFFT SOURCES test_FwFFT.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_Fw2dFFT SOURCES test_Fw2dFFT.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_coldelecResponse SOURCES test_coldelecResponse.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_gausTF1 SOURCES test_gausTF1.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_offsetLine SOURCES test_offsetLine.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_GausStepFitter SOURCES test_GausStepFitter.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_GausRmsFitter SOURCES test_GausRmsFitter.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_SampleTailer SOURCES test_SampleTailer.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_shiftHistFit SOURCES test_shiftHistFit.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_RootParFormula SOURCES test_RootParFormula.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_DuneContextToolRedirector SOURCES test_DuneContextToolRedirector.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

cet_test(test_DuneContextManager
  SOURCES
    test_DuneContextManager.cxx
  LIBRARIES
    dunecore::DuneCommon_Utility
    ROOT::Core
)

