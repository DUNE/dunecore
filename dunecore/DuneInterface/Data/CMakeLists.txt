# dunecore/dunecore/DuneInterface/Data/CMakeLists.txt
#
# David Adams
# September 2017
#
# CMake instructions for DUNE service interface classes.

add_subdirectory(test)

art_make(BASENAME_ONLY
  NO_PLUGINS
  LIBRARIES
  FFTW3::FFTW3
        )

# Including DataMap.h confers a transitive dependency on ROOT::Hist
cet_make_library(LIBRARY_NAME dunecore::DuneInterface_Data_DataMap INTERFACE
  SOURCE DataMap.h
  LIBRARIES INTERFACE ROOT::Hist
  FFTW3::FFTW3)

# Including RunData.h confers a transitive dependency on ROOT::Hist
cet_make_library(LIBRARY_NAME dunecore::DuneInterface_Data_RunData INTERFACE
  SOURCE RunData.h
  LIBRARIES INTERFACE ROOT::Hist
  FFTW3::FFTW3)

install_headers()
install_source()
