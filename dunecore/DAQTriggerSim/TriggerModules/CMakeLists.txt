#art_make( BASENAME_ONLY

set(          MODULE_LIBRARIES dunecore::DAQTriggerSim_TriggerDataProducts
                           dunecore::DAQTriggerSim_TriggerAlgorithms
                           larcore::Geometry_Geometry_service
                           larcorealg::Geometry
                           nusimdata::SimulationBase
                           larsim::MCCheater_ParticleInventoryService_service
                           art::Framework_Core
                           art::Framework_Principal
                           art::Framework_Services_Registry
                           art_root_io::tfile_support
                           ROOT::Core
                           art_root_io::TFileService_service
                           art::Persistency_Common
                           art::Persistency_Provenance
                           art::Utilities
			   canvas::canvas
                           messagefacility::MF_MessageLogger
                           cetlib::cetlib 
			   cetlib_except::cetlib_except
	 )

cet_build_plugin(ActivityTriggerProd art::module LIBRARIES ${MODULE_LIBRARIES} SOURCE ActivityTriggerProd_module.cc BASENAME_ONLY)
cet_build_plugin(TemplateTriggerProd art::module LIBRARIES ${MODULE_LIBRARIES} SOURCE TemplateTriggerProd_module.cc BASENAME_ONLY)

install_fhicl()
install_headers()
install_source()
