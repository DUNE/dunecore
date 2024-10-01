////////////////////////////////////////////////////////////////////////
/// \file  WireReadout35Geom.cxx
/// \brief The class of 35t specific algorithms
///
/// \version $Id:  $
/// \author  tylerdalion@gmail.com
////////////////////////////////////////////////////////////////////////
///
/// Any gdml before v3 should stay configured to use WireReadout35Geom, and
/// any gdml v3 or later should be configured to use WireReadout35OptGeom.
/// This is done in DUNEWireReadout using the fcl parameter DetectorVersion
/// in the SortingParameters pset.
///
#include "dunecore/Geometry/WireReadout35Geom.h"
#include "dunecore/Geometry/WireReadoutSorter35.h"
#include "larcorealg/Geometry/GeometryCore.h"
#include "larcorealg/Geometry/AuxDetGeo.h"
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/TPCGeo.h"
#include "larcorealg/Geometry/PlaneGeo.h"
#include "larcorealg/Geometry/WireGeo.h"
#include "larcorealg/Geometry/WireReadoutGeomBuilderStandard.h"
#include "larcorealg/Geometry/WireReadoutSorter.h"

#include "art/Framework/Services/Registry/ServiceHandle.h"
#include "messagefacility/MessageLogger/MessageLogger.h" 

namespace geo{

