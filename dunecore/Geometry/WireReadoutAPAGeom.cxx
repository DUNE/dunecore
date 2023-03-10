////////////////////////////////////////////////////////////////////////
/// \file  WireReadoutAPAGeom.cxx
/// \brief Interface to algorithm class for a specific detector channel mapping
///
/// \version $Id:  $
/// \author  tylerdalion@gmail.com
////////////////////////////////////////////////////////////////////////

#include "dunecore/Geometry/WireReadoutAPAGeom.h"
#include "larcorealg/Geometry/GeometryCore.h"
#include "larcorealg/Geometry/AuxDetGeo.h"
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/TPCGeo.h"
#include "larcorealg/Geometry/PlaneGeo.h"
#include "larcorealg/Geometry/WireGeo.h"
#include "larcorealg/Geometry/WireReadoutGeomBuilderStandard.h"

#include "art/Framework/Services/Registry/ServiceHandle.h"
#include "fhiclcpp/ParameterSet.h"
#include "messagefacility/MessageLogger/MessageLogger.h" 

namespace {
  class WireReadoutSorterAPA : public geo::WireReadoutSorter {
  private:
    bool compareWires(geo::WireGeo const& w1, geo::WireGeo const& w2) const override
    {
      auto const xyz1 = w1.GetCenter();
      auto const xyz2 = w2.GetCenter();

      // we want the wires to be sorted such that the smallest corner wire
      // on the readout end of a plane is wire zero, with wire number
      // increasing away from that wire.

      // if a top TPC, count from top down
      if( xyz1.Y()>0 && xyz1.Y() > xyz2.Y() ) return true;

      // if a bottom TPC, count from bottom up
      if( xyz1.Y()<0 && xyz1.Y() < xyz2.Y() ) return true;

      // sort the all vertical wires to increase in +z direction
      if( xyz1.Y() == xyz2.Y() && xyz1.Z() < xyz2.Z() ) return true;

      return false;
    }
  };
}

namespace geo{

