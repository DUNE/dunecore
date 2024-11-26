/*!
 * \file    CRPWireReadoutGeom.cxx
 * \brief   Channel mapping algorithms for vertical drift CRPs
 * \details Adapted from ICARUSWireReadoutGeom by G. Petrillo
 * \date    Oct 10, 2022
 * 
 *  vgalymov@ipnl.in2p3.fr
 */

// LArSoft libraries
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/WireReadoutGeomBuilderStandard.h"
#include "larcorealg/Geometry/GeometryCore.h"
#include "larcorealg/Geometry/GeometryCore.h"
#include "larcorealg/Geometry/TPCGeo.h"
#include "larcorealg/Geometry/PlaneGeo.h"
#include "larcorealg/Geometry/ReadoutDataContainers.h"
#include "larcorealg/Geometry/details/extractMaxGeometryElements.h"
#include "larcorealg/CoreUtils/enumerate.h"
#include "larcorealg/CoreUtils/counter.h"
#include "larcorealg/CoreUtils/DebugUtils.h" // lar::debug::printBacktrace()
#include "larcorealg/CoreUtils/StdUtils.h" // util::size()
#include "larcoreobj/SimpleTypesAndConstants/geo_vectors.h"

// framework libraries
#include "messagefacility/MessageLogger/MessageLogger.h"
#include "fhiclcpp/ParameterSet.h"
#include "cetlib_except/exception.h" // cet::exception

// C/C++ libraries
#include <vector>
#include <array>
#include <set>
#include <algorithm>  // std::transform(), std::find()
#include <utility>    // std::move()
#include <iterator>   // std::back_inserter()
#include <functional> // std::mem_fn()
#include <tuple>

#include "CRPWireReadoutGeom.h"
#include "GeoObjectSorterCRU60D.h"

using geo::dune::vd::crp::ChannelToWireMap;


namespace {
  
  constexpr double tolerance = 1.e-4;
  auto check_tolerance = [](double val) {
    return std::abs( val ) < tolerance;
  };

  typedef std::vector< const geo::TPCGeo* > TPCPtrVector_t;
  
  std::vector< TPCPtrVector_t > groupTPCsIntoSets( const geo::WireReadoutGeom& wireReadout,
                                                   const geo::CryostatGeo &cryo ){
    //
    // The implementation of this function to group volTPC objects into sets 
    // representing CRPs assumes the the following sorting scheme
    // TPC volumes are sorted:
    //   1) in drift coordinate
    //   2) within a given drift volume in z coordinate
    //   3) within a given z row in the other coordinate (x or y depending on the drift axis)
    // The function attemtps to detect the number of drift volumes present in 
    // the geometry by looking at a number of distinct values returned 
    // by TPCGeo::DetectDriftDirection()
    // Once the number of drift volumes or cells is found, it attemtps to to compute
    // the number of TPC volumes on the same z row (nz). Then the number of TPC volumes 
    // for the other coordinate is computed as no = ntpc / nz. With nz and no one then
    // attempts to map the indecies of TPCs into tpcsets representing an entire CRP
    //

    const std::string LogCategory = "groupTPCsIntoSets in CRPWireReadoutGeom";
    
    std::vector< TPCPtrVector_t > TPCsInSets;
    TPCPtrVector_t tpcs;
    unsigned int ntpc    = cryo.NTPC();
    unsigned int ncells  = 1U;  // number of drift volumes
    bool drift_direction_set{false};
    geo::Coordinate drift_axis{};
    geo::DriftSign drift_sign{};
    for (geo::TPCGeo const& tpc: cryo.IterateTPCs()) {
      tpcs.push_back( &tpc );
      auto const [axis, dasign] = tpc.DriftAxisWithSign();
      if( !drift_direction_set ) {
        drift_axis = axis;
	drift_sign = dasign;
	drift_direction_set = true;
	continue;
      }
      
      if( (axis != drift_axis || dasign != drift_sign) && ncells < 2U){
	ncells++;
      }
      drift_axis = axis;
      drift_sign = dasign;
      drift_direction_set = true;
    }

    mf::LogDebug log(LogCategory);
    
    log
      << "Number of drift cells in this geometry: "<<ncells<<"\n";
    
    // if only 4 TPC volumes they must belong to the same CRP
    // just return them (assumes they have been sorted correctly)
    // if( ntpc == 4U ){ 
    //   TPCsInSets.push_back( tpcs );
    //   return TPCsInSets;
    // }

    unsigned int ntpc_cell = ntpc / ncells;
    // now try to determine how many TPCs are on the same Z
    // this again assumes the GeoObjectSorterCRU60D
    // z is the second criteria for sorting

    unsigned int nz = 0U;
    auto begin = tpcs.begin();
    auto end   = begin + ntpc_cell;
    auto c0 = (*begin)->GetCenter();
    for(;begin!=end;++begin){
        auto c1 = (*begin)->GetCenter();
        if( check_tolerance(c0.Z() - c1.Z()) ){
	  nz++; // count also the first TPC
	}
	else {  
	  break; 
	}
    }    
    
    // other CRP coordinate 
    unsigned int no = ntpc / nz;
    if( nz % 2 != 0  || no % 2 != 0 ){
      throw cet::exception(LogCategory)
	<< "could not interpret the CRP geometry correctly\n";
    }
    
    log
      << "Number of TPCs per Z row: "<<nz<<"\n";
    
    //
    //    TPCsInSets
    for( unsigned int irow = 0U; irow < no; irow += 2 ){
      for( unsigned int icol = 0U; icol < nz; icol += 2 ){
	unsigned int idx0 = icol + irow * nz;
	unsigned int idx1 = idx0 + 1;
	unsigned int idx2 = icol + (irow + 1) * nz;
	unsigned int idx3 = idx2 + 1;
	log
	  <<"Set "<<TPCsInSets.size()<<" has TPCs at "<<idx0<<" "<<idx1<<" "<<idx2<<" "<<idx3<<"\n";
	if( idx0>=ntpc || idx1>=ntpc || idx2 >= ntpc || idx3 >= ntpc ){
	  throw cet::exception(LogCategory)
	    << "bad tpc idx for set ("<<idx0<<", "<<idx1<<", "<<idx2<<", "<<idx3<<")\n";
	}
		
	
	TPCsInSets.push_back( { tpcs[ idx0 ], tpcs[ idx1 ], tpcs[ idx2 ], tpcs[ idx3 ] } );
      }
    }
    
    if( TPCsInSets.size() != ntpc/4 ){
      throw cet::exception(LogCategory)
	<< "bad number of tpcsets\n";
    }
    
    return TPCsInSets;
  }

