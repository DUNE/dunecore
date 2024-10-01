# dunecore/dunecore/DuneInterface/Data/test/CMakeLists.txt

# David Adams
# May 2018

# Build test for each component.

include(CetTest)

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
