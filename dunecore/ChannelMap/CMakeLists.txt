# Tom Junk 2022

install_fhicl()
install_headers()
install_source()

file(GLOB channel_map_files *Map*.txt)
install_fw( LIST ${channel_map_files} )

art_make(SERVICE_LIBRARIES 
                           art::Framework_Services_Registry
                           art::Framework_Principal
                           art_Framework_Core
                           art::Persistency_Provenance
                           messagefacility::MF_MessageLogger
                           ROOT::Core
 	                   dunecore::ChannelMap
) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - deprecated: use art_make_library(), art_dictonary(), and cet_build_plugin() with explicit source lists and plugin base types