    //----------------------------------------------------------------------------
  bool compareWireDX(geo::WireGeo const& w1, geo::WireGeo const& w2)
  { // X is drift coordinate
    // wire sorting algorithm

    //  w1 geo info
    auto center1 = w1.GetCenter();
    auto start1  = w1.GetStart();
    auto end1    = w1.GetEnd();
    auto Delta   = end1-start1;
    //double dx1   = Delta.X();
    double dy1   = Delta.Y();
    double dz1   = Delta.Z();
    double thtz  = w1.ThetaZ();

    // w2 geo info
    auto center2 = w2.GetCenter();

    if( check_tolerance(dz1) ){ // wires perpendicular to z axis
      return center1.Z() < center2.Z();
    }

    if( check_tolerance(dy1) ){ // wires perpendicular to y axis
      return center1.Y() < center2.Y();
    }

    //cout<<"w1 " << w1.WireInfo("  ", 3)
    //<<" half length " << w1.HalfL()
    //<<" thetaZ = "<<thtz<<endl;

    // u-view
    if( thtz > 1.57 ) {

      // wires at angle with same z center
      if( check_tolerance( center2.Z() - center1.Z() ) ){
        if( dz1 < 0 ){ dy1 = -dy1; } // always compare here upstream - downstream ends
        if( dy1 < 0 ){ return center1.Y() < center2.Y(); }
        if( dy1 > 0 ){ return center1.Y() > center2.Y(); }
      }

      // otherwise sorted in z
      return center1.Z() < center2.Z();
    } // u view

      // v view
      // wires at angle with same z center
    if( check_tolerance( center2.Z() - center1.Z() ) ){
      if( dz1 < 0 ){ dy1 = -dy1; } // always compare here upstream - downstream ends
      if( dy1 < 0 ){ return center1.Y() > center2.Y(); }
      if( dy1 > 0 ){ return center1.Y() < center2.Y(); }
    }

    // otherwise sorted in -z
    return center1.Z() > center2.Z();
  }