  //----------------------------------------------------------------------------
  WireReadoutAPAGeom::WireReadoutAPAGeom(fhicl::ParameterSet const& p, GeometryCore const* geom)
    : WireReadoutGeom{geom,
                      std::make_unique<WireReadoutGeomBuilderStandard>(
                          p.get<fhicl::ParameterSet>("Builder", {})),
                      std::make_unique<WireReadoutSorterAPA>()}
  {
    fChannelsPerOpDet = p.get< unsigned int >("ChannelsPerOpDet"      );

    std::vector<geo::CryostatGeo> const& cgeo = geom->Cryostats();
    
    fNcryostat = cgeo.size();
    
    mf::LogInfo("WireReadoutAPAGeom") << "Initializing wire readout...";
      
    fNTPC.resize(fNcryostat);
    fFirstChannelInNextPlane.resize(1);  // Change 1 to Ncryostat if you want
    fFirstChannelInThisPlane.resize(1);  // to treat each APA uniquely,and do
                                         // the same with the other resizes.
    fPlanesPerAPA = Nplanes({0, 0});
    nAnchoredWires.resize(fPlanesPerAPA);
    fWiresInPlane.resize(fPlanesPerAPA);
    fFirstChannelInThisPlane[0].resize(1);  // remember FirstChannel vectors
    fFirstChannelInNextPlane[0].resize(1);  // for first APA only.
    fFirstChannelInThisPlane[0][0].resize(fPlanesPerAPA);  // Make room for info
    fFirstChannelInNextPlane[0][0].resize(fPlanesPerAPA);  // on each plane.
    fViews.clear();
    fPlaneIDs.clear();
    fTopChannel = 0;

    // Size some vectors and initialize the FirstChannel vectors.
    // If making FirstChannel's for every APA uniquely, they also
    // need to be sized here. Not necessary for now
    for(unsigned int cs = 0; cs != fNcryostat; ++cs){
      
      fNTPC[cs] = cgeo[cs].NTPC();

    }// end sizing loop over cryostats

    // Find the number of wires anchored to the frame
    for(unsigned int p=0; p!=fPlanesPerAPA; ++p){

      auto const& plane = Plane({0, 0, p});
      fWiresInPlane[p] = plane.Nwires();
      fViews.emplace(plane.View());
      
      for(unsigned int w = 0; w != fWiresInPlane[p]; ++w){

        // for vertical planes
        if(plane.View()==geo::kZ)   {
          nAnchoredWires[p] = fWiresInPlane[p];      
          break;
        }

        auto const xyz = plane.Wire(w).GetCenter();
        auto const xyz_next = plane.Wire(w+1).GetCenter();

        if(xyz.Z()==xyz_next.Z()){
	  nAnchoredWires[p] = w;      
	  break;
	}

      }// end wire loop

    }// end plane loop

    raw::ChannelID_t CurrentChannel = 0;
   
    for(unsigned int PCount = 0; PCount != fPlanesPerAPA; ++PCount){

      fFirstChannelInThisPlane[0][0][PCount] = CurrentChannel;
      CurrentChannel = CurrentChannel + 2*nAnchoredWires[PCount];
      fFirstChannelInNextPlane[0][0][PCount] = CurrentChannel;

    }// end build loop over planes

    // Save the number of channels
    fChannelsPerAPA = fFirstChannelInNextPlane[0][0][fPlanesPerAPA-1];

    fNchannels = 0;
    for(size_t cs = 0; cs < fNcryostat; ++cs){
      fNchannels = fNchannels + fChannelsPerAPA*fNTPC[cs]/2;
    }

    //save data into fFirstWireCenterY and fFirstWireCenterZ
    fPlaneData.resize(fNcryostat);
    for (unsigned int cs=0; cs<fNcryostat; ++cs){
      fPlaneData[cs].resize(cgeo[cs].NTPC());
      for (unsigned int tpc=0; tpc<cgeo[cs].NTPC(); ++tpc){
        fPlaneData[cs][tpc].resize(Nplanes({cs, tpc}));
        for (unsigned int plane=0; plane<Nplanes({cs, tpc}); ++plane){
          PlaneData_t& PlaneData = fPlaneData[cs][tpc][plane];
          auto const& pid = *fPlaneIDs.emplace(cs, tpc, plane).first;
          const geo::PlaneGeo& thePlane = Plane(pid);
          auto const xyz = thePlane.Wire(0).GetCenter();
          PlaneData.fFirstWireCenterY = xyz.Y();
          PlaneData.fFirstWireCenterZ = xyz.Z();
          // we are interested in the ordering of wire numbers: we find that a
          // point is N wires left of a wire W: is that wire W + N or W - N?
          // In fact, for TPC #0 it is W + N for V and Z planes, W - N for U
          // plane; for TPC #0 it is W + N for V and Z planes, W - N for U
          PlaneData.fWireSortingInZ = thePlane.WireIDincreasesWithZ()? +1.: -1.;

	  // find boundaries of the outside APAs for this plane by looking at endpoints of wires

          auto endpoint = thePlane.Wire(0).GetStart();
          PlaneData.fYmax = endpoint.Y();
          PlaneData.fYmin = endpoint.Y();
          PlaneData.fZmax = endpoint.Z();
          PlaneData.fZmin = endpoint.Z();
	  unsigned int nwires = thePlane.Nwires(); 
	  for (unsigned int iwire=0;iwire<nwires;iwire++){
            endpoint = thePlane.Wire(iwire).GetStart();
            PlaneData.fYmax = std::max(PlaneData.fYmax,endpoint.Y());
            PlaneData.fYmin = std::min(PlaneData.fYmin,endpoint.Y());
            PlaneData.fZmax = std::max(PlaneData.fZmax,endpoint.Z());
            PlaneData.fZmin = std::min(PlaneData.fZmin,endpoint.Z());
            endpoint = thePlane.Wire(iwire).GetEnd();
            PlaneData.fYmax = std::max(PlaneData.fYmax,endpoint.Y());
            PlaneData.fYmin = std::min(PlaneData.fYmin,endpoint.Y());
            PlaneData.fZmax = std::max(PlaneData.fZmax,endpoint.Z());
            PlaneData.fZmin = std::min(PlaneData.fZmin,endpoint.Z());
	  } // loop on wire 

        } // for plane
      } // for TPC
    } // for cryostat

    //initialize fWirePitch and fOrientation
    fWirePitch.resize(fPlanesPerAPA);
    fOrientation.resize(fPlanesPerAPA);
    fSinOrientation.resize(fPlanesPerAPA);
    fCosOrientation.resize(fPlanesPerAPA);

    for (unsigned int plane=0; plane<fPlanesPerAPA; plane++){
      auto const& planegeo = Plane({0, 0, plane});
      fWirePitch[plane]=planegeo.WirePitch();
      fOrientation[plane]=planegeo.Wire(0).ThetaZ();
      fSinOrientation[plane] = sin(fOrientation[plane]);
      fCosOrientation[plane] = cos(fOrientation[plane]);
    }


    for(unsigned int c=0; c<fNcryostat; c++){

      mf::LogVerbatim("WireReadoutAPAGeom") << "Cryostat " << c << ":";

      mf::LogVerbatim("WireReadoutAPAGeom") << "  " << fNchannels << " total channels";
      mf::LogVerbatim("WireReadoutAPAGeom") << "  " << fNTPC[c]/2 << " APAs";
      mf::LogVerbatim("WireReadoutAPAGeom") << "  For all identical APA:" ;
      mf::LogVerbatim("WireReadoutAPAGeom") << "    Number of channels per APA = " << fChannelsPerAPA ;
      
      mf::LogVerbatim("WireReadoutAPAGeom") << "    U channels per APA = " << 2*nAnchoredWires[0] ;
      mf::LogVerbatim("WireReadoutAPAGeom") << "    V channels per APA = " << 2*nAnchoredWires[1] ;
      mf::LogVerbatim("WireReadoutAPAGeom") << "    Z channels per APA = " << 2*nAnchoredWires[2] ;
      
      mf::LogVerbatim("WireReadoutAPAGeom") << "    Pitch in U Plane = " << fWirePitch[0] ;
      mf::LogVerbatim("WireReadoutAPAGeom") << "    Pitch in V Plane = " << fWirePitch[1] ;
      mf::LogVerbatim("WireReadoutAPAGeom") << "    Pitch in Z Plane = " << fWirePitch[2] ;
      
    }

    return;

  }
   
