art_make_library(LIBRARY_NAME HDF5Utils
         SOURCE HDF5Utils.cc
         LIBRARIES
         #artdaq-core_Data
         #artdaq-core_Utilities
         #${ARTDAQ_DAQDATA}
         cetlib_except::cetlib_except
         fhiclcpp::fhiclcpp
         messagefacility::MF_MessageLogger
         #${RCEDAMLIB}
         lardataobj_RawData
         art::Framework_Principal
         #dune_VDColdbox_ChannelMap_VDColdboxChannelMapService_service 
         ART_FRAMEWORK_CORE
         ART_FRAMEWORK_PRINCIPAL
         ART_FRAMEWORK_SERVICES_REGISTRY
         LIBHDF5 
         pthread
         z
)

simple_plugin(HDF5RawInput "source"
  dune_raw_data::dune-raw-data_Overlays
  HDF5Utils
  art::Framework_Services_Registry
)

install_headers()
install_fhicl()
install_source()
install_scripts()