  bool compareWireDY(geo::WireGeo const& w1, geo::WireGeo const& w2)
  { // Y is drift coordinate
    // wire sorting algorithm

    //  w1 geo info
    auto center1 = w1.GetCenter();
    auto start1  = w1.GetStart();
    auto end1    = w1.GetEnd();
    auto Delta   = end1-start1;
    double dx1   = Delta.X();
    double dz1   = Delta.Z();
    double thtz  = w1.ThetaZ();

    // w2 geo info
    auto center2 = w2.GetCenter();

    if( check_tolerance(dz1) ){ // wires perpendicular to z axis
      return center1.Z() < center2.Z();
    }

    if( check_tolerance(dx1) ){ // wires perpendicular to x axis
      return center1.X() < center2.X();
    }

    //cout<<"w1 " << w1.WireInfo("  ", 3)
    //<<" half length " << w1.HalfL()
    //<<" thetaZ = "<<thtz<<endl;

    // u-view
    if( thtz > 1.57 ) {

      // wires at angle with same z center
      if( check_tolerance( center2.Z() - center1.Z() ) ){
        if( dz1 < 0 ){ dx1 = -dx1; } // always compare here upstream - downstream ends
        if( dx1 < 0 ){ return center1.X() < center2.X(); }
        if( dx1 > 0 ){ return center1.X() > center2.X(); }
      }

      // otherwise sorted in z
      return center1.Z() < center2.Z();
    } // u view

      // v view
      // wires at angle with same z center
    if( check_tolerance( center2.Z() - center1.Z() ) ){
      if( dz1 < 0 ){ dx1 = -dx1; } // always compare here upstream - downstream ends
      if( dx1 < 0 ){ return center1.X() > center2.X(); }
      if( dx1 > 0 ){ return center1.X() < center2.X(); }
    }

    // otherwise sorted in -z
    return center1.Z() > center2.Z();
  }

  class CRPWireReadoutSorter : public geo::WireReadoutSorter {
  public:
    explicit CRPWireReadoutSorter(geo::GeometryCore const* geom)
      : fDriftCoordinate{geom->TPC().DriftAxisWithSign().coordinate} // Use first available TPC
    {}

  private:
    bool compareWires(geo::WireGeo const& w1, geo::WireGeo const& w2) const override
    {
      if (fDriftCoordinate == geo::Coordinate::Y) return compareWireDY(w1, w2);
      return compareWireDX(w1, w2);
    }

    geo::Coordinate fDriftCoordinate;
  };
}


// -----------------------------------------------------------------------------
geo::CRPWireReadoutGeom::CRPWireReadoutGeom(fhicl::ParameterSet const& p,
                                            GeometryCore const* geom)
  : WireReadoutGeom{geom,
                    std::make_unique<geo::WireReadoutGeomBuilderStandard>(
                        p.get<fhicl::ParameterSet>("Builder", {})),
                    std::make_unique<CRPWireReadoutSorter>(geom)}
{
  mf::LogInfo(fLogCategory)
    << "Initializing CRPWireReadoutGeom channel mapping algorithm.";
  
  buildReadoutPlanes(geom->Cryostats());
  fillChannelToWireMap(geom->Cryostats());
  
  MF_LOG_TRACE(fLogCategory)
    << "CRPWireReadoutGeom::Initialize() completed.";
}


//------------------------------------------------------------------------------
std::vector<geo::WireID> geo::CRPWireReadoutGeom::ChannelToWire
  (raw::ChannelID_t channel) const
{
  //
  // input check
  //
  assert(!fPlaneInfo.empty());
  
  //
  // output
  //
  std::vector<geo::WireID> AllSegments;
  
  //
  // find the ROP with that channel
  //
  ChannelToWireMap::ChannelsInROPStruct const* channelInfo
    = fChannelToWireMap.find(channel);
  if (!channelInfo) {
    throw cet::exception(fLogCategory)
      << "geo::CRPWireReadoutGeom::ChannelToWire(" << channel
      << "): invalid channel requested (must be lower than "
      << Nchannels() << ")\n";
  }
  
  //
  // find the wire planes in that ROP
  //
  PlaneColl_t const& planes = ROPplanes(channelInfo->ropid);
  
  //
  // associate one wire for each of those wire planes to the channel
  //
  AllSegments.reserve(planes.size()); // this is sometimes (often?) too much
  for (auto const pid: planes) {
    
    //geo::PlaneID const& pid = plane->ID();
    ChannelRange_t const& channelRange = fPlaneInfo[pid].channelRange();
    
    if (!channelRange.contains(channel)) continue;
    AllSegments.emplace_back
      (pid, static_cast<geo::WireID::WireID_t>(channel - channelRange.begin()));
    
  } // for planes in ROP
  
  return AllSegments;
  
} // geo::CRPWireReadoutGeom::ChannelToWire()


//------------------------------------------------------------------------------
unsigned int geo::CRPWireReadoutGeom::Nchannels() const {
  
  return fChannelToWireMap.nChannels();
} // geo::CRPWireReadoutGeom::Nchannels()


//------------------------------------------------------------------------------
unsigned int geo::CRPWireReadoutGeom::Nchannels
  (readout::ROPID const& ropid) const 
{
  ChannelToWireMap::ChannelsInROPStruct const* ROPinfo
    = fChannelToWireMap.find(ropid);
  return ROPinfo? ROPinfo->nChannels: 0U;
} // geo::CRPWireReadoutGeom::Nchannels(ROPID)