  //----------------------------------------------------------------------------
  std::vector<geo::WireID> WireReadoutAPAGeom::ChannelToWire(raw::ChannelID_t channel)  const
  {

    // first check if this channel ID is legal
    if(channel >= fNchannels )
      throw cet::exception("Geometry") << "ILLEGAL CHANNEL ID for channel " << channel << "\n";

    std::vector< WireID > AllSegments;
    
    static unsigned int cstat;
    static unsigned int tpc;
    static unsigned int plane;
    static unsigned int wireThisPlane;
    static unsigned int NextPlane;
    static unsigned int ThisPlane;
    
    raw::ChannelID_t chan       = channel%fChannelsPerAPA;
    raw::ChannelID_t pureAPAnum = std::floor( channel/fChannelsPerAPA );

    bool breakVariable = false;
    for(unsigned int planeloop = 0; planeloop != fPlanesPerAPA; ++planeloop){
          
      NextPlane = fFirstChannelInNextPlane[0][0][planeloop];
      ThisPlane = fFirstChannelInThisPlane[0][0][planeloop];
          
      if(chan < NextPlane){

        // fNTPC[0] works for now since there are the same number of TPCs per crostat
        cstat = std::floor( channel / ((fNTPC[0]/2)*fChannelsPerAPA) );
        tpc   = (2*pureAPAnum) % fNTPC[0];
        plane = planeloop;
        wireThisPlane  = chan - ThisPlane;
            
        breakVariable = true;
        break;
      }
      if(breakVariable) break;          
    }// end plane loop

    

    int WrapDirection = 1; // go from tpc to (tpc+1) or tpc to (tpc-1)

    // find the lowest wire
    raw::ChannelID_t ChannelGroup = std::floor( wireThisPlane/nAnchoredWires[plane] );
    unsigned int bottomwire = wireThisPlane-ChannelGroup*nAnchoredWires[plane];
    
    if(ChannelGroup%2==1){
      tpc += 1;
      WrapDirection  = -1;         
    }
    
    for(unsigned int SegCount = 0; SegCount != 50; ++SegCount){
      
      tpc += WrapDirection*(SegCount%2);
      geo::WireID CodeWire(cstat, tpc, plane, bottomwire + SegCount*nAnchoredWires[plane]);
      AllSegments.push_back(CodeWire);
      
      // reset the tcp variable so it doesnt "accumulate value"
      tpc -= WrapDirection*(SegCount%2);
      
      if( bottomwire + (SegCount+1)*nAnchoredWires[plane] > fWiresInPlane[plane]-1) break;
    }
    
    return AllSegments;
  }


