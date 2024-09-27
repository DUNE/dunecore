////////////////////////////////////////////////////////////////////////////////
/// \file DUNEWireReadout_service.cc
///
/// \author  rs@fnal.gov
////////////////////////////////////////////////////////////////////////////////

// class header
#include "dunecore/Geometry/DUNEWireReadout.h"

// DUNE libraries
#include "dunecore/Geometry/DuneApaWireReadoutGeom.h"
#include "dunecore/Geometry/WireReadout35Geom.h"
#include "dunecore/Geometry/WireReadout35OptGeom.h"
#include "dunecore/Geometry/WireReadoutAPAGeom.h"
#include "dunecore/Geometry/WireReadoutCRMGeom.h"
#include "dunecore/Geometry/WireReadoutCRUGeom.h"
#include "dunecore/Geometry/ColdBoxWireReadoutGeom.h"
#include "dunecore/Geometry/CRPWireReadoutGeom.h"
#include "dunecore/Geometry/ProtoDUNEWireReadoutGeom.h"
#include "dunecore/Geometry/ProtoDUNEWireReadoutGeomv7.h"
#include "dunecore/Geometry/ProtoDUNEWireReadoutGeomv8.h"
#include "dunecore/Geometry/WireReadoutSorterAPA.h"
#include "dunecore/Geometry/WireReadoutSorter35.h"
#include "dunecore/Geometry/WireReadoutSorterICEBERG.h"

// LArSoft libraries
#include "larcore/Geometry/Geometry.h"
#include "larcorealg/Geometry/GeometryCore.h"
#include "larcorealg/Geometry/WireReadoutSorter.h"

// art libraries
#include "art/Framework/Services/Registry/ServiceHandle.h"
#include "art/Framework/Services/Registry/ServiceDefinitionMacros.h"

// C/C++ standard libraries
#include <string>

using geo::WireReadoutSorter;
using geo::WireReadoutSorterAPA;
using geo::WireReadoutSorter35;
using geo::WireReadoutSorterICEBERG;

//**********************************************************************