//------------------------------------------------------------------------------
double geo::CRPWireReadoutGeom::WireCoordinate
  (double YPos, double ZPos, geo::PlaneID const& planeID) const
{
  /*
   * this should NOT be called... it shouldn't be here at all!
   */
  
  cet::exception e(fLogCategory);
  e << "CRPWireReadoutGeom does not support `WireCoordinate()` call."
    "\nPlease update calling software to use geo::PlaneGeo::WireCoordinate()`:"
    "\n";
  
  //lar::debug::printBacktrace(e, 4U);
  
  throw e;
} // geo::CRPWireReadoutGeom::WireCoordinate()


//------------------------------------------------------------------------------
geo::WireID geo::CRPWireReadoutGeom::NearestWireID
  (const geo::Point_t&  worldPos, geo::PlaneID const& planeID) const
{
  /*
   * this should NOT be called... it shouldn't be here at all!
   */
  
  cet::exception e(fLogCategory);
  e << "CRPWireReadoutGeom does not support `NearestWireID()` call."
    "\nPlease update calling software to use geo::PlaneGeo::NearestWireID()`:"
    "\n";
  
  //lar::debug::printBacktrace(e, 3U);
  
  throw e;
} // geo::CRPWireReadoutGeom::NearestWireID()


//------------------------------------------------------------------------------
raw::ChannelID_t geo::CRPWireReadoutGeom::PlaneWireToChannel
  (geo::WireID const& wireID) const
{
  return fPlaneInfo[wireID].firstChannel() + wireID.Wire;
} // geo::CRPWireReadoutGeom::PlaneWireToChannel()


//------------------------------------------------------------------------------
std::set<geo::PlaneID> const& geo::CRPWireReadoutGeom::PlaneIDs() const {
  
  /*
   * this should NOT be called... it shouldn't be here at all!
   */
  
  cet::exception e(fLogCategory);
  e << "CRPWireReadoutGeom does not support `PlaneIDs()` call."
    "\nPlease update calling software to use geo::GeometryCore::IteratePlanes()`"
    "\n";
  
  //lar::debug::printBacktrace(e, 3U);
  
  throw e;
  
} // geo::CRPWireReadoutGeom::PlaneIDs()


//------------------------------------------------------------------------------
unsigned int geo::CRPWireReadoutGeom::NTPCsets
  (readout::CryostatID const& cryoid) const
{
  return HasCryostat(cryoid)? TPCsetCount(cryoid): 0U;
} // geo::CRPWireReadoutGeom::NTPCsets()


//------------------------------------------------------------------------------
/// Returns the largest number of TPC sets any cryostat in the detector has
unsigned int geo::CRPWireReadoutGeom::MaxTPCsets() const {
  assert(fReadoutMapInfo);
  return fReadoutMapInfo.MaxTPCsets();
} // geo::CRPWireReadoutGeom::MaxTPCsets()


//------------------------------------------------------------------------------
/// Returns whether we have the specified TPC set
/// @return whether the TPC set is valid and exists
bool geo::CRPWireReadoutGeom::HasTPCset
  (readout::TPCsetID const& tpcsetid) const
{
  return
    HasCryostat(tpcsetid)? (tpcsetid.TPCset < TPCsetCount(tpcsetid)): false;
} // geo::CRPWireReadoutGeom::HasTPCset()


//------------------------------------------------------------------------------
readout::TPCsetID geo::CRPWireReadoutGeom::TPCtoTPCset
  (geo::TPCID const& tpcid) const
{
  return tpcid? TPCtoTPCset()[tpcid]: readout::TPCsetID{};
} // geo::CRPWireReadoutGeom::TPCtoTPCset()


//------------------------------------------------------------------------------
std::vector<geo::TPCID> geo::CRPWireReadoutGeom::TPCsetToTPCs
  (readout::TPCsetID const& tpcsetid) const
{
  std::vector<geo::TPCID> TPCs;
  if (!tpcsetid) return TPCs;
  
  return TPCsetTPCs(tpcsetid);
} // geo::CRPWireReadoutGeom::TPCsetToTPCs()


//------------------------------------------------------------------------------
geo::TPCID geo::CRPWireReadoutGeom::FirstTPCinTPCset
  (readout::TPCsetID const& tpcsetid) const
{
  if (!tpcsetid) return {};
  
  auto const& TPClist = TPCsetTPCs(tpcsetid);
  return TPClist.empty()? geo::TPCID{}: TPClist.front();
  
} // geo::CRPWireReadoutGeom::FirstTPCinTPCset()