  //----------------------------------------------------------------------------
  unsigned int WireReadoutAPAGeom::Nchannels() const
  {
    return fNchannels;
  }
  
  
  //----------------------------------------------------------------------------
  unsigned int WireReadoutAPAGeom::Nchannels
    (readout::ROPID const& ropid) const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::Nchannels(ROPID)
  
  
  //----------------------------------------------------------------------------
  double WireReadoutAPAGeom::WireCoordinate
    (double YPos, double ZPos, geo::PlaneID const& planeid) const
  {
    // Returns the wire number corresponding to a (Y,Z) position in the plane
    // with float precision.
    // Core code ripped from original NearestWireID() implementation
    
    const PlaneData_t& PlaneData = AccessElement(fPlaneData, planeid);
    
    //get the orientation angle of a given plane and calculate the distance between first wire
    //and a point projected in the plane
//    const double rotate = (planeid.TPC % 2 == 1)? -1.: +1.;
    
    // the formula used here is geometric:
    // distance = delta_y cos(theta_z) + delta_z sin(theta_z)
    // with a correction for the orientation of the TPC:
    // odd TPCs have supplementary wire angle (pi-theta_z), changing cosine sign
    
    const bool bSuppl = (planeid.TPC % 2) == 1;
    float distance =
      -(YPos - PlaneData.fFirstWireCenterY) * (bSuppl? -1.: +1.) * fCosOrientation[planeid.Plane]
      +(ZPos - PlaneData.fFirstWireCenterZ) * fSinOrientation[planeid.Plane]
      ;
    
    // The sign of this formula is correct if the wire with larger ID is on the
    // "right" (intuitively, larger z; rigorously, smaller intercept)
    // than this one.
    // Of course, we are not always that lucky. fWireSortingInZ fixes our luck.

    return PlaneData.fWireSortingInZ * distance/fWirePitch[planeid.Plane];
  } // WireReadoutAPAGeom::WireCoordinate()
  
  //----------------------------------------------------------------------------
  WireID WireReadoutAPAGeom::NearestWireID
    (const geo::Point_t& xyz, geo::PlaneID const& planeid) const
  {

    // cap the position to be within the boundaries of the wire endpoints.
    // This simulates charge drifting in from outside of the wire frames inwards towards
    // the first and last collection wires on the side, and towards the right endpoints

    const PlaneData_t& PlaneData = AccessElement(fPlaneData, planeid);
    double ycap = std::max(PlaneData.fYmin,std::min(PlaneData.fYmax,xyz.Y()));
    double zcap = std::max(PlaneData.fZmin,std::min(PlaneData.fZmax,xyz.Z()));

    // add 0.5 to have the correct rounding
    int NearestWireNumber
      = int (0.5 + WireCoordinate(ycap, zcap, planeid));
    
    // If we are outside of the wireplane range, throw an exception
    // (this response maintains consistency with the previous
    // implementation based on geometry lookup)
    if(NearestWireNumber < 0 ||
       NearestWireNumber >= (int) fWiresInPlane[planeid.Plane])
    {
      const int wireNumber = NearestWireNumber; // save for the output
      
      if(wireNumber < 0 ) NearestWireNumber = 0;
      else                NearestWireNumber = fWiresInPlane[planeid.Plane] - 1;
    
    /*
      // comment in the following statement to throw an exception instead
      throw InvalidWireIDError("Geometry", wireNumber, NearestWireNumber)
        << "WireReadoutAPAGeom::NearestWireID(): can't Find Nearest Wire for position ("
        << xyz.X() << "," << xyz.Y() << "," << xyz.Z() << ")"
        << " approx wire number # " << wireNumber
        << " (capped from " << NearestWireNumber << ")\n";
    */
    } // if invalid wire
    
    return { planeid, (geo::WireID::WireID_t) NearestWireNumber };
  } // WireReadoutAPAGeom::NearestWireID()
  
  
  //----------------------------------------------------------------------------
  raw::ChannelID_t WireReadoutAPAGeom::PlaneWireToChannel
    (geo::WireID const& wireid) const
  {
    unsigned int OtherSideWires = 0;

    // start in very first APA:
    raw::ChannelID_t Channel = fFirstChannelInThisPlane[0][0][wireid.Plane];
    // move channel to proper cryostat:
    Channel += wireid.Cryostat*(fNTPC[wireid.Cryostat]/2)*fChannelsPerAPA;
    // move channel to proper APA:
    Channel += std::floor( wireid.TPC/2 )*fChannelsPerAPA;
    // get number of wires on the first side of the APA if starting on the other side TPC:
    OtherSideWires += (wireid.TPC%2)*nAnchoredWires[wireid.Plane];


    // Lastly, account for the fact that channel number while moving up wire number in one
    // plane resets after 2 times the number of wires anchored -- one for each APA side.
    // At the same time, OtherSideWires accounts for the fact that if a channel starts on 
    // the other side, it is offset by the number of wires on the first side.
    Channel += (OtherSideWires + wireid.Wire)%(2*nAnchoredWires[wireid.Plane]);
    
    return Channel;

  }

