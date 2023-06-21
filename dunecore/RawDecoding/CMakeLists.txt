cet_build_plugin(FDHDDataInterface   art::tool
                        art_utilities
                        canvas::canvas
                        cetlib::cetlib
                        cetlib_except::cetlib_except
                        lardataobj::RawData
                        artdaq_core::artdaq-core_Data
                        artdaq_core::artdaq-core_Utilities
                        dunecore::ChannelMap_FDHDChannelMapService_service
			art::Framework_Core
                        art::Framework_Principal
                        art::Framework_Services_Registry
                        art_root_io::tfile_support
                        ROOT::Core
                        art_root_io::TFileService_service
                        art::Persistency_Provenance
                        messagefacility::MF_MessageLogger
                        dunecore::HDF5Utils
                        HDF5::HDF5
             )

install_headers()
install_fhicl()
install_source()
install_scripts()