//------------------------------------------------------------------------------
unsigned int geo::CRPWireReadoutGeom::NROPs
  (readout::TPCsetID const& tpcsetid) const
{
  return HasTPCset(tpcsetid)? ROPcount(tpcsetid): 0U;
} // geo::CRPWireReadoutGeom::NROPs()


//------------------------------------------------------------------------------
unsigned int geo::CRPWireReadoutGeom::MaxROPs() const {
  assert(fReadoutMapInfo);
  return fReadoutMapInfo.MaxROPs();
} // geo::CRPWireReadoutGeom::MaxROPs()

//------------------------------------------------------------------------------
bool geo::CRPWireReadoutGeom::HasROP(readout::ROPID const& ropid) const {
  return HasTPCset(ropid)? (ropid.ROP < ROPcount(ropid)): false;
} // geo::CRPWireReadoutGeom::HasROP()


//------------------------------------------------------------------------------
  /**
   * @brief Returns the ID of the ROP planeid belongs to, or invalid if none
   * @param planeid ID of the plane
   * @return the ID of the corresponding ROP, or invalid ID when planeid is
   *
   * In this mapping, readout planes and wire planes are mapped one-to-one.
   * The returned value mirrors the plane ID in the readout space.
   * If the plane ID is not valid, an invalid readout plane ID is returned.
   * Note that this check is performed on the validity of the plane ID, that
   * does not necessarily imply that the plane specified by the ID actually
   * exists.
   */
readout::ROPID geo::CRPWireReadoutGeom::WirePlaneToROP
  (geo::PlaneID const& planeid) const
{
  return planeid? PlaneToROP(planeid): readout::ROPID{};
  //return planeid?fReadoutMapInfo.fPlaneToROP[planeid]:readout::ROPID{};
} // geo::CRPWireReadoutGeom::WirePlaneToROP()


//------------------------------------------------------------------------------
std::vector<geo::PlaneID> geo::CRPWireReadoutGeom::ROPtoWirePlanes
  (readout::ROPID const& ropid) const
{
  std::vector<geo::PlaneID> Planes;
  if (!ropid) return Planes;
  return ROPplanes(ropid);
} // geo::CRPWireReadoutGeom::ROPtoWirePlanes()


//------------------------------------------------------------------------------
std::vector<geo::TPCID> geo::CRPWireReadoutGeom::ROPtoTPCs
  (readout::ROPID const& ropid) const
{
  std::vector<geo::TPCID> TPCs;
  if (!ropid) return TPCs;
  
  auto const& PlaneList = ROPplanes(ropid);
  TPCs.reserve(PlaneList.size());
  for( auto const pid : PlaneList ){
    TPCs.push_back( pid );
  }

  return TPCs;
} // geo::CRPWireReadoutGeom::ROPtoTPCs()


//------------------------------------------------------------------------------
readout::ROPID geo::CRPWireReadoutGeom::ChannelToROP
  (raw::ChannelID_t channel) const
{
  if (!raw::isValidChannelID(channel)) return {};
  
  ChannelToWireMap::ChannelsInROPStruct const* info
    = fChannelToWireMap.find(channel);
  return info? info->ropid: readout::ROPID{};
} // geo::CRPWireReadoutGeom::ChannelToROP()


//------------------------------------------------------------------------------
raw::ChannelID_t geo::CRPWireReadoutGeom::FirstChannelInROP
  (readout::ROPID const& ropid) const
{
  if (!ropid) return raw::InvalidChannelID;
  
  ChannelToWireMap::ChannelsInROPStruct const* info
    = fChannelToWireMap.find(ropid);
  return info? info->firstChannel: raw::InvalidChannelID;
} // geo::CRPWireReadoutGeom::FirstChannelInROP()


//------------------------------------------------------------------------------
geo::PlaneID geo::CRPWireReadoutGeom::FirstWirePlaneInROP
  (readout::ROPID const& ropid) const
{
  if (!ropid) return {};
  PlaneColl_t const& planes = ROPplanes(ropid);
  return planes.empty()? geo::PlaneID{}: planes.front();
} // geo::CRPWireReadoutGeom::FirstWirePlaneInROP()


//------------------------------------------------------------------------------
bool geo::CRPWireReadoutGeom::HasCryostat
  (readout::CryostatID const& cryoid) const
{
  assert(fReadoutMapInfo);
  return cryoid.Cryostat < fReadoutMapInfo.NCryostats();
} // geo::CRPWireReadoutGeom::HasCryostat()


