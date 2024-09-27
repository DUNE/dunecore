/*!
 * \file    ColdBoxWireReadoutGeom.h
 * \brief   Channel mapping algorithms for VD ColdBox CRP.
 * \details Adapted from ICARUSWireReadoutGeom by G. Petrillo
 * \date    October 25, 2021
 * \warning Only one CRP is currently supported with 48 deg ind1
 *
 *  vgalymov@ipnl.in2p3.fr
 */


// LArSoft libraries
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/GeometryCore.h"
#include "larcorealg/Geometry/WireReadoutGeomBuilderStandard.h"
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

#include "dunecore/Geometry/ColdBoxWireReadoutGeom.h"
#include "dunecore/Geometry/WireReadoutSorterCRU.h"

using geo::dune::vd::ChannelToWireMap;

// -----------------------------------------------------------------------------
geo::ColdBoxWireReadoutGeom::ColdBoxWireReadoutGeom(fhicl::ParameterSet const& p, GeometryCore const* geom)
  : WireReadoutGeom{geom,
                    std::make_unique<WireReadoutGeomBuilderStandard>(
                      p.get<fhicl::ParameterSet>("Builder", {})),
                    std::make_unique<WireReadoutSorterCRU>()}
{
  mf::LogInfo("ColdBoxWireReadoutGeom")
    << "Initializing ColdBoxWireReadoutGeom channel mapping algorithm.";
  
  buildReadoutPlanes(geom->Cryostats());
  fillChannelToWireMap(geom->Cryostats());
  
  MF_LOG_TRACE("ColdBoxWireReadoutGeom")
    << "ColdBoxWireReadoutGeom::Initialize() completed.";
} // geo::ColdBoxWireReadoutGeom::Initialize()


//------------------------------------------------------------------------------
std::vector<geo::WireID> geo::ColdBoxWireReadoutGeom::ChannelToWire
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
    throw cet::exception("Geometry")
      << "geo::ColdBoxWireReadoutGeom::ChannelToWire(" << channel
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
  
} // geo::ColdBoxWireReadoutGeom::ChannelToWire()


//------------------------------------------------------------------------------
unsigned int geo::ColdBoxWireReadoutGeom::Nchannels() const {
  
  return fChannelToWireMap.nChannels();
} // geo::ColdBoxWireReadoutGeom::Nchannels()


//------------------------------------------------------------------------------
unsigned int geo::ColdBoxWireReadoutGeom::Nchannels
  (readout::ROPID const& ropid) const 
{
  ChannelToWireMap::ChannelsInROPStruct const* ROPinfo
    = fChannelToWireMap.find(ropid);
  return ROPinfo? ROPinfo->nChannels: 0U;
} // geo::ColdBoxWireReadoutGeom::Nchannels(ROPID)


//------------------------------------------------------------------------------
double geo::ColdBoxWireReadoutGeom::WireCoordinate
  (double YPos, double ZPos, geo::PlaneID const& planeID) const
{
  /*
   * this should NOT be called... it shouldn't be here at all!
   */
  
  cet::exception e("ColdBoxWireReadoutGeom");
  e << "ColdBoxWireReadoutGeom does not support `WireCoordinate()` call."
    "\nPlease update calling software to use geo::PlaneGeo::WireCoordinate()`:"
    "\n";
  
  //lar::debug::printBacktrace(e, 4U);
  
  throw e;
} // geo::ColdBoxWireReadoutGeom::WireCoordinate()


//------------------------------------------------------------------------------
geo::WireID geo::ColdBoxWireReadoutGeom::NearestWireID
  (const geo::Point_t& worldPos, geo::PlaneID const& planeID) const
{
  /*
   * this should NOT be called... it shouldn't be here at all!
   */
  
  cet::exception e("ColdBoxWireReadoutGeom");
  e << "ColdBoxWireReadoutGeom does not support `NearestWireID()` call."
    "\nPlease update calling software to use geo::PlaneGeo::NearestWireID()`:"
    "\n";
  
  //lar::debug::printBacktrace(e, 3U);
  
  throw e;
} // geo::ColdBoxWireReadoutGeom::NearestWireID()


//------------------------------------------------------------------------------
raw::ChannelID_t geo::ColdBoxWireReadoutGeom::PlaneWireToChannel
  (geo::WireID const& wireID) const
{
  return fPlaneInfo[wireID].firstChannel() + wireID.Wire;
} // geo::ColdBoxWireReadoutGeom::PlaneWireToChannel()


