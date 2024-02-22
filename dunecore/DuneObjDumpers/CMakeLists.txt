art_make(
  LIB_LIBRARIES
    ROOT::EG
    ROOT::Core
  MODULE_LIBRARIES
    dunecore::DuneObj
    nusimdata::SimulationBase
    art::Framework_Core
    art::Framework_Principal
    art::Persistency_Common
    art::Persistency_Provenance
    art::Utilities
    canvas::canvas
    messagefacility::MF_MessageLogger
    cetlib::cetlib
    cetlib_except::cetlib_except
    ROOT::EG
  ) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - deprecated: use art_make_library(), art_dictonary(), and cet_build_plugin() with explicit source lists and plugin base types

install_headers()
install_fhicl()
install_source()
