# dunecore/dunecore/DuneInterface/Data/test/CMakeLists.txt

# David Adams
# May 2018

# Build test for each component.
add_compile_options("-Wno-error=parentheses" )
include(CetTest)

cet_transitive_paths(FHICL_DIR BINARY IN_TREE)
cet_test_env_prepend(FHICL_FILE_PATH "." ${TRANSITIVE_PATHS_WITH_FHICL_DIR})
cet_transitive_paths(LIBRARY_DIR BINARY IN_TREE)
cet_test_env_prepend(CET_PLUGIN_PATH ${TRANSITIVE_PATHS_WITH_LIBRARY_DIR})

cet_test(test_DataMap SOURCES test_DataMap.cxx
  LIBRARIES
  ROOT::Core
  ROOT::Hist
)

cet_test(test_DuneEventInfo SOURCES test_DuneEventInfo.cxx
  LIBRARIES
  ROOT::Core
)

cet_test(test_RunData SOURCES test_RunData.cxx
  LIBRARIES
  ROOT::Core
)

cet_test(test_AdcChannelData SOURCES test_AdcChannelData.cxx
  LIBRARIES
  ROOT::Core
)

cet_test(test_FftwReal2dDftData SOURCES test_FftwReal2dDftData.cxx
  LIBRARIES
  ROOT::Core
  FFTW3::FFTW3
)

cet_test(test_Tpc2dRoi SOURCES test_Tpc2dRoi.cxx
  LIBRARIES
  ROOT::Core
  FFTW3::FFTW3
)

cet_test(test_TpcData SOURCES test_TpcData.cxx
  LIBRARIES
  ROOT::Core
    dunecore::DuneInterface_Data
)

cet_enable_asserts()