  //----------------------------------------------------------------------------
  WireReadout35Geom::WireReadout35Geom(fhicl::ParameterSet const& p, GeometryCore const* geom)
    : WireReadoutGeom{geom,
                      std::make_unique<WireReadoutGeomBuilderStandard>(
                          p.get<fhicl::ParameterSet>("Builder", {})),
                      std::make_unique<WireReadoutSorter35>(p)}
  {
    std::vector<geo::CryostatGeo> const& cgeo = geom->Cryostats();
    
    fNcryostat = cgeo.size();
    
    mf::LogInfo("WireReadout35Geom") << "Initializing...";
      
    fNTPC.resize(fNcryostat);
    fWiresPerPlane.resize(fNcryostat);
    fFirstChannelInNextPlane.resize(fNcryostat);
    fFirstChannelInThisPlane.resize(fNcryostat);
    nAnchoredWires.resize(fNcryostat);
    fViews.clear();
    fPlaneIDs.clear();
    fPlanesPerAPA = Nplanes({0, 0});

    fTopChannel = 0;

    // Size some vectors and initialize the FirstChannel vectors.
    for(unsigned int cs = 0; cs != fNcryostat; ++cs){
      
      fNTPC[cs] = cgeo[cs].NTPC();

      nAnchoredWires[cs].resize(fNTPC[cs]);
      fWiresPerPlane[cs].resize(fNTPC[cs]);
      fFirstChannelInThisPlane[cs].resize(fNTPC[cs]/2);
      fFirstChannelInNextPlane[cs].resize(fNTPC[cs]/2);

      for(unsigned int apa = 0; apa != fNTPC[cs]/2; ++apa){
        
        nAnchoredWires[cs][apa].resize(fPlanesPerAPA);
        fWiresPerPlane[cs][apa].resize(fPlanesPerAPA);
        fFirstChannelInThisPlane[cs][apa].resize(fPlanesPerAPA);
        fFirstChannelInNextPlane[cs][apa].resize(fPlanesPerAPA);

      }// end loop over apas
    }// end cryostats

    // Find the number of wires anchored to the frame
    for(unsigned int c = 0; c != fNcryostat; ++c){
      for(unsigned int a = 0; a != fNTPC[c]/2; ++a){
        for(unsigned int p = 0; p != fPlanesPerAPA; ++p){

          unsigned int t = 2*a;
          auto const& plane = Plane({c, t, p});
          fWiresPerPlane[c][a][p] = plane.Nwires();
          fViews.emplace(plane.View());

          for(unsigned int w = 0; w != fWiresPerPlane[c][a][p]; ++w){

            // for vertical planes
            if(plane.View() == geo::kZ)   {
              nAnchoredWires[c][a][p] = fWiresPerPlane[c][a][p];      
              break;
            }

            auto const xyz = plane.Wire(w).GetCenter();
            auto const xyz_next = plane.Wire(w+1).GetCenter();

            if(xyz.Z()==xyz_next.Z()){
              nAnchoredWires[c][a][p] = w-1; // this is a known bug, should be w
                                             // fixed in WireReadout35Geom
              break;
            }

          }
        }
      }
    }

    raw::ChannelID_t CurrentChannel = 0;
 
    for(unsigned int cs = 0; cs != fNcryostat; ++cs){
      for(unsigned int apa = 0; apa != fNTPC[cs]/2; ++apa){  
        for(unsigned int p = 0; p != fPlanesPerAPA; ++p){

          fFirstChannelInThisPlane[cs][apa][p] = CurrentChannel;
          CurrentChannel = CurrentChannel + 2*nAnchoredWires[cs][apa][p];
          fFirstChannelInNextPlane[cs][apa][p] = CurrentChannel;

        }// end plane loop
      }// end apa loop
    }// end cs


    // Save the number of channels
    fNchannels = CurrentChannel;

    // Save the number of channels
    fChannelsPerAPA = fFirstChannelInNextPlane[0][0][fPlanesPerAPA-1];

    
    fWirePitch.resize(fPlanesPerAPA);
    fOrientation.resize(fPlanesPerAPA);
    fSinOrientation.resize(fPlanesPerAPA);
    fCosOrientation.resize(fPlanesPerAPA);


    //save data into fFirstWireCenterY, fFirstWireCenterZ and fWireSortingInZ
    fPlaneData.resize(fNcryostat);
    for (unsigned int cs=0; cs<fNcryostat; cs++){
      fPlaneData[cs].resize(fNTPC[cs]);
      for (unsigned int tpc=0; tpc<fNTPC[cs]; tpc++){
        fPlaneData[cs][tpc].resize(fPlanesPerAPA);
        for (unsigned int plane=0; plane<fPlanesPerAPA; plane++){
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

	  // find boundaries of the APA frame for this plane by looking at endpoints of wires

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
    for (unsigned int plane=0; plane<fPlanesPerAPA; plane++){
      auto const& planegeo = Plane({0, 0, plane});
      fWirePitch[plane]=planegeo.WirePitch();
      fOrientation[plane]=planegeo.Wire(0).ThetaZ();
      fSinOrientation[plane] = sin(fOrientation[plane]);
      fCosOrientation[plane] = cos(fOrientation[plane]);

    } // for
    
    
    mf::LogVerbatim("WireReadout35Geom") << "fNchannels = " << fNchannels ;
    mf::LogVerbatim("WireReadout35Geom") << "U channels per APA = " << 2*nAnchoredWires[0][0][0] ;
    mf::LogVerbatim("WireReadout35Geom") << "V channels per APA = " << 2*nAnchoredWires[0][0][1] ;
    mf::LogVerbatim("WireReadout35Geom") << "Z channels per APA side = " << nAnchoredWires[0][0][2] ;

    mf::LogVerbatim("WireReadout35Geom") << "Pitch in U Plane = " << fWirePitch[0] ;
    mf::LogVerbatim("WireReadout35Geom") << "Pitch in V Plane = " << fWirePitch[1] ;
    mf::LogVerbatim("WireReadout35Geom") << "Pitch in Z Plane = " << fWirePitch[2] ;

    return;

  }
   
  //----------------------------------------------------------------------------
  std::vector<geo::WireID> WireReadout35Geom::ChannelToWire(raw::ChannelID_t channel)  const
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
    
    for(unsigned int csloop = 0; csloop != fNcryostat; ++csloop){
      
      bool breakVariable = false;
      
      for(unsigned int apaloop = 0; apaloop != fNTPC[csloop]/2; ++apaloop){
        for(unsigned int planeloop = 0; planeloop != fPlanesPerAPA; ++planeloop){
          
          NextPlane = fFirstChannelInNextPlane[csloop][apaloop][planeloop];
                 ThisPlane = fFirstChannelInThisPlane[csloop][apaloop][planeloop];
          
          if(channel < NextPlane){
            
            cstat = csloop;
            tpc   = 2*apaloop;
            plane = planeloop;
            wireThisPlane  = channel - ThisPlane;
            
            breakVariable = true;
            break;
          }// end if break          
          if(breakVariable) break;
          
        }// end plane loop        
        if(breakVariable) break;
        
      }// end apa loop      
      if(breakVariable) break;
      
    }// end cryostat loop
    

    int WrapDirection = 1; // go from tpc to (tpc+1) or tpc to (tpc-1)

    // find the lowest wire
    raw::ChannelID_t ChannelGroup = std::floor( wireThisPlane/nAnchoredWires[cstat][tpc/2][plane] );
    unsigned int bottomwire = wireThisPlane-ChannelGroup*nAnchoredWires[cstat][tpc/2][plane];
    
    if(ChannelGroup%2==1){
      // start in the other TPC
      tpc += 1;
      WrapDirection  = -1;         
    }
    
    for(unsigned int WireSegmentCount = 0; WireSegmentCount != 50; ++WireSegmentCount){
      
      tpc += WrapDirection*(WireSegmentCount%2);
      
      geo::WireID CodeWire(cstat, tpc, plane, bottomwire + WireSegmentCount*nAnchoredWires[cstat][std::floor(tpc/2)][plane]);
      
      AllSegments.push_back(CodeWire);
      
      // reset the tcp variable so it doesnt "accumulate value"
      tpc -= WrapDirection*(WireSegmentCount%2);
      
      if( bottomwire + (WireSegmentCount+1)*nAnchoredWires[cstat][std::floor(tpc/2)][plane] > 
          fWiresPerPlane[cstat][std::floor(tpc/2)][plane]-1) break;
      
    } //end WireSegmentCount loop
    
    
    return AllSegments;
  }


  //----------------------------------------------------------------------------
  unsigned int WireReadout35Geom::Nchannels() const
  {
    return fNchannels;
  }
  

  //----------------------------------------------------------------------------
  unsigned int WireReadout35Geom::Nchannels
    (readout::ROPID const& ropid) const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::Nchannels(ROPID)
  
  
  //----------------------------------------------------------------------------
  double WireReadout35Geom::WireCoordinate
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
  } // WireReadout35Geom::WireCoordinate()
  
  
  //----------------------------------------------------------------------------
  WireID WireReadout35Geom::NearestWireID
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
       NearestWireNumber >= (int) WiresPerPlane(planeid))
    {
      const int wireNumber = NearestWireNumber; // save for the output
      
      if(wireNumber < 0 ) NearestWireNumber = 0;
      else                NearestWireNumber = WiresPerPlane(planeid) - 1;
    
    /*
      // comment in the following statement to throw an exception instead
      throw InvalidWireIDError("Geometry", wireNumber, NearestWireNumber)
        << "WireReadout35Geom::NearestWireID(): can't Find Nearest Wire for position ("
        << xyz.X() << "," << xyz.Y() << "," << xyz.Z() << ")"
        << " approx wire number # " << wireNumber
        << " (capped from " << NearestWireNumber << ")\n";
    */
    } // if invalid wire
    
