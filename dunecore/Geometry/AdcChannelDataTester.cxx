// AdcChannelDataTester.cxx

#include "AdcChannelDataTester.h"
#include "larcore/Geometry/WireReadout.h"
#include "larcore/Geometry/Geometry.h"
#include "art/Framework/Services/Registry/ServiceHandle.h"
#include <ostream>
#include <iomanip>

using std::string;
using std::cout;
using std::endl;
using std::setw;
using Index = unsigned int;

//**********************************************************************

int AdcChannelDataTester::
fill(AdcChannelData& acd, Index icha, Index isam0) {
  const string myname = "AdcChannelDataTester::fill: ";
  acd.setEventInfo(new AdcChannelData::EventInfo(run, event, subrun));
  acd.setChannelInfo(icha);
  acd.pedestal = pedestal;
  acd.sampleUnit = "ke";
  if ( acd.raw.size() < nsam ) acd.raw.resize(nsam, 0);
  if ( acd.samples.size() < nsam ) acd.samples.resize(nsam, 0.0);
  for ( Index isam=0; isam<rawwf.size(); ++isam ) {
    Index ksam = (isam+isam0)%nsam;
    acd.raw[ksam] += rawwf[isam];
  }
  for ( Index isam=0; isam<samwf.size(); ++isam ) {
    Index ksam = (isam+isam0)%nsam;
    acd.samples[ksam] += samwf[isam];
  }
  return 0;
}

//**********************************************************************

int AdcChannelDataTester::
strumChannels(AdcChannelDataMap& acds, Index a_ncha) {
  const string myname = "strumChannels: ";
  Index ncha = a_ncha;
  if ( ncha == 0 ) {
    art::ServiceHandle<geo::Geometry> pgeo;
    if ( pgeo->DetectorName() == "" ) {
      cout << myname << "Geometry not found." << endl;
      return 1;
    }
    ncha = art::ServiceHandle<geo::WireReadout>()->Get().Nchannels();
  }
  for ( Index icha=0; icha<ncha; ++icha ) {
    channel = icha;
    fill(acds[icha], icha, icha);
  }
  return 0;
}
  
//**********************************************************************

// Strum all wires in a TPC.

int AdcChannelDataTester::
strumTpcWires(AdcChannelDataMap& acds, Index itpc, Index icry) {
  const string myname = "strumTpcWires: ";

  art::ServiceHandle<geo::Geometry> pgeo;
  if ( pgeo->DetectorName() == "" ) {
    cout << myname << "Geometry not found." << endl;
    return 1;
  }

  geo::TPCID tid(icry, itpc);
  if ( ! pgeo->HasTPC(tid) ) {
    cout << myname << "TPC not found: " << tid << endl;
    return 2;
  }
  auto const& wireReadout = art::ServiceHandle<geo::WireReadout>()->Get();
  Index npla = wireReadout.Nplanes(tid);
  Index nsam = 500;
  Index isam = 0;
  for ( Index ipla=0; ipla<npla; ++ipla ) {
    geo::PlaneID pid(tid, ipla);
    Index nwir = wireReadout.Nwires(pid);
    for ( Index iwir=0; iwir<nwir; ++iwir ) {
      geo::WireID wid(pid, iwir);
      Index icha = wireReadout.PlaneWireToChannel(wid);
      fill(acds[channel], icha, isam);
      if ( ++isam >= nsam ) isam = 0;
    }
  }

  return 0;
}

//**********************************************************************

// Strum all wires in a cryostat.

int AdcChannelDataTester::
strumCryoWires(AdcChannelDataMap& acds, Index icry) {
  const string myname = "strumCryoWires: ";

  art::ServiceHandle<geo::Geometry> pgeo;
  if ( pgeo->DetectorName() == "" ) {
    cout << myname << "Geometry not found." << endl;
    return 1;
  }

  const geo::CryostatGeo& gcry = pgeo->Cryostat(geo::CryostatID{icry});
  for ( Index itpc=0; itpc<gcry.NTPC(); ++itpc ) {
    strumTpcWires(acds, itpc, icry);
  }

  return 0;
}

//**********************************************************************

// Strum all wires in the detector.

int AdcChannelDataTester::
strumDetectorWires(AdcChannelDataMap& acds) {
  const string myname = "strumDetectorWires: ";

  art::ServiceHandle<geo::Geometry> pgeo;
  if ( pgeo->DetectorName() == "" ) {
    cout << myname << "Geometry not found." << endl;
    return 1;
  }

  Index ncry = pgeo->Ncryostats();
  for ( Index icry=0; icry<ncry; ++icry ) {
    strumCryoWires(acds, icry);
  }

  return 0;
}

//**********************************************************************
