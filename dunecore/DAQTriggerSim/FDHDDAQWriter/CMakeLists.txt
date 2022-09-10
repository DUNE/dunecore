
art_make(MODULE_LIBRARIES
                        lardataobj_RawData
                        art::Framework_Core
                        art::Framework_Principal
                        art::Framework_Services_Registry
                        art_root_io::tfile_support
                        ROOT::Core
                        art_root_io::TFileService_service
                        ART_PERSISTENCY_PROVENANCE
                        messagefacility::MF_MessageLogger
                        CETLIB
                        ROOT_BASIC_LIB_LIST
			LIBHDF5
                        dunecore::ChannelMap_FDHDChannelMapService_service
                        BASENAME_ONLY
)


install_headers()
install_fhicl()
install_source()
install_scripts()
