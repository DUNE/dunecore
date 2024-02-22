# dunecore/dunecore/DuneCommon/Service/EventContext/CMakeLists.txt

# David Adams
# January 2023

install_headers()
install_source()

art_make(SERVICE_LIBRARIES 
           dunecore_DuneCommon_Utility
           art::Framework_Services_Registry
           art::Framework_Principal
           art_Framework_Core
           art::Persistency_Provenance
           messagefacility::MF_MessageLogger
           ROOT::Core
) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - deprecated: use art_make_library(), art_dictonary(), and cet_build_plugin() with explicit source lists and plugin base types

add_subdirectory(test)
