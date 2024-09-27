////////////////////////////////////////////////////////////////////////
/// \file  ProtoDUNEWireReadoutGeom.h
/// \brief Interface to algorithm class for a specific detector channel mapping in protoDUNE
///
/// \version $Id:  $
/// \author  Alex Himmel
///
/// 
/// November 2016
///
/// Inherits from the central DuneApaWireReadoutGeom, just adding special channel-mapping
/// specific to the photon detectors in protoDUNE.
///
////////////////////////////////////////////////////////////////////////
#ifndef geo_ProtoDUNEWireReadoutGeom_H
#define geo_ProtoDUNEWireReadoutGeom_H

#include "dunecore/Geometry/DuneApaWireReadoutGeom.h"

#include "larcoreobj/SimpleTypesAndConstants/readout_types.h" // readout::ROPID, ...
#include "larcoreobj/SimpleTypesAndConstants/RawTypes.h" // raw::ChannelID_t
#include "larcorealg/Geometry/WireReadoutGeom.h"

#include "fhiclcpp/fwd.h"

#include <map>
#include <memory>

namespace geo{

  class ProtoDUNEWireReadoutGeom : public DuneApaWireReadoutGeom {

  public:
  
    typedef unsigned int Index;
  
    ProtoDUNEWireReadoutGeom(fhicl::ParameterSet const& pset,
                             GeometryCore const* geom);

    // Photon detector methos being overridden here
    Index NOpChannels(Index NOpDets)                           const override;
    Index MaxOpChannel(Index NOpDets)                          const override;
    Index NOpHardwareChannels(Index opDet)                     const override;
    Index OpChannel(Index detNum, Index channel)               const override;
    Index OpDetFromOpChannel(Index opChannel)                  const override;
    Index HardwareChannelFromOpChannel(Index opChannel)        const override;
    bool  IsValidOpChannel(Index opChannel, Index /*NOpDets*/) const override
      {return fOpDet.count(opChannel); }
  
    // ProtoDUNE-specific
    Index SSPfromOpDet(Index opDet)                const;
    Index FirstSSPChFromOpDet(Index OpDet)         const;
    Index OpChannelFromSSP(Index ssp, Index sspch) const;
    void  PrintChannelMaps()                       const;

  private:
  
    Index fMaxOpChannel;
    Index fNOpChannels;
    std::map<Index, Index> fSSP;
    std::map<Index, Index> fSSPChOne;
    std::map<Index, Index> fOpDet;
    std::map<Index, Index> fHWChannel;

  
  }; // class ProtoDUNEWireReadoutGeom
  
  //----------------------------------------------------------------------------
  
  
}
#endif