dune::DUNEWireReadout::DUNEWireReadout(fhicl::ParameterSet const& pset)
{
  auto const wireReadoutClass = pset.get<std::string>("WireReadoutClass", {});
  auto const wireSorterClass = pset.get<std::string>("WireSorterClass", {});

  // The APA sorting algorithm requires special handling.
  // This flag is set if that map is used.
  bool useApaMap = false;
  bool is35t = false;
  bool isICEBERG = false;

  auto const* geom = art::ServiceHandle<geo::Geometry const>().get();
  auto const& detectorName = geom->DetectorName();

  // If class name is given use it.
  if ( wireReadoutClass.size() ) {
    if ( wireReadoutClass == "DuneApaWireReadout" ) {
      useApaMap = true;
    } else if ( wireReadoutClass == "WireReadout35" ) {
      fWireReadout = std::make_unique<geo::WireReadout35Geom>(pset, geom);
    } else if ( wireReadoutClass == "WireReadout35Opt" ) {
      fWireReadout = std::make_unique<geo::WireReadout35OptGeom>(pset, geom);
    } else if ( wireReadoutClass == "WireReadoutAPA" ) {
      fWireReadout = std::make_unique<geo::WireReadoutAPAGeom>(pset, geom);
    } else if ( wireReadoutClass == "ProtoDUNEWireReadout" ) {
      fWireReadout = std::make_unique<geo::ProtoDUNEWireReadoutGeom>(pset, geom);
    } else if ( wireReadoutClass == "ProtoDUNEWireReadoutv7" ) {
      fWireReadout = std::make_unique<geo::ProtoDUNEWireReadoutGeomv7>(pset, geom);
    } else if ( wireReadoutClass == "ProtoDUNEWireReadoutv8" ) {
      fWireReadout = std::make_unique<geo::ProtoDUNEWireReadoutGeomv8>(pset, geom);
    } else {
      throw cet::exception("DUNEWireReadout") << "Invalid wire readout class name:" << wireReadoutClass << "\n";
    }

  // Otherwise derive class name from detector name.
  } else {
    // DUNE 35t prototype
    if ( ( detectorName.find("dune35t") != std::string::npos ) ||
         ( detectorName.find("lbne35t") != std::string::npos ) ) {
      std::string const detectorVersion = pset.get< std::string >("DetectorVersion");
      if (( detectorVersion.find("v3") != std::string::npos )
       || ( detectorVersion.find("v4") != std::string::npos )
       || ( detectorVersion.find("v5") != std::string::npos )
       || ( detectorVersion.find("v6") != std::string::npos )) {
        useApaMap = true;
        is35t = true;
      } else {
        fWireReadout = std::make_unique<geo::WireReadout35Geom>(pset, geom);
      }

    // DUNE 10kt
    } else if (( detectorName.find("dune10kt") != std::string::npos )
          || ( detectorName.find("lbne10kt") != std::string::npos )) {
      useApaMap = true;

    // DUNE 10kt dual phase
    } else if ( detectorName.find("dunedphase10kt") != std::string::npos ) {
      fWireReadout = std::make_unique<geo::WireReadoutCRMGeom>(pset, geom);

    // DUNE 10kt vd
    } else if ( ( detectorName.find("dunevd10kt") != std::string::npos ) ) {
      fWireReadout = std::make_unique<geo::WireReadoutCRUGeom>(pset, geom);

    // VD CRP cold box channel map
    } else if ( ( detectorName.find("dunevdcb1") != std::string::npos ) ) {
      fWireReadout = std::make_unique<geo::ColdBoxWireReadoutGeom>(pset, geom);

    // VD CRP2 cold box channel map
    } else if ( ( detectorName.find("dunecrpcb") != std::string::npos ) ) {
      fWireReadout = std::make_unique<geo::CRPWireReadoutGeom>(pset, geom);

    // protoDUNE 6x6x6 dual phase
    } else if ( detectorName.find("protodunedphase") != std::string::npos ) {
      fWireReadout = std::make_unique<geo::WireReadoutCRMGeom>(pset, geom);

    // 3x1x1 dual phase
    } else if ( detectorName.find("3x1x1dphase") != std::string::npos ) {
      fWireReadout = std::make_unique<geo::WireReadoutCRMGeom>(pset, geom);

    // DUNE 34kt
    } else if ( ( detectorName.find("dune34kt") != std::string::npos )
             || ( detectorName.find("lbne34kt") != std::string::npos ) ) {
      fWireReadout = std::make_unique<geo::WireReadoutAPAGeom>(pset, geom);

    // protoDUNE with arapucas
    } else if ( detectorName.find("protodunev7") != std::string::npos ) {
      fWireReadout = std::make_unique<geo::ProtoDUNEWireReadoutGeomv7>(pset, geom);

    // protoDUNE with arapucas and updated paddles
    } else if ( detectorName.find("protodunev8") != std::string::npos ) {
      fWireReadout = std::make_unique<geo::ProtoDUNEWireReadoutGeomv8>(pset, geom);

    // protoDUNE VD
    } else if ( detectorName.find("protodunevd") != std::string::npos ) {
      fWireReadout = std::make_unique<geo::CRPWireReadoutGeom>(pset, geom);

    // protoDUNE
    } else if ( ( detectorName.find("protodune") != std::string::npos )
             || ( detectorName.find("protolbne") != std::string::npos ) ) {
      fWireReadout = std::make_unique<geo::ProtoDUNEWireReadoutGeom>(pset, geom);

    // iceberg
    } else if ( detectorName.find("iceberg") != std::string::npos ) {
      fWireReadout = std::make_unique<geo::ProtoDUNEWireReadoutGeom>(pset, geom);
      isICEBERG = true;
      useApaMap = true;

    // LArND
    } else if ( detectorName.find("larnd") != std::string::npos ) {
      fWireReadout = std::make_unique<geo::WireReadoutAPAGeom>(pset, geom);
    }
    else {
      throw cet::exception("DUNEWireReadout") << "Unsupported detector: '" << detectorName << "'\n";
    }
  }



  if ( useApaMap ) {
    // Find the sorter.
    bool useApaSort = false;
    bool use35tSort = false;
    bool useICEBERGSort = false;

    std::unique_ptr<geo::WireReadoutSorter> psort{nullptr};
    if ( wireSorterClass.size() ) {
      if ( wireSorterClass == "WireReadoutSorterAPA" ) {
        useApaSort = true;
      } else if ( wireSorterClass == "WireReadoutSorter35" ) {
        use35tSort = true;
      }
      else if ( wireSorterClass == "WireReadoutSorterICEBERG" ) {
        useICEBERGSort = true;
      }
    } else {
      if ( is35t ) use35tSort = true;
      else if ( isICEBERG ) useICEBERGSort = true;
      else useApaSort = true;
    }

    // Construct the sorter.
    if ( useApaSort ) {
      psort = std::make_unique<WireReadoutSorterAPA>();
    } else if ( use35tSort ) {
      psort = std::make_unique<WireReadoutSorter35>(pset);
    } else if ( useICEBERGSort ) {
      psort = std::make_unique<WireReadoutSorterICEBERG>();
    }

    // Create channel map and set sorter.
    fWireReadout = std::make_unique<geo::DuneApaWireReadoutGeom>(pset, geom, std::move(psort));
  }
}

//**********************************************************************

DEFINE_ART_SERVICE_INTERFACE_IMPL(dune::DUNEWireReadout, geo::WireReadout)

//**********************************************************************
