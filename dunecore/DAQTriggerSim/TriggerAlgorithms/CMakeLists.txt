#for classes_def.xml

include_directories( ${CMAKE_CURRENT_SOURCE_DIR} )

art_make(
  LIB_LIBRARIES    
  nusimdata::SimulationBase
  larcorealg::Geometry
  larcore::Geometry_Geometry_service
  larsim::MCCheater_BackTrackerService_service
  larsim::MCCheater_ParticleInventoryService_service
  art::Framework_Core
  art::Framework_Principal
  art::Framework_Services_Registry
  art::Persistency_Common
  art::Persistency_Provenance
  art::Utilities
  canvas::canvas
  cetlib::cetlib 
  cetlib_except::cetlib_except
  Boost::filesystem              
  messagefacility::MF_MessageLogger
  fhiclcpp::fhiclcpp
  dunecore::DAQTriggerSim_TriggerDataProducts
  )


install_headers()
install_source()