//------------------------------------------------------------------------------
std::set<geo::PlaneID> const& geo::ColdBoxWireReadoutGeom::PlaneIDs() const {
  
  /*
   * this should NOT be called... it shouldn't be here at all!
   */
  
  cet::exception e("ColdBoxWireReadoutGeom");
  e << "ColdBoxWireReadoutGeom does not support `PlaneIDs()` call."
    "\nPlease update calling software to use geo::GeometryCore::IteratePlanes()`"
    "\n";
  
  //lar::debug::printBacktrace(e, 3U);
  
  throw e;
  
} // geo::ColdBoxWireReadoutGeom::PlaneIDs()


//------------------------------------------------------------------------------
unsigned int geo::ColdBoxWireReadoutGeom::NTPCsets
  (readout::CryostatID const& cryoid) const
{
  return HasCryostat(cryoid)? TPCsetCount(cryoid): 0U;
} // geo::ColdBoxWireReadoutGeom::NTPCsets()


//------------------------------------------------------------------------------
/// Returns the largest number of TPC sets any cryostat in the detector has
unsigned int geo::ColdBoxWireReadoutGeom::MaxTPCsets() const {
  assert(fReadoutMapInfo);
  return fReadoutMapInfo.MaxTPCsets();
} // geo::ColdBoxWireReadoutGeom::MaxTPCsets()


//------------------------------------------------------------------------------
/// Returns whether we have the specified TPC set
/// @return whether the TPC set is valid and exists
bool geo::ColdBoxWireReadoutGeom::HasTPCset
  (readout::TPCsetID const& tpcsetid) const
{
  return
    HasCryostat(tpcsetid)? (tpcsetid.TPCset < TPCsetCount(tpcsetid)): false;
} // geo::ColdBoxWireReadoutGeom::HasTPCset()


//------------------------------------------------------------------------------
readout::TPCsetID geo::ColdBoxWireReadoutGeom::TPCtoTPCset
  (geo::TPCID const& tpcid) const
{
  return tpcid? TPCtoTPCset()[tpcid]: readout::TPCsetID{};
} // geo::ColdBoxWireReadoutGeom::TPCtoTPCset()


//------------------------------------------------------------------------------
std::vector<geo::TPCID> geo::ColdBoxWireReadoutGeom::TPCsetToTPCs
  (readout::TPCsetID const& tpcsetid) const
{
  std::vector<geo::TPCID> TPCs;
  if (!tpcsetid) return TPCs;
  
  return TPCsetTPCs(tpcsetid);
} // geo::ColdBoxWireReadoutGeom::TPCsetToTPCs()


//------------------------------------------------------------------------------
geo::TPCID geo::ColdBoxWireReadoutGeom::FirstTPCinTPCset
  (readout::TPCsetID const& tpcsetid) const
{
  if (!tpcsetid) return {};
  
  auto const& TPClist = TPCsetTPCs(tpcsetid);
  return TPClist.empty()? geo::TPCID{}: TPClist.front();
  
} // geo::ColdBoxWireReadoutGeom::FirstTPCinTPCset()


//------------------------------------------------------------------------------
unsigned int geo::ColdBoxWireReadoutGeom::NROPs
  (readout::TPCsetID const& tpcsetid) const
{
  return HasTPCset(tpcsetid)? ROPcount(tpcsetid): 0U;
} // geo::ColdBoxWireReadoutGeom::NROPs()


//------------------------------------------------------------------------------
unsigned int geo::ColdBoxWireReadoutGeom::MaxROPs() const {
  assert(fReadoutMapInfo);
  return fReadoutMapInfo.MaxROPs();
} // geo::ColdBoxWireReadoutGeom::MaxROPs()

//------------------------------------------------------------------------------
bool geo::ColdBoxWireReadoutGeom::HasROP(readout::ROPID const& ropid) const {
  return HasTPCset(ropid)? (ropid.ROP < ROPcount(ropid)): false;
} // geo::ColdBoxWireReadoutGeom::HasROP()


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
readout::ROPID geo::ColdBoxWireReadoutGeom::WirePlaneToROP
  (geo::PlaneID const& planeid) const
{
  return planeid? PlaneToROP(planeid): readout::ROPID{};
  //return planeid?fReadoutMapInfo.fPlaneToROP[planeid]:readout::ROPID{};
} // geo::ColdBoxWireReadoutGeom::WirePlaneToROP()


//------------------------------------------------------------------------------
std::vector<geo::PlaneID> geo::ColdBoxWireReadoutGeom::ROPtoWirePlanes
  (readout::ROPID const& ropid) const
{
  std::vector<geo::PlaneID> Planes;
  if (!ropid) return Planes;
  return ROPplanes(ropid);
} // geo::ColdBoxWireReadoutGeom::ROPtoWirePlanes()