  //----------------------------------------------------------------------------
  SigType_t WireReadoutAPAGeom::SignalTypeForChannelImpl( raw::ChannelID_t const channel )  const
  {
    raw::ChannelID_t chan = channel % fChannelsPerAPA;
    SigType_t sigt = kInduction;

    // instead of calling channel to wire, we can make use of the way we 
    // up channels among APAs;
    // the first two planes are induction, and the last one is collection
    if(       chan <  fFirstChannelInThisPlane[0][0][2]     ){ sigt = kInduction;  }
    else if( (chan >= fFirstChannelInThisPlane[0][0][2]) &&
             (chan <  fFirstChannelInNextPlane[0][0][2])    ){ sigt = kCollection; }
    else{    mf::LogWarning("BadChannelSignalType") << "Channel " << channel 
                                                    << " (" << chan << ") not given signal type." << std::endl;         }
  
    return sigt;
  }

  //----------------------------------------------------------------------------
  View_t WireReadoutAPAGeom::View( raw::ChannelID_t const channel )  const
  {
    raw::ChannelID_t chan = channel % fChannelsPerAPA;
    View_t view = geo::kU;

    // instead of calling channel to wire, we can make use of the way we 
    // up channels among APAs;
    // Plane 0: U, Plane 1: V, Plane 2: W
    if(       chan <  fFirstChannelInNextPlane[0][0][0]     ){ view = geo::kU; }
    else if( (chan >= fFirstChannelInThisPlane[0][0][1]) &&
             (chan <  fFirstChannelInNextPlane[0][0][1])    ){ view = geo::kV; }
    else if( (chan >= fFirstChannelInThisPlane[0][0][2]) &&
             (chan <  fFirstChannelInNextPlane[0][0][2])    ){ view = geo::kZ; }
    else{    mf::LogWarning("BadChannelViewType") << "Channel " << channel 
                                                  << " (" << chan << ") not given view type.";  }
    
    return view;
  }  

  //----------------------------------------------------------------------------
  std::set<View_t> const& WireReadoutAPAGeom::Views() const
  {
    return fViews;
  }

  //----------------------------------------------------------------------------
  std::set<PlaneID> const& WireReadoutAPAGeom::PlaneIDs() const
  {
    return fPlaneIDs;
  }

  //----------------------------------------------------------------------------
  unsigned int WireReadoutAPAGeom::NOpChannels(unsigned int NOpDets) const
  {
    return fChannelsPerOpDet*NOpDets;
  }

  //----------------------------------------------------------------------------
  unsigned int WireReadoutAPAGeom::NOpHardwareChannels(unsigned int opDet) const
  {
    return fChannelsPerOpDet;
  }

