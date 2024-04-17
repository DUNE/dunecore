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
                           larevt::CalibrationDBI_Providers
                           larcoreobj::headers
                           larcore::headers
         LIB_LIBRARIES
           dunecore_ArtSupport
           larevt::CalibrationDBI_Providers
           larcoreobj::headers
           larcore::headers
           art::Persistency_Provenance
           canvas::canvas
           ROOT::HistPainter
           FFTW3::FFTW3
)

add_subdirectory(test)