//------------------------------------------------------------------------------
std::vector<geo::TPCID> geo::ColdBoxWireReadoutGeom::ROPtoTPCs
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
} // geo::ColdBoxWireReadoutGeom::ROPtoTPCs()


//------------------------------------------------------------------------------
readout::ROPID geo::ColdBoxWireReadoutGeom::ChannelToROP
  (raw::ChannelID_t channel) const
{
  if (!raw::isValidChannelID(channel)) return {};
  
  ChannelToWireMap::ChannelsInROPStruct const* info
    = fChannelToWireMap.find(channel);
  return info? info->ropid: readout::ROPID{};
} // geo::ColdBoxWireReadoutGeom::ChannelToROP()


//------------------------------------------------------------------------------
raw::ChannelID_t geo::ColdBoxWireReadoutGeom::FirstChannelInROP
  (readout::ROPID const& ropid) const
{
  if (!ropid) return raw::InvalidChannelID;
  
  ChannelToWireMap::ChannelsInROPStruct const* info
    = fChannelToWireMap.find(ropid);
  return info? info->firstChannel: raw::InvalidChannelID;
} // geo::ColdBoxWireReadoutGeom::FirstChannelInROP()


//------------------------------------------------------------------------------
geo::PlaneID geo::ColdBoxWireReadoutGeom::FirstWirePlaneInROP
  (readout::ROPID const& ropid) const
{
  if (!ropid) return {};
  PlaneColl_t const& planes = ROPplanes(ropid);
  return planes.empty()? geo::PlaneID{}: planes.front();
} // geo::ColdBoxWireReadoutGeom::FirstWirePlaneInROP()


//------------------------------------------------------------------------------
bool geo::ColdBoxWireReadoutGeom::HasCryostat
  (readout::CryostatID const& cryoid) const
{
  assert(fReadoutMapInfo);
  return cryoid.Cryostat < fReadoutMapInfo.NCryostats();
} // geo::ColdBoxWireReadoutGeom::HasCryostat()


//------------------------------------------------------------------------------
void geo::ColdBoxWireReadoutGeom::fillChannelToWireMap
  (std::vector<geo::CryostatGeo> const& Cryostats)
{
  
  //
  // input check
  //
  assert(fReadoutMapInfo);
  assert(!Cryostats.empty());
  
  //mf::LogInfo("ColdBoxWireReadoutGeom")<<"fillChannelToWireMap\n";
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
        
        mf::LogTrace log("ColdBoxWireReadoutGeom");
        
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
        
        auto iPlane = util::begin(planes);
        auto const pend = util::end(planes);
        
        // assign available channels to all wires of the first plane
        nextChannel += (*iPlane)->Nwires();
        fPlaneInfo[(*iPlane)->ID()] = {
          ChannelRange_t{ firstROPchannel, nextChannel }, rid };
        log << " [" << (*iPlane)->ID() << "] "
          << fPlaneInfo[(*iPlane)->ID()].firstChannel()
          << " -- " << fPlaneInfo[(*iPlane)->ID()].lastChannel() << ";";
        
        geo::Point_t lastWirePos = (*iPlane)->LastWire().GetCenter();
	
        while (++iPlane != pend) {
          
          geo::PlaneGeo const& plane = **iPlane;
          
          // find out which wire matches the last wire from the previous plane;
          // if there is no such wire, an exception will be thrown,
          // which is ok to us since we believe it should not happen.
          geo::WireID const lastMatchedWireID
            = plane.NearestWireID(lastWirePos);
          
          /*
          mf::LogTrace("ColdBoxWireReadoutGeom")
            << (*std::prev(iPlane))->ID() << " W:" << ((*std::prev(iPlane))->Nwires() - 1)
            << " ending at " << (*std::prev(iPlane))->LastWire().GetEnd()
            << " matched " << lastMatchedWireID
            << " which starts at " << plane.Wire(lastMatchedWireID).GetStart()
            ;
          */
          
          // For ROP = 0 (1st induction)
          // the first channel in this plane (`iPlane`) is the one associated
          // to the first wire in the plane, which has local wire number `0`;
          // the last channel from the previous plane (`nextChannel - 1`)
          // is associated to the matched wire (`lastMatchedWireID`),
          // which has some wire number (`lastMatchedWireID.Wire`).
          //
          auto const nWires = plane.Nwires();
          raw::ChannelID_t const firstChannel = 
	    (r == 0)?((nextChannel - 1) - lastMatchedWireID.Wire):nextChannel;

          nextChannel = firstChannel + nWires;
          
          fPlaneInfo[plane.ID()] = { { firstChannel, nextChannel }, rid };
          log << " [" << plane.ID() << "] "
            << fPlaneInfo[plane.ID()].firstChannel() << " -- "
            << fPlaneInfo[plane.ID()].lastChannel() << ";";
          
          // update for the next iteration
          lastWirePos = plane.LastWire().GetCenter();
          
        } // while
        
	unsigned int const nChannels = nextChannel - firstROPchannel;
        fChannelToWireMap.addROP(rid, firstROPchannel, nChannels);
        log
          << " => " << nChannels << " channels starting at " << firstROPchannel;
        
      } // for readout plane
      
    } // for TPC set
    
  } // for cryostat
  
  fChannelToWireMap.setEndChannel(nextChannel);
  mf::LogInfo("ColdBoxWireReadoutGeom")
    << "Counted " << fChannelToWireMap.nChannels() << " channels.";
  
} // geo::ColdBoxWireReadoutGeom::fillChannelToWireMap()