  //----------------------------------------------------------------------------
  unsigned int WireReadoutAPAGeom::OpChannel(unsigned int detNum, unsigned int channel) const
  {
    unsigned int uniqueChannel = (detNum * fChannelsPerOpDet) + channel;
    return uniqueChannel;
  }

  //----------------------------------------------------------------------------
  unsigned int WireReadoutAPAGeom::OpDetFromOpChannel(unsigned int opChannel) const
  {
    unsigned int detectorNum = (unsigned int) opChannel / fChannelsPerOpDet;
    return detectorNum;
  }

  //----------------------------------------------------------------------------
  unsigned int WireReadoutAPAGeom::HardwareChannelFromOpChannel(unsigned int opChannel) const
  {
    unsigned int channel = opChannel % fChannelsPerOpDet;
    return channel;
  }

  //----------------------------------------------------------------------------
  unsigned int WireReadoutAPAGeom::NTPCsets
    (readout::CryostatID const& cryoid) const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::NTPCsets()
  
  
  //----------------------------------------------------------------------------
  unsigned int WireReadoutAPAGeom::MaxTPCsets() const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::MaxTPCsets()
  
  
  //----------------------------------------------------------------------------
  bool WireReadoutAPAGeom::HasTPCset(readout::TPCsetID const& tpcsetid) const
  {
    return tpcsetid.TPCset < NTPCsets(tpcsetid);
  } // WireReadoutAPAGeom::HasTPCset()
  
  
  //----------------------------------------------------------------------------
  readout::TPCsetID WireReadoutAPAGeom::TPCtoTPCset
    (geo::TPCID const& tpcid) const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::TPCtoTPCset()
  
  
  //----------------------------------------------------------------------------
  std::vector<geo::TPCID> WireReadoutAPAGeom::TPCsetToTPCs
    (readout::TPCsetID const& tpcsetid) const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::TPCsetToTPCs()
  
  
  //----------------------------------------------------------------------------
  geo::TPCID WireReadoutAPAGeom::FirstTPCinTPCset
    (readout::TPCsetID const& tpcsetid) const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::FirstTPCinTPCset()
  
  
  //----------------------------------------------------------------------------
  unsigned int WireReadoutAPAGeom::NROPs
      (readout::TPCsetID const& tpcsetid) const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::NROPs()
  
  
  //----------------------------------------------------------------------------
  unsigned int WireReadoutAPAGeom::MaxROPs() const {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::MaxROPs()
  
  
  //----------------------------------------------------------------------------
  bool WireReadoutAPAGeom::HasROP(readout::ROPID const& ropid) const {
    return ropid.ROP < NROPs(ropid);
  } // WireReadoutAPAGeom::HasROP()
  
  
  //----------------------------------------------------------------------------
  readout::ROPID WireReadoutAPAGeom::WirePlaneToROP
    (geo::PlaneID const& planeid) const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::WirePlaneToROP()
  
  
  //----------------------------------------------------------------------------
  std::vector<geo::PlaneID> WireReadoutAPAGeom::ROPtoWirePlanes
    (readout::ROPID const& ropid) const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::ROPtoWirePlanes()
  
  
  //----------------------------------------------------------------------------
  std::vector<geo::TPCID> WireReadoutAPAGeom::ROPtoTPCs
    (readout::ROPID const& ropid) const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::ROPtoTPCs()
  
  
  //----------------------------------------------------------------------------
  readout::ROPID WireReadoutAPAGeom::ChannelToROP
    (raw::ChannelID_t channel) const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::ROPtoTPCs()
  
  
  //----------------------------------------------------------------------------
  raw::ChannelID_t WireReadoutAPAGeom::FirstChannelInROP
    (readout::ROPID const& ropid) const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::FirstChannelInROP()
  
  
  //----------------------------------------------------------------------------
  geo::PlaneID WireReadoutAPAGeom::FirstWirePlaneInROP
    (readout::ROPID const& ropid) const
  {
    throw cet::exception("WireReadoutAPAGeom") << __func__ << " not implemented!\n";
  } // WireReadoutAPAGeom::FirstWirePlaneInROP()
  
  
} // namespace
