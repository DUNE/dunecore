art_make_library(LIBRARY_NAME HDF5Utils
         SOURCE HDF5Utils.cc
         LIBRARIES
         cetlib_except::cetlib_except
         fhiclcpp::fhiclcpp
         messagefacility::MF_MessageLogger
         lardataobj::RawData
         art::Framework_Principal
         art::Framework_Core
         art::Framework_Principal
         art::Framework_Services_Registry
         HDF5::HDF5
         pthread
         z
)

simple_plugin(HDF5RawInput "source"
  dunepdlegacy_Overlays
  HDF5Utils
  art::Framework_Services_Registry
)

simple_plugin(HDF5RawInput2 "source"
  dunepdlegacy_Overlays
  HDF5Utils
  dunecore::dunedaqhdf5utils2
  art::Framework_Services_Registry
  dunecore::HDF5Utils_HDF5RawFile2Service_service
)

simple_plugin(HDF5TPStreamInput2 "source"
  dunepdlegacy_Overlays
  HDF5Utils
  dunecore::dunedaqhdf5utils2
  art::Framework_Services_Registry
  dunecore::HDF5Utils_HDF5RawFile2Service_service
)

simple_plugin(HDF5RawFile2Service "service"
              ${ART_PERSISTENCY_ROOTDB}
              art::Framework_Services_Registry
              ${persistency_lib}
              SQLite::SQLite3
              messagefacility::MF_MessageLogger
              ${CETLIB_LIBS}
	      dunecore::dunedaqhdf5utils2
)

add_subdirectory(dunedaqhdf5utils2)

install_headers()
install_fhicl()
install_source()
install_scripts()