// -----------------------------------------------------------------------------
void geo::ColdBoxWireReadoutGeom::buildReadoutPlanes
  (std::vector<geo::CryostatGeo> const& Cryostats)
{
  auto const [ NCryostats, MaxTPCs, MaxPlanes ]
    = geo::details::extractMaxGeometryElements<3U>(Cryostats, *this);
  
  //mf::LogInfo("ColdBoxWireReadoutGeom")
  //<< "Build readout planes for "<<NCryostats<<" "<<MaxTPCs<<" "<<MaxPlanes<<"\n";
  

  if( Cryostats.size() > 1 ){
    throw cet::exception("Geometry")
      << "geo::ColdBoxWireReadoutGeom::buildReadoutPlanes " << Cryostats.size()
      << ": more than one cryostat is currently not supported\n";
  }
  
  if( Cryostats[0].NTPC() != 4 ){
    throw cet::exception("Geometry")
      << "geo::ColdBoxWireReadoutGeom::buildReadoutPlanes " << Cryostats[0].NTPC()
      << ": more than four TPCs is currently not supported\n";
  }
  
  // currently do it by hand for CB --> to be generalized for FD
  auto cryo = Cryostats[0];
  //unsigned int MaxTPCs = cryo.NTPC();
  //unsigned int MaxPlanes = 3;
  unsigned int MaxROPs    = 3;
  unsigned int MaxTPCsets = MaxTPCs/2;
  std::vector<unsigned int> TPCsetCount = {2};
  std::vector<std::vector<const geo::TPCGeo*>> AllTPCsInTPCsets( MaxTPCsets );       // TPCs belonging to a set
  // the standard CRU sorter is assumed (fixing this another "todo")
  AllTPCsInTPCsets[0] = {cryo.TPCPtr(0), cryo.TPCPtr(2)};
  AllTPCsInTPCsets[1] = {cryo.TPCPtr(1), cryo.TPCPtr(3)};
  readout::TPCsetDataContainer<TPCColl_t> TPCsetTPCs(NCryostats, MaxTPCsets);
  
  for( auto&& [s, TPClist ]: util::enumerate(AllTPCsInTPCsets) ){
    readout::TPCsetID const tpcsetid
    { cryo.ID(), static_cast<readout::TPCsetID::TPCsetID_t>(s) };
    //mf::LogInfo("ColdBoxWireReadoutGeom")<< tpcsetid <<" "<<TPCPtrs.size()<<"\n";
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
} // geo::ColdBoxWireReadoutGeom::buildReadoutPlanes()


// -----------------------------------------------------------------------------
std::size_t geo::ColdBoxWireReadoutGeom::findPlaneType(readout::ROPID const& rid) const
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
  
} // geo::ColdBoxWireReadoutGeom::findPlaneType()


// ----------------------------------------------------------------------------
geo::SigType_t geo::ColdBoxWireReadoutGeom::SignalTypeForChannelImpl
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
} // geo::ColdBoxWireReadoutGeom::SignalTypeForChannelImpl()


// ----------------------------------------------------------------------------
std::string geo::ColdBoxWireReadoutGeom::PlaneTypeName(PlaneType_t planeType) {
  
  using namespace std::string_literals;
  switch (planeType) {
    case kFirstInductionType:  return "first induction"s;
    case kSecondInductionType: return "second induction"s;
    case kCollectionType:      return "collection induction"s;
    case kUnknownType:         return "unknown"s;
    default:
      return "unsupported ("s + std::to_string(planeType) + ")"s;
  } // switch
  
} // geo::ColdBoxWireReadoutGeom::PlaneTypeName()


// ----------------------------------------------------------------------------