//------------------------------------------------------------------------------
void geo::CRPWireReadoutGeom::fillChannelToWireMap
  (std::vector<geo::CryostatGeo> const& Cryostats)
{
  
  //
  // input check
  //
  assert(fReadoutMapInfo);
  assert(!Cryostats.empty());
  
  //
  // output setup
  //
  assert(fPlaneInfo.empty());
  std::array<unsigned int, 3U> maxSizes
    = geo::details::extractMaxGeometryElements<3U>(Cryostats, *this);
 
  fPlaneInfo.resize(maxSizes[0U], maxSizes[1U], maxSizes[2U]);
  
  raw::ChannelID_t nextChannel = 0; // next available channel
  for (geo::CryostatGeo const& cryo: Cryostats) {
    
    readout::CryostatID const cid { cryo.ID() };
    
    auto const nTPCsets 
      = static_cast<readout::TPCsetID::TPCsetID_t>(TPCsetCount(cid));

    for (readout::TPCsetID::TPCsetID_t s: util::counter(nTPCsets)) {
      
      readout::TPCsetID const sid { cid, s };
      auto const nROPs = static_cast<readout::ROPID::ROPID_t>(ROPcount(sid));

      for (readout::ROPID::ROPID_t r: util::counter(nROPs)) {
        
        mf::LogTrace log(fLogCategory);
	//mf::LogInfo log(fLogCategory);
        
        readout::ROPID const rid { sid, r };
        auto const planeType = findPlaneType(rid);
        log << "ROP: " << rid
          << " (plane type: " << PlaneTypeName(planeType) << ")";

        PlaneColl_t const& plane_ids = ROPplanes(rid);
	assert(!plane_ids.empty());
        log << " (" << plane_ids.size() << " planes):";
	
	std::vector<geo::PlaneGeo const*> planes;
	planes.reserve( plane_ids.size() );
	for( auto const pid : plane_ids ){
          planes.push_back( PlanePtr( pid ) );
	}
        
        raw::ChannelID_t const firstROPchannel = nextChannel;
	
	// iterate over all the geo planes assigend to this ROP
        geo::Point_t lastWirePos = (*planes.begin())->LastWire().GetCenter();
	for( auto plane_it = planes.begin(); 
	     plane_it != planes.end();
	     plane_it++ ){
	  
	  //
          geo::PlaneGeo const& plane = **plane_it;

	  // first channel for a given plane
	  raw::ChannelID_t firstChannel = nextChannel;

	  if( r > 1 ){ // collection ROP
	    // simply add offset
	    nextChannel += plane.Nwires();
	  }
	  else { // induction ROPs

	    // assumed the geoplane pairing in CRU: 0 with 1, 2 with 3
	    auto plane_idx = std::distance(planes.begin(), plane_it);

	    // assign all wires to channels from the first plane in the pair
	    if( plane_idx % 2 == 0 ){ 
	      //raw::ChannelID_t const firstChannel = nextChannel;
	      nextChannel += plane.Nwires();
	    }
	    else {
	      // find the wire which matches the last one 
	      // from the previous plane of this CRU
	      geo::WireID const lastMatchedWireID
		= plane.NearestWireID(lastWirePos);
	      
	      // first channel for this plane
	      firstChannel = (nextChannel - 1) - lastMatchedWireID.Wire;
	      
	      // add nwires
	      nextChannel  = firstChannel + plane.Nwires();
	    }
	  }// else if induction ROPs
	  
	  fPlaneInfo[plane.ID()] = { { firstChannel, nextChannel }, rid };
          log << " [" << plane.ID() << "] "
	      << fPlaneInfo[plane.ID()].firstChannel() << " -- "
	      << fPlaneInfo[plane.ID()].lastChannel() << ";";
          
          // update for the next iteration
          lastWirePos = plane.LastWire().GetCenter();
	} // for loop over geo planes belonging to a ROP
	
	unsigned int const nChannels = nextChannel - firstROPchannel;
        fChannelToWireMap.addROP(rid, firstROPchannel, nChannels);
        log
          << " => " << nChannels << " channels starting at " << firstROPchannel;
        
      } // for readout plane
      
    } // for TPC set
    
  } // for cryostat
  
  fChannelToWireMap.setEndChannel(nextChannel);
  mf::LogInfo(fLogCategory)
    << "Counted " << fChannelToWireMap.nChannels() << " channels.";
  
} // geo::CRPWireReadoutGeom::fillChannelToWireMap()


