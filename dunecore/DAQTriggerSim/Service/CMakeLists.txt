# dunetpc/dune/DAQTriggerSim/Service/CMakeLists.txt
#
# Michael Baird
# March 2016
#
# CMake instructions for DAQTriggerSim/Services

cet_build_plugin(TemplateTriggerService   art::service
                lardataobj::RawData
                larcoreobj::headers
                ROOT::Core
                nurandom::RandomUtils_NuRandomService_service
		art::Utilities canvas::canvas art::Framework_Principal
                messagefacility::MF_MessageLogger
                cetlib::cetlib cetlib_except::cetlib_except
             )

cet_build_plugin(HardwareMapperService   art::service
                larcorealg::Geometry
                dunecore_Geometry
                ROOT::Core
                messagefacility::MF_MessageLogger
                art::Utilities canvas::canvas art::Framework_Principal
             )

install_fhicl()
install_headers()
install_source()
