////////////////////////////////////////////////////////////////////////////////
/// \file DUNEGeometryHelper_service.cc
///
/// \author  rs@fnal.gov
////////////////////////////////////////////////////////////////////////////////

// class header
#include "dunecore/Geometry/DUNEGeometryHelper.h"

#include "art/Framework/Services/Registry/ServiceDefinitionMacros.h"

// LArSoft libraries
#include "larcorealg/Geometry/GeometryCore.h"
#include "larcorealg/Geometry/ChannelMapAlg.h"
#include "larcorealg/Geometry/ChannelMapStandardAlg.h"
#include "dunecore/Geometry/DuneApaChannelMapAlg.h"
#include "dunecore/Geometry/ChannelMap35Alg.h"
#include "dunecore/Geometry/ChannelMap35OptAlg.h"
#include "dunecore/Geometry/ChannelMapAPAAlg.h"
#include "dunecore/Geometry/ChannelMapCRMAlg.h"
#include "dunecore/Geometry/ChannelMapCRUAlg.h"
#include "dunecore/Geometry/ColdBoxChannelMapAlg.h"
#include "dunecore/Geometry/CRPChannelMapAlg.h"
#include "dunecore/Geometry/ProtoDUNEChannelMapAlg.h"
#include "dunecore/Geometry/ProtoDUNEChannelMapAlgv7.h"
#include "dunecore/Geometry/ProtoDUNEChannelMapAlgv8.h"
#include "larcorealg/Geometry/GeoObjectSorter.h"
#include "dunecore/Geometry/GeoObjectSorterAPA.h"
#include "dunecore/Geometry/GeoObjectSorter35.h"
#include "dunecore/Geometry/GeoObjectSorterICEBERG.h"

// C/C++ standard libraries
#include <string>

using std::string;
using geo::GeoObjectSorter;
using geo::GeoObjectSorterAPA;
using geo::GeoObjectSorter35;
using geo::GeoObjectSorterICEBERG;
using dune::DUNEGeometryHelper;

//**********************************************************************

DUNEGeometryHelper::DUNEGeometryHelper(const fhicl::ParameterSet& pset)
  : fChannelMapClass{pset.get<string>("ChannelMapClass", {})}
  , fGeoSorterClass{pset.get<string>("GeoSorterClass", {})}
{}

//**********************************************************************

