# dunecore/dunecore/DuneCommon/Service/ChannelStatus/CMakeLists.txt

# David Adams
# January 2023

install_headers()
install_source()

art_make(SERVICE_LIBRARIES 
                           dunecore_DuneCommon_Service_ToolBasedChannelStatus
                           art::Framework_Services_Registry
                           art::Framework_Principal
                           art_Framework_Core
                           art::Persistency_Provenance
                           messagefacility::MF_MessageLogger
                           ROOT::Core
         LIB_LIBRARIES
           dunecore_ArtSupport
           art::Persistency_Provenance
           canvas::canvas
           ROOT::HistPainter
           ROOT_BASIC_LIB_LIST
           FFTW3::FFTW3
)

#add_subdirectory(test)
