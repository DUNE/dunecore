# Tom Junk 2022
find_package( nlohmann_json REQUIRED )
include_directories($ENV{NLOHMANN_JSON_INC})
include_directories("${nlohmann_json_DIR}/../../../include")

install_fhicl()
install_headers()
install_source()

file(GLOB channel_map_files *Map*.txt)
install_fw( LIST ${channel_map_files} )

art_make(SERVICE_LIBRARIES 
                           art::Framework_Services_Registry
                           art::Framework_Principal
                           art::Framework_Core
                           art::Persistency_Provenance
                           messagefacility::MF_MessageLogger
                           ROOT::Core
 	                   dunecore::ChannelMap
)

art_make_library(
  LIBRARY_NAME opdet_PDVDPDMapAlg
  SOURCE
    PDVDPDMapAlg_tool.cc
  LIBRARIES
    art::Framework_Core
    art::Utilities
    messagefacility::MF_MessageLogger
    fhiclcpp::fhiclcpp
    ROOT::Core
    nlohmann_json::nlohmann_json
)
  
# install PDVD_PDS_Mapping.json with mapping of the photon detectors
install_fw(LIST
           PDVD_PDS_Mapping_v04152025.json 
           PDVD_PDS_Mapping_v07082025.json
           PDVD_PDS_Mapping_v09162025.json)