std::unique_ptr<geo::ChannelMapAlg>
DUNEGeometryHelper::doConfigureChannelMapAlg(fhicl::ParameterSet const& pset,
                                             std::string const& detectorName) const
{
  std::unique_ptr<geo::ChannelMapAlg> channelMap{nullptr};

  // The APA sorting algorithm requires special handling.
  // This flag is set if that map is used.
  bool useApaMap = false;
  bool is35t = false;
  bool isICEBERG = false;

  // If class name is given use it.
  if ( fChannelMapClass.size() ) {
    if ( fChannelMapClass == "DuneApaChannelMapAlg" ) {
      useApaMap = true;
    } else if ( fChannelMapClass == "ChannelMap35Alg" ) {
      channelMap = std::make_unique<geo::ChannelMap35Alg>(pset);
    } else if ( fChannelMapClass == "ChannelMap35OptAlg" ) {
      channelMap = std::make_unique<geo::ChannelMap35OptAlg>(pset);
    } else if ( fChannelMapClass == "ChannelMapAPAAlg" ) {
      channelMap = std::make_unique<geo::ChannelMapAPAAlg>(pset);
    } else if ( fChannelMapClass == "ProtoDUNEChannelMapAlg" ) {
      channelMap = std::make_unique<geo::ProtoDUNEChannelMapAlg>(pset);
    } else if ( fChannelMapClass == "ProtoDUNEChannelMapAlgv7" ) {
      channelMap = std::make_unique<geo::ProtoDUNEChannelMapAlgv7>(pset);
    } else if ( fChannelMapClass == "ProtoDUNEChannelMapAlgv8" ) {
      channelMap = std::make_unique<geo::ProtoDUNEChannelMapAlgv8>(pset);
    } else {
      throw cet::exception("DUNEGeometryHelper") << "Invalid channel map class name:" << fChannelMapClass << "\n";
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
        channelMap = std::make_unique<geo::ChannelMap35Alg>(pset);
      }

    // DUNE 10kt
    } else if (( detectorName.find("dune10kt") != std::string::npos )
          || ( detectorName.find("lbne10kt") != std::string::npos )) {
      useApaMap = true;

    // DUNE 10kt dual phase
    } else if ( detectorName.find("dunedphase10kt") != std::string::npos ) {
      channelMap = std::make_unique<geo::ChannelMapCRMAlg>(pset);

    // DUNE 10kt vd
    } else if ( ( detectorName.find("dunevd10kt") != std::string::npos ) ) {
      channelMap = std::make_unique<geo::ChannelMapCRUAlg>(pset);

    // VD CRP cold box channel map 
    } else if ( ( detectorName.find("dunevdcb1") != std::string::npos ) ) {
      channelMap = std::make_unique<geo::ColdBoxChannelMapAlg>(pset);
      //channelMap = std::make_unique<geo::ChannelMapCRUAlg>(pset);

    // VD CRP2 cold box channel map 
    } else if ( ( detectorName.find("dunecrpcb") != std::string::npos ) ) {
      channelMap = std::make_unique<geo::CRPChannelMapAlg>(pset);
      //channelMap = std::make_unique<geo::ChannelMapCRUAlg>(pset);

    // protoDUNE 6x6x6 dual phase
    } else if ( detectorName.find("protodunedphase") != std::string::npos ) {
      channelMap = std::make_unique<geo::ChannelMapCRMAlg>(pset);

    // 3x1x1 dual phase
    } else if ( detectorName.find("3x1x1dphase") != std::string::npos ) {
      channelMap = std::make_unique<geo::ChannelMapCRMAlg>(pset);

    // DUNE 34kt
    } else if ( ( detectorName.find("dune34kt") != std::string::npos )
             || ( detectorName.find("lbne34kt") != std::string::npos ) ) {
      channelMap = std::make_unique<geo::ChannelMapAPAAlg>(pset);

    // protoDUNE with arapucas
    } else if ( detectorName.find("protodunev7") != std::string::npos ) {
      channelMap = std::make_unique<geo::ProtoDUNEChannelMapAlgv7>(pset);

    // protoDUNE with arapucas and updated paddles
    } else if ( detectorName.find("protodunev8") != std::string::npos ) {
      channelMap = std::make_unique<geo::ProtoDUNEChannelMapAlgv8>(pset);
      
    // protoDUNE VD
//    } else if ( detectorName.find("protodunevd_v1") != std::string::npos ) {
    } else if ( detectorName.find("protodunevd") != std::string::npos ) {
      channelMap = std::make_unique<geo::CRPChannelMapAlg>(pset);
      
    // protoDUNE
    } else if ( ( detectorName.find("protodune") != std::string::npos )
             || ( detectorName.find("protolbne") != std::string::npos ) ) {
      channelMap = std::make_unique<geo::ProtoDUNEChannelMapAlg>(pset);

    // iceberg
    } else if ( detectorName.find("iceberg") != std::string::npos ) {
      channelMap = std::make_unique<geo::ProtoDUNEChannelMapAlg>(pset);
      isICEBERG = true;
      useApaMap = true;
      
    // LArND
    } else if ( detectorName.find("larnd") != std::string::npos ) {
      channelMap = std::make_unique<geo::ChannelMapAPAAlg>(pset);
    }
    else {
      throw cet::exception("DUNEGeometryHelper") << "Unsupported detector: '" << detectorName << "'\n";
    }
  }



  if ( useApaMap ) {
    // Find the sorter.
    bool useApaSort = false;
    bool use35tSort = false;
    bool useICEBERGSort = false;
    
    GeoObjectSorter* psort = nullptr;
    if ( fGeoSorterClass.size() ) {
      if ( fGeoSorterClass == "GeoObjectSorterAPA" ) {
        useApaSort = true;
      } else if ( fGeoSorterClass == "GeoObjectSorter35" ) {
        use35tSort = true;
      }
      else if ( fGeoSorterClass == "GeoObjectSorterICEBERG" ) {
	useICEBERGSort = true;
      }
    } else {
      if ( is35t ) use35tSort = true;
      else if ( isICEBERG ) useICEBERGSort = true;
      else useApaSort = true;
    }

    // Construct the sorter.
    if ( useApaSort ) {
      psort = new GeoObjectSorterAPA(pset);
    } else if ( use35tSort ) {
      psort = new GeoObjectSorter35(pset);
    } else if ( useICEBERGSort ) {
      psort = new GeoObjectSorterICEBERG(pset);
    }
    
    // Create channel map and set sorter.
    auto alg = new geo::DuneApaChannelMapAlg(pset);
    alg->setSorter(*psort);
    channelMap = std::unique_ptr<geo::DuneApaChannelMapAlg>(alg);
  }

  return channelMap;
}

//**********************************************************************

DEFINE_ART_SERVICE_INTERFACE_IMPL(dune::DUNEGeometryHelper, geo::ExptGeoHelperInterface)

//**********************************************************************
