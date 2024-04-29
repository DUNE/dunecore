include_directories("${dunedaqdataformats_DIR}/../../../include")
include_directories("${dunedetdataformats_DIR}/../../../include")

art_make(MODULE_LIBRARIES
                        lardataobj::RawData
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
)

install_headers()
install_fhicl()
install_source()
install_scripts()
