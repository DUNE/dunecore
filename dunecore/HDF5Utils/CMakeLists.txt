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
         LIBHDF5 
         pthread
         z
)

simple_plugin(HDF5RawInput "source"
  dunepdlegacy_Overlays
  HDF5Utils
  art::Framework_Services_Registry
)

install_headers()
install_fhicl()
install_source()
install_scripts()
