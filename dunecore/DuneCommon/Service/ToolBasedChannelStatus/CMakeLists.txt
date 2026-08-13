# dunecore/dunecore/DuneCommon/Service/ChannelStatus/CMakeLists.txt

# David Adams
# January 2023

install_headers()
install_source()

set(SERVICE_LIBRARIES 
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
)
set(         LIB_LIBRARIES
           dunecore_ArtSupport
           larevt::CalibrationDBI_Providers
           larcoreobj::headers
           larcore::headers
           art::Persistency_Provenance
           canvas::canvas
           ROOT::HistPainter
           FFTW3::FFTW3
)

cet_make_library(dunecore_DuneCommon_Service_ToolBasedChannelStatus LIBRARIES ${LIB_LIBRARIES} SOURCE ToolBasedChannelStatus.cxx ToolBasedChannelStatusService.cxx)
cet_build_plugin(ToolBasedChannelStatusService art::service LIBRARIES ${SERVICE_LIBRARIES} SOURCE ToolBasedChannelStatusService_service.cc)

add_subdirectory(test)
