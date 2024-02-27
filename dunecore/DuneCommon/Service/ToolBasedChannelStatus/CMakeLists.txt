# dunecore/dunecore/DuneCommon/Service/ChannelStatus/CMakeLists.txt

# David Adams
# January 2023

install_headers()
install_source()

art_make(SERVICE_LIBRARIES 
                           dunecore_DuneCommon_Service_ToolBasedChannelStatus
                           art::Framework_Services_Registry
                           art::Framework_Principal
                           art::Framework_Core
                           art::Persistency_Provenance
                           messagefacility::MF_MessageLogger
                           ROOT::Core
         LIB_LIBRARIES
           larcore::Geometry_Geometry_service
	   larevt::CalibrationDBI_Providers
           dunecore_ArtSupport
           art::Persistency_Provenance
           canvas::canvas
           ROOT::HistPainter
           FFTW3::FFTW3
) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - deprecated: use art_make_library(), art_dictonary(), and cet_build_plugin() with explicit source lists and plugin base types

add_subdirectory(test)
