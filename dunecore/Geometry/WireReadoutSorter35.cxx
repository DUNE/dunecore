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
#include "dunecore/Geometry/WireReadoutSorter35.h"
#include "larcorealg/Geometry/WireGeo.h"

#include "fhiclcpp/ParameterSet.h"
#include "messagefacility/MessageLogger/MessageLogger.h"

geo::WireReadoutSorter35::WireReadoutSorter35(fhicl::ParameterSet const& p)
  : fDetVersion(p.get< std::string >("DetectorVersion", "dune35t4apa"))
{}

bool geo::WireReadoutSorter35::compareWires(WireGeo const& w1, WireGeo const& w2) const
{
  auto const xyz1 = w1.GetCenter();
  auto const xyz2 = w2.GetCenter();

  //mf::LogVerbatim("sortWire35") << "Sorting wires: ("
  //			      << xyz1.X() <<","<< xyz1.Y() <<","<< xyz1.Z() << ") and ("
  //			      << xyz2.X() <<","<< xyz2.Y() <<","<< xyz2.Z() << ")";


  // immedieately take care of vertical wires regardless of which TPC
  // vertical wires should always have same y, and always increase in z direction
  if( xyz1.Y()==xyz2.Y() && xyz1.Z()<xyz2.Z() ) return true;

  ///////////////////////////////////////////////////////////
  // Hard code a number to tell sorting when to look
  // for top/bottom APAs and when to look for only one
  bool InVertSplitRegion = false;
  if(fDetVersion=="dune35t")             InVertSplitRegion = xyz1.Z() > 76.35;      // the old
  else if(fDetVersion=="dune35t4apa")    InVertSplitRegion = ((51 < xyz1.Z())       // the new...
                                                              && (xyz1.Z() < 102)); //
  else if(fDetVersion=="dune35t4apa_v2") InVertSplitRegion = ((52.74 < xyz1.Z())    // ...and improved
                                                              && (xyz1.Z() < 106.23));
  else if(fDetVersion=="dune35t4apa_v3"
          || fDetVersion=="dune35t4apa_v4"
          || fDetVersion=="dune35t4apa_v5"
          || fDetVersion=="dune35t4apa_v6"
          ) InVertSplitRegion = ((51.41045 < xyz1.Z())
                                 && (xyz1.Z() < 103.33445));
  ///////////////////////////////////////////////////////////

  // we want the wires to be sorted such that the smallest corner wire
  // on the readout end of a plane is wire zero, with wire number
  // increasing away from that wire.

  if( InVertSplitRegion ){

    // if a bottom TPC, count from bottom up
    if( xyz1.Y()<0 && xyz1.Y() < xyz2.Y() ) return true;

    // if a top TPC, count from top down
    if( xyz1.Y()>0 && xyz1.Y() > xyz2.Y() ) return true;

  }
  else {

    if( xyz1.Y() > xyz2.Y() ) return true;

  }

  return false;
}