    return { planeid, (geo::WireID::WireID_t) NearestWireNumber };
  } // WireReadout35Geom::NearestWireID()
  
  //----------------------------------------------------------------------------
  raw::ChannelID_t WireReadout35Geom::PlaneWireToChannel
    (geo::WireID const& wireid) const
  {

    unsigned int OtherSideWires = 0;

    raw::ChannelID_t Channel = AccessAPAelement(fFirstChannelInThisPlane, wireid);

    // get number of wires starting on the first side of the APA if starting
    // on the other side TPC.
    if (wireid.TPC % 2 == 1) OtherSideWires += AnchoredWires(wireid);
    
    // Lastly, account for the fact that channel number while moving up wire number in one
    // plane resets after 2 times the number of wires anchored -- one for each APA side.
    // At the same time, OtherSideWires accounts for the fact that if a channel starts on
    // the other side, it is offset by the number of wires on the first side.
    Channel += (OtherSideWires + wireid.Wire)%(2*AnchoredWires(wireid));

    return Channel;

  }


  //----------------------------------------------------------------------------
  SigType_t WireReadout35Geom::SignalTypeForChannelImpl( raw::ChannelID_t const channel )  const
  {
    raw::ChannelID_t chan = channel % fChannelsPerAPA;
    SigType_t sigt = kInduction;

    if(       chan <  fFirstChannelInThisPlane[0][0][2]     ){ sigt = kInduction;  }
    else if( (chan >= fFirstChannelInThisPlane[0][0][2]) &&
             (chan <  fFirstChannelInNextPlane[0][0][2])    ){ sigt = kCollection; }
    else{    mf::LogWarning("BadChannelSignalType") << "Channel " << channel 
                                                    << " (" << chan << ") not given signal type." << std::endl;         }
  
    return sigt;
  }

  //----------------------------------------------------------------------------
  View_t WireReadout35Geom::View( raw::ChannelID_t const channel )  const
  {
    raw::ChannelID_t chan = channel % fChannelsPerAPA;
    View_t view = geo::kU;

    if(       chan <  fFirstChannelInNextPlane[0][0][0]     ){ view = geo::kU; }
    else if( (chan >= fFirstChannelInThisPlane[0][0][1]) &&
             (chan <  fFirstChannelInNextPlane[0][0][1])    ){ view = geo::kV; }
    else if( (chan >= fFirstChannelInThisPlane[0][0][2]) &&
             (chan <  fFirstChannelInNextPlane[0][0][2])    ){ view = geo::kZ; }
    else{    mf::LogWarning("BadChannelViewType") << "Channel " << channel 
                                                  << " (" << chan << ") not given view type.";}
    
    return view;
  }  
 
  //----------------------------------------------------------------------------
  std::set<View_t> const& WireReadout35Geom::Views() const
  {
    return fViews;
  }

  //----------------------------------------------------------------------------
  std::set<PlaneID> const& WireReadout35Geom::PlaneIDs() const
  {
    return fPlaneIDs;
  }

  //----------------------------------------------------------------------------
  unsigned int WireReadout35Geom::NOpChannels(unsigned int NOpDets) const
  {
    return 12*NOpDets;
  }

  //----------------------------------------------------------------------------
  unsigned int WireReadout35Geom::NOpHardwareChannels(unsigned int opDet) const
  {
    // CSU 3-sipm design
    if (opDet == 0 || opDet == 4 || opDet == 6)
      return 8;

    // LSU 2-sipm design
    if (opDet == 2)
      return 2;

    // IU 12-sipm design
    return 12;
  }

  //----------------------------------------------------------------------------
  unsigned int WireReadout35Geom::OpChannel(unsigned int detNum, unsigned int channel) const
  {
    unsigned int uniqueChannel = (detNum * 12) + channel;
    return uniqueChannel;
  }

  //----------------------------------------------------------------------------
  unsigned int WireReadout35Geom::OpDetFromOpChannel(unsigned int opChannel) const
  {
    unsigned int detectorNum = (unsigned int) opChannel / 12;
    return detectorNum;
  }

  //----------------------------------------------------------------------------
  unsigned int WireReadout35Geom::HardwareChannelFromOpChannel(unsigned int opChannel) const
  {
    unsigned int channel = opChannel % 12;
    return channel;
  }

  //----------------------------------------------------------------------------
  unsigned int WireReadout35Geom::NTPCsets
    (readout::CryostatID const& cryoid) const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::NTPCsets()
  
  
  //----------------------------------------------------------------------------
  unsigned int WireReadout35Geom::MaxTPCsets() const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::MaxTPCsets()
  
  
  //----------------------------------------------------------------------------
  bool WireReadout35Geom::HasTPCset(readout::TPCsetID const& tpcsetid) const
  {
    return tpcsetid.TPCset < NTPCsets(tpcsetid);
  } // WireReadout35Geom::HasTPCset()
  
  
  //----------------------------------------------------------------------------
  readout::TPCsetID WireReadout35Geom::TPCtoTPCset
    (geo::TPCID const& tpcid) const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::TPCtoTPCset()
  
  
  //----------------------------------------------------------------------------
  std::vector<geo::TPCID> WireReadout35Geom::TPCsetToTPCs
    (readout::TPCsetID const& tpcsetid) const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::TPCsetToTPCs()
  
  
  //----------------------------------------------------------------------------
  geo::TPCID WireReadout35Geom::FirstTPCinTPCset
    (readout::TPCsetID const& tpcsetid) const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::FirstTPCinTPCset()
  
  
  //----------------------------------------------------------------------------
  unsigned int WireReadout35Geom::NROPs
      (readout::TPCsetID const& tpcsetid) const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::NROPs()
  
  
  //----------------------------------------------------------------------------
  unsigned int WireReadout35Geom::MaxROPs() const {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::MaxROPs()
  
  
  //----------------------------------------------------------------------------
  bool WireReadout35Geom::HasROP(readout::ROPID const& ropid) const {
    return ropid.ROP < NROPs(ropid);
  } // WireReadout35Geom::HasROP()
  
  
  //----------------------------------------------------------------------------
  readout::ROPID WireReadout35Geom::WirePlaneToROP
    (geo::PlaneID const& planeid) const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::WirePlaneToROP()
  
  
  //----------------------------------------------------------------------------
  std::vector<geo::PlaneID> WireReadout35Geom::ROPtoWirePlanes
    (readout::ROPID const& ropid) const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::ROPtoWirePlanes()
  
  
  //----------------------------------------------------------------------------
  std::vector<geo::TPCID> WireReadout35Geom::ROPtoTPCs
    (readout::ROPID const& ropid) const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::ROPtoTPCs()
  
  
  //----------------------------------------------------------------------------
  readout::ROPID WireReadout35Geom::ChannelToROP
    (raw::ChannelID_t channel) const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::ROPtoTPCs()
  
  
  //----------------------------------------------------------------------------
  raw::ChannelID_t WireReadout35Geom::FirstChannelInROP
    (readout::ROPID const& ropid) const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::FirstChannelInROP()
  
  
  //----------------------------------------------------------------------------
  geo::PlaneID WireReadout35Geom::FirstWirePlaneInROP
    (readout::ROPID const& ropid) const
  {
    throw cet::exception("WireReadout35Geom") << __func__ << " not implemented!\n";
  } // WireReadout35Geom::FirstWirePlaneInROP()
  
  
} // namespace
