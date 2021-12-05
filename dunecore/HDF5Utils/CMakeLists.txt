art_make_library(LIBRARY_NAME HDF5Utils
         SOURCE HDF5Utils.cc
         LIBRARIES
         #artdaq-core_Data
         #artdaq-core_Utilities
         #${ARTDAQ_DAQDATA}
         ${CETLIB_EXCEPT}
         ${Boost_SYSTEM_LIBRARY}
         ${FHICLCPP}
         ${MF_MESSAGELOGGER}
         ${MF_MESSAGEUTILITIES}
         #${RCEDAMLIB}
         ${GALLERY_LIB}
         ${ART_LIB}
         lardataobj_RawData
         art_Framework_Principal
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
  art_Framework_Services_Registry
)

install_headers()
install_fhicl()
install_source()
install_scripts()
