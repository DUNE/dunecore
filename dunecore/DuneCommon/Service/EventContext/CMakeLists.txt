# dunecore/dunecore/DuneCommon/Service/EventContext/CMakeLists.txt

# David Adams
# January 2023

install_headers()
install_source()

set(SERVICE_LIBRARIES 
           dunecore_DuneCommon_Utility
           art::Framework_Services_Registry
           art::Framework_Principal
           art::Framework_Core
           art::Persistency_Provenance
           messagefacility::MF_MessageLogger
           ROOT::Core
)
cet_build_plugin(EventContextService art::service LIBRARIES ${SERVICE_LIBRARIES} SOURCE EventContextService_service.cc)

add_subdirectory(test)