// -----------------------------------------------------------------------------
void geo::CRPWireReadoutGeom::buildReadoutPlanes
  (std::vector<geo::CryostatGeo> const& Cryostats)
{
  auto const [ NCryostats, MaxTPCs, MaxPlanes ]
    = geo::details::extractMaxGeometryElements<3U>(Cryostats, *this);
  
  mf::LogInfo(fLogCategory)
    << "Build readout planes for "<<NCryostats<<" "<<MaxTPCs<<" "<<MaxPlanes;

  if( Cryostats.size() > 1 ){
    throw cet::exception(fLogCategory)
      << "geo::CRPWireReadoutGeom::buildReadoutPlanes " << Cryostats.size()
      << ": more than one cryostat is currently not supported\n";
  }
  
  if( Cryostats[0].NTPC() %4 != 0 ){
    throw cet::exception(fLogCategory)
      << "geo::CRPWireReadoutGeom::buildReadoutPlanes " << Cryostats[0].NTPC()
      << ": non-four-module TPCs is not supported\n";
  }
  
  //
  auto cryo = Cryostats[0];
  unsigned int MaxROPs    = 3;
  unsigned int MaxTPCsets = MaxTPCs/4; // 
  std::vector<unsigned int> TPCsetCount = {MaxTPCsets};
  
  // TPCs belonging to a set
  std::vector<std::vector<const geo::TPCGeo*>> AllTPCsInTPCsets = groupTPCsIntoSets(*this, cryo);
  if( AllTPCsInTPCsets.size() != MaxTPCsets ){
    throw cet::exception(fLogCategory)
      << "geo::CRPWireReadoutGeom::buildReadoutPlanes number of TPCsets in invalid\n";
  }    

  readout::TPCsetDataContainer<TPCColl_t> TPCsetTPCs(NCryostats, MaxTPCsets);
  
  for( auto&& [s, TPClist ]: util::enumerate(AllTPCsInTPCsets) ){
    readout::TPCsetID const tpcsetid
    { cryo.ID(), static_cast<readout::TPCsetID::TPCsetID_t>(s) };
    //mf::LogInfo("CRPWireReadoutGeom")<< tpcsetid <<" "<<TPCPtrs.size()<<"\n";
    std::vector<geo::TPCID> TPCs;
    TPCs.reserve(TPClist.size());
    std::transform(TPClist.begin(), TPClist.end(), std::back_inserter(TPCs),
		   std::mem_fn(&geo::TPCGeo::ID));

    TPCsetTPCs[tpcsetid] = std::move(TPCs);
  }

  //  number of readout planes in each TPC set
  readout::TPCsetDataContainer<unsigned int> ROPcount;
  ROPcount.resize( TPCsetTPCs.dimSize<0U>(), TPCsetTPCs.dimSize<1U>(), 0U );
  
  // geo::PlaneGeo objects in each readout plane
  readout::ROPDataContainer<PlaneColl_t> ROPplanes;
  ROPplanes.resize(TPCsetTPCs.dimSize<0U>(), TPCsetTPCs.dimSize<1U>(), MaxROPs);

  for (auto [ c, nTPCsets ]: util::enumerate(TPCsetCount)) {
    readout::CryostatID const cryoid
    { static_cast<readout::CryostatID::CryostatID_t>(c) };
    for (readout::TPCsetID::TPCsetID_t s = 0; s < nTPCsets; ++s) {
      readout::TPCsetID const tpcsetid { cryoid, s };
      unsigned int nROP  = MaxROPs;
      ROPcount[tpcsetid] = nROP;

      auto TPCs = AllTPCsInTPCsets[s];
      for( unsigned r = 0; r<nROP;++r ){ // assuming the number of rops == number of planes per TPC
	// get PlaneColl_t for each set for each plane
	PlaneColl_t planes;
	
	for ( const geo::TPCGeo* TPC: TPCs){ 
          planes.push_back({TPC->ID(), r});
	}
	readout::ROPID const ropid { tpcsetid, r };
	mf::LogTrace log(fLogCategory);
	log << "Readout plane " << ropid << " assigned with " << planes.size()
            << " planes:";
	for (auto const plane: planes)
	  log << "  (" << plane << ")";
	
        if(!ROPplanes[ropid].empty()) {
          //
          // If this happens, it may be that the geometry is not compatible
          // with the algorithm, or just a bug.
          // Enabling the debug stream will show which planes are assigned
          // each time, including the two conflicting assignments.
          //
          throw cet::exception(fLogCategory)
            << "Logic error: ROPID " << ropid
            << " has already been assigned!\n";
        }
	
	ROPplanes[ ropid ] = std::move( planes );
      } // ROPs/ planes
    } // tpcs in tpcset
  }//cryo, TPCSets
      
  //
  // the TPC set each TPC belongs to 
  geo::TPCDataContainer<readout::TPCsetID> TPCtoTPCset;
  TPCtoTPCset.resize( NCryostats, MaxTPCs, {});
  for (auto c
	 : util::counter<geo::CryostatID::CryostatID_t>(TPCsetTPCs.dimSize<0>())){
    
    geo::CryostatID const cid { c };
    for (auto s: util::counter<readout::TPCsetID::TPCsetID_t>(TPCsetTPCs.dimSize<1>()))
      {
	readout::TPCsetID const sid { cid, s };
      	for (auto const TPCid: TPCsetTPCs[sid]) {
	  TPCtoTPCset[TPCid] = sid;
	  MF_LOG_TRACE(fLogCategory) << TPCid << " => " << sid;
	} // for TPCs in TPC set
      } // for TPC sets in cryostat
  } // for cryostats
  
  // ROP each wire belongs to
  geo::PlaneDataContainer<readout::ROPID> PlaneToROP;
  PlaneToROP.resize( NCryostats, MaxTPCs, MaxPlanes, {} );
  for (auto c
    : util::counter<geo::CryostatID::CryostatID_t>(ROPplanes.dimSize<0>())
       )
    {
      geo::CryostatID const cid { c };
      for (auto s: util::counter<readout::TPCsetID::TPCsetID_t>(ROPplanes.dimSize<1>()))
	{
	  readout::TPCsetID const sid { cid, s };
	  for (auto r: util::counter<readout::ROPID::ROPID_t>(ROPplanes.dimSize<2>()))
	    {
	      readout::ROPID const rid { sid, r };
	      for (auto const plane: ROPplanes[rid]) {
		//assert(plane && plane->ID());
		PlaneToROP[plane] = rid;
		MF_LOG_TRACE(fLogCategory) << plane << " => " << rid;
	      } // for planes in readout plane
	    } // for readout planes in TPC set
	} // for TPC sets in cryostat
    } // for cryostats
  
  // copy to ReadoutMapInfo struct
  fReadoutMapInfo.set(
   		      std::move(TPCsetCount), std::move(TPCsetTPCs),
   		      std::move(ROPcount), std::move(ROPplanes),
   		      std::move(TPCtoTPCset), std::move(PlaneToROP)
   		      );
} // geo::CRPWireReadoutGeom::buildReadoutPlanes()


