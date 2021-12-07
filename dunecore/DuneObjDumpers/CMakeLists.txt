art_make(
  LIB_LIBRARIES
    ROOT_EG
    ROOT::Core
  MODULE_LIBRARIES
  #dune_DuneObjDumpers
    dune_DuneObj
    nusimdata::SimulationBase
    ART_FRAMEWORK_CORE
    ART_FRAMEWORK_PRINCIPAL
    art::Persistency_Common
    art::Persistency_Provenance
    art::Utilities
    canvas::canvas
    messagefacility::MF_MessageLogger

  cetlib::cetlib cetlib_except
    ROOT_EG
    ROOT_BASIC_LIB_LIST
  )

install_headers()
install_fhicl()
install_source()
