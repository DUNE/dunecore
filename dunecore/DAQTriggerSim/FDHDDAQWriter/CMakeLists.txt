
# these are temporary hacks -- may need to refactor these header-only products
# in a way that cmake can find the headers

include_directories( $ENV{DUNEDAQDATAFORMATS_INC} )
include_directories( $ENV{DUNEDETDATAFORMATS_INC} )

cet_build_plugin(FDHDDAQWriter art::Analyzer
  LIBRARIES
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