// -----------------------------------------------------------------------------
std::size_t geo::CRPWireReadoutGeom::findPlaneType(readout::ROPID const& rid) const
{
  /*
   * This implementation is very fragile, relying on the fact that the first
   * induction plane numbers are `kFirstInductionType`, the second induction
   * plane numbers are `kSecondInductionType` and the collection plane numbers
   * are `kCollectionType`. This assumption is not checked anywhere.
   * 
   */
  constexpr std::array PlaneTypes = { // let's C++ figure out type and size
    kFirstInductionType,  // P:0
    kSecondInductionType, // P:1
    kCollectionType       // P:2
  };
  
  PlaneColl_t const& planes = ROPplanes(rid);
  //std::cout<<"findPlaneType: "<<rid<<" "<<planes.size()<<" @ "<<planes.front()
  //<<" "<<planes.front()->ID().Plane<<"\n";
  //for (geo::PlaneGeo const* plane: planes)
  //std::cout <<" (" << plane->ID() << ")";
  //std::cout<<"\n";

  if (planes.empty()) return kUnknownType;
  if (auto const planeNo = planes.front().Plane; planeNo < PlaneTypes.size())
    return PlaneTypes[planeNo];
  else return kUnknownType;
  
} // geo::CRPWireReadoutGeom::findPlaneType()


// ----------------------------------------------------------------------------
geo::SigType_t geo::CRPWireReadoutGeom::SignalTypeForChannelImpl
  (raw::ChannelID_t const channel) const
{
  ChannelToWireMap::ChannelsInROPStruct const* channelInfo
    = fChannelToWireMap.find(channel);
  if (!channelInfo) return geo::kMysteryType;
  
  switch (findPlaneType(channelInfo->ropid)) {
    case kFirstInductionType:
    case kSecondInductionType:
      return geo::kInduction;
    case kCollectionType:
      return geo::kCollection;
    default:
      return geo::kMysteryType;
  } // switch
  
  return geo::kMysteryType;
} // geo::CRPWireReadoutGeom::SignalTypeForChannelImpl()


// ----------------------------------------------------------------------------
std::string geo::CRPWireReadoutGeom::PlaneTypeName(PlaneType_t planeType) {
  
  using namespace std::string_literals;
  switch (planeType) {
    case kFirstInductionType:  return "first induction"s;
    case kSecondInductionType: return "second induction"s;
    case kCollectionType:      return "collection induction"s;
    case kUnknownType:         return "unknown"s;
    default:
      return "unsupported ("s + std::to_string(planeType) + ")"s;
  } // switch
  
} // geo::CRPWireReadoutGeom::PlaneTypeName()


// ----------------------------------------------------------------------------
