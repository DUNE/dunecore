
art_make(MODULE_LIBRARIES
                        lardataobj_RawData
                        art::Framework_Core
                        art::Framework_Principal
                        art::Framework_Services_Registry
                        art_root_io::tfile_support
                        ROOT::Core
                        art_root_io::TFileService_service
                        messagefacility::MF_MessageLogger
			HDF5::HDF5
                        dunecore::ChannelMap_FDHDChannelMapService_service
                        BASENAME_ONLY
) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - deprecated: use art_make_library(), art_dictonary(), and cet_build_plugin() with explicit source lists and plugin base types

install_headers()
install_fhicl()
install_source()
install_scripts()
