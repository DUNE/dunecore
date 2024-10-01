// test_GeometryDune.cxx

#ifndef test_GeometryDune_CXX
#define test_GeometryDune_CXX

// David Adams
// November 2016
//
// Test the DUNE geometry including channel mapping.
//
// This test demonstrates how to configure and use the LArSoft Geometry
// service outside the art framework. DUNE geometry and geometry helper
// service are used.
//
// Note the geometry service requires the experiment-specific geometry
// helper with the channel map also be loaded.
//
// The functions that set the expected values must be defined externally.

#undef NDEBUG

#include "larcore/Geometry/WireReadout.h"
#include "larcore/Geometry/Geometry.h"
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include "dunecore/ArtSupport/ArtServiceHelper.h"
#include "art/Framework/Services/Registry/ServiceHandle.h"
#include "larcorealg/Geometry/Exceptions.h"

using std::string;
using std::cout;
using std::cerr;
using std::endl;
using std::ofstream;
using std::istringstream;
using std::ostringstream;
using std::setw;
using std::vector;
using std::abs;
using geo::View_t;
using geo::SigType_t;
using geo::CryostatID;
using geo::TPCID;
using geo::PlaneID;
using geo::WireID;
typedef readout::TPCsetID APAID;
using readout::ROPID;
using geo::Geometry;
using geo::WireReadoutGeom;
using geo::CryostatGeo;
using geo::TPCGeo;
using geo::WireGeo;

typedef unsigned int Index;
const Index InvalidIndex = std::numeric_limits<Index>::max();

template<class T>
using Vector = vector<T>;

template<class T>
using TwoVector = Vector<Vector<T>>;

template<class T>
using ThreeVector = Vector<TwoVector<T>>;

template<class T, class V>
void resize(Vector<T>& vec1, Index n1, const V& val) {
  vec1.resize(n1, val);
}

template<class T, class V>
void resize(TwoVector<T>& vec2, Index n1, Index n2, const V& val) {
  vec2.resize(n1);
  for ( Vector<T>& vec1 : vec2 ) {
    vec1.resize(n2, val);
  }
}

template<class T, class V>
void resize(ThreeVector<T>& vec3, Index n1, Index n2, Index n3, const V& val) {
  vec3.resize(n1);
  for ( TwoVector<T>& vec2 : vec3 ) {
    vec2.resize(n2);
    for ( Vector<T>& vec1 : vec2 ) {
      vec1.resize(n3, val);
    }
  }
}

struct SpacePoint {
  double x;
  double y;
  double z;
  SpacePoint(double ax, double ay, double az) : x(ax), y(ay), z(az) { }
};

//**********************************************************************

// Helper functions

namespace {

template<class T>
void check(string name, T val) {
  cout << name << ": " << val << endl;
}

template<class T, class V>
void check(string name, T val, V checkval, bool print =true, bool doAssert =true) {
  if ( print ) check(name, val);
  T eval = checkval;
  if ( val != eval ) {
    cout << val << " != " << checkval << endl;
    assert(! doAssert);
    cout << "************** Assertion not made!!! *************" << endl;
  }
}

template<class T, class V>
void checkval(string name, T val, V chkval) {
  T eval = chkval;
  if ( val != eval ) {
    cout << endl << "---------------------------------" << endl;
    cout << name << ": " << val << " != " << chkval << endl;
    cout << "---------------------------------" << endl;
    assert(false);
  }
}

void checkfloat(double x1, double x2, double tol =1.e-5) {
  double den = abs(x1) + abs(x2);
  double num = abs(x2 - x1);
  if ( num/den > tol ) {
    cout << endl << "---------------------------------" << endl;
    cout << "checkfloat: " << x1 << " != " << x2 << endl;
    cout << "---------------------------------" << endl;
    assert(false);
  }
}

//**********************************************************************

// Helper classes.

struct ExpectedValues {
  typedef void (*FunPtr)(Geometry*);
  string gname;
  string chanmap;
  string sorter;
  string fullname;
  Index ncry = 0;
  Index ntpc = 0;
  Index npla = 0;
  Index napa = 0;
  Index nrop = 0;
  Index nchaPerApa = 0;
  Index nchatot = 0;
  ThreeVector<View_t> view;
  ThreeVector<SigType_t> sigType;
  TwoVector<Index> nwirPerPlane;
  // For ROP tests.
  Vector<Index> nchaPerRop;
  Vector<Index> chacry;          // Expected cryostat for each channel;
  Vector<Index> chaapa;          // Expected APA for each channel;
  Vector<Index> charop;          // Expected ROP for each channel;
  ThreeVector<Index> firstchan;  // First channel(cry, apa, rop)
  // For space point tests.
  FunPtr pfun = nullptr;
  vector<double> xfs;            // x-fractions for space points
  vector<double> yfs;            // y-fractions for space points
  vector<double> zfs;            // z-fractions for space points
  Vector<SpacePoint> posXyz;     // Space points.
  vector<double> posTpc;         // TPCs for space points
  vector<double> posPla;         // TPC planes for space points
  vector<double> posWco;         // Wire coordinates for space points
  // Photon detectors.
  Index nopdet = 0;
  Index nopcha = 0;              // # readout channels
  Index nopchaHardware = 0;      // # harware channels (0 means same as readout)
  Vector<Index> nopdetcha;
  TwoVector<Index> opdetcha;
};

//**********************************************************************

}  //end unnamed namespace

//**********************************************************************

// Functions that set the expected values.
// These must be defined externally.

void setExpectedValues(ExpectedValues& ev);
void setExpectedValuesSpacePoints(Geometry const*, WireReadoutGeom const&);

//**********************************************************************

// Function that carries out the test.
//            ev - expected results
//         dorop - If true ROP mapping methods are tested
//  maxchanprint - Max # channels to display for each ROP

int test_GeometryDune(const ExpectedValues& ev, bool dorop, Index maxchanprint,
                      bool useExistingFcl) {
  const string myname = "test_GeometryDune: ";
  cout << myname << "Starting test" << endl;
#ifdef NDEBUG
  cout << myname << "NDEBUG must be off." << endl;
  abort();
#endif
  string line = "-----------------------------";

  cout << myname << line << endl;
  cout << myname << "   Geometry: " << ev.gname << endl;
  cout << myname << "Channel map: " << ev.chanmap << endl;
  cout << myname << "     Sorter: " << ev.sorter << endl;
  cout << myname << "     Do ROP: " << dorop << endl;

  cout << myname << line << endl;
  cout << myname << "Create configuration." << endl;
  if (useExistingFcl) {
    ArtServiceHelper::load_services("test_GeometryDune.fcl",
                                    ArtServiceHelper::FileOnPath);
  } else {
    std::stringstream config;
    config << "#include \"geometry_dune.fcl\"" << endl;
    config << "services.Geometry:                   @local::" << ev.gname << endl;
    if (ev.gname.find("dune35t") != std::string::npos) {
      config << "services.WireReadout:     @local::dune35t_wire_readout" << endl;
    } else {
    config << "services.WireReadout:     @local::dune_wire_readout" << endl;
    }
    if ( ev.chanmap.size() ) {
      config << "services.WireReadout.ChannelMapClass: " << ev.chanmap << endl;
    }
    //config << "services.WireReadout.GeoSorterClass: " << ev.sorter << endl;
    ArtServiceHelper::load_services(config);
  }

  cout << myname << line << endl;
  cout << myname << "Get Geometry service." << endl;
  art::ServiceHandle<geo::Geometry> pgeo;
  auto const& wireReadout = art::ServiceHandle<geo::WireReadout>()->Get();

  cout << myname << line << endl;
  check("Default wiggle", pgeo->DefaultWiggle());
  check("Geometry name", pgeo->DetectorName(), ev.fullname);
  cout << myname << "GDML name: " << pgeo->GDMLFile() << endl;

  cout << myname << line << endl;
  double xlo, ylo, zlo;
  double xhi, yhi, zhi;
  cout << myname << "World box"  << endl;
  pgeo->WorldBox(&xlo, &ylo, &zlo, &xhi, &yhi, &zhi);
  check("  xlo", xlo);
  check("  ylo", ylo);
  check("  zlo", zlo);
  check("  xhi", xhi);
  check("  yhi", yhi);
  check("  zhi", zhi);

  cout << myname << line << endl;
  check("SurfaceY", pgeo->SurfaceY());

  cout << myname << line << endl;
  if ( 0  ) check("GetWorldVolumeName", pgeo->GetWorldVolumeName());
  if ( 0 ) check("TotalMass", pgeo->TotalMass());

  cout << myname << line << endl;
  auto const& cryostat = pgeo->Cryostat();
  check("CryostatHalfWidth", cryostat.HalfWidth());
  check("CryostatHalfHeight", cryostat.HalfHeight());
  check("CryostatLength", cryostat.Length());
  //check("", pgeo->());

  cout << myname << line << endl;
  Index ncry = pgeo->Ncryostats();
  check("Ncryostats", ncry, ev.ncry);
  check("MaxTPCs", pgeo->MaxTPCs(), ev.ntpc);
  check("MaxPlanes", wireReadout.MaxPlanes(), ev.npla);
  check("TotalNTPC", pgeo->TotalNTPC(), ev.ntpc);
  check("Nviews", wireReadout.Nviews(), ev.npla);
  check("Nchannels", wireReadout.Nchannels(), ev.nchatot);

  cout << myname << line << endl;
  cout << "Check TPC wire plane counts." << endl;
  for ( auto const& cid : pgeo->Iterate<geo::CryostatID>() ) {
    auto icry = cid.Cryostat;
    Index ntpc = pgeo->NTPC(cid);
    cout << "  Cryostat " << icry << " has " << ntpc << " TPCs" << endl;
    for ( auto const& tpcid : pgeo->Iterate<geo::TPCID>(cid)) {
      auto itpc = tpcid.TPC;
      Index npla = wireReadout.Nplanes(tpcid);
      cout << "    TPC " << itpc << " has " << npla << " planes" << endl;
      assert( npla == 3 );
      for ( auto const& planeid : wireReadout.Iterate<geo::PlaneID>(tpcid) ) {
        auto ipla = planeid.Plane;
        Index nwir = wireReadout.Nwires(planeid);
        Index ich1 = wireReadout.Nchannels();
        Index ich2 = 0;
        for ( auto const& wid : wireReadout.Iterate<geo::WireID>(planeid) ) {
          Index ich = wireReadout.PlaneWireToChannel(wid);
          if ( ich < ich1 ) ich1 = ich;
          if ( ich > ich2 ) ich2 = ich;
        }
        cout << "      Plane " << ipla << " has " << setw(4) << nwir << " wires"
             << " readout on channels [" << ich1 << ", " << ich2 << "]"
             << endl;
        assert( nwir == ev.nwirPerPlane[itpc][ipla] );
      }
    }
  }

  cout << myname << line << endl;
  cout << "Check wire planes." << endl;
  const double piOver2 = 0.5*acos(-1.0);
  for ( auto const& gpla : wireReadout.Iterate<geo::PlaneGeo>() ) {
    auto const& plaid = gpla.ID();
    cout << "  Plane " << plaid << endl;
    cout << "    Signal type: " << wireReadout.SignalType(plaid) << endl;
    cout << "           View: " << wireReadout.Plane(plaid).View() << endl;
    cout << "     Wire angle: " << gpla.ThetaZ() - piOver2 << endl;
    assert( wireReadout.SignalType(plaid) == ev.sigType[plaid.Cryostat][plaid.TPC][plaid.Plane] );
    assert( wireReadout.Plane(plaid).View() == ev.view[plaid.Cryostat][plaid.TPC][plaid.Plane] );
  }

  cout << myname << line << endl;
  cout << "Check channel-wire mapping." << endl;
  Index itpc1Last = TPCID::InvalidID;
  Index ipla1Last = WireID::InvalidID;
  Index nprint = 0;
  TwoVector<Index> lastwire;
  resize(lastwire, ev.ntpc, ev.npla, 0);
  for ( Index itpc=0; itpc<ev.ntpc; ++itpc )
    for ( Index ipla=0; ipla<ev.npla; ++ipla )
      lastwire[itpc][ipla] = 0;
  for ( Index icha=0; icha<ev.nchatot; ++icha ) {
    vector<WireID> wirids = wireReadout.ChannelToWire(icha);
    assert( wirids.size() > 0 );
    WireID wirid1 = wirids[0];
    Index itpc1 = wirid1.TPC;
    Index iapa1 = itpc1/2;
    Index ipla1 = wirid1.Plane;
    if ( itpc1 != itpc1Last || ipla1 != ipla1Last ) nprint = 0;
    itpc1Last = itpc1;
    ipla1Last = ipla1;
    bool print = nprint < maxchanprint;
    if ( print ) ++nprint;
    if ( print ) cout << "  Channel " << setw(4) << icha << " has " << wirids.size() << " wires:";
    ostringstream sposs;
    sposs.precision(2);
    for ( WireID wirid : wirids ) {
      Index itpc = wirid.TPC;
      Index iapa = itpc/2;
      Index ipla = wirid.Plane;
      Index iwir = wirid.Wire;
      if ( print ) cout << " " << itpc << "-" << ipla << "-" << setw(3) << iwir;
      if ( iwir > lastwire[itpc][ipla] ) lastwire[itpc][ipla] = iwir;
      assert( iapa == iapa1 );
      assert( ipla == ipla1 );
      checkval("\nPlaneWireToChannel", wireReadout.PlaneWireToChannel(wirid), icha );
      assert( wireReadout.SignalType(icha) == ev.sigType[wirid.Cryostat][wirid.TPC][wirid.Plane] );
      checkval("View", wireReadout.View(icha), ev.view[wirid.Cryostat][wirid.TPC][wirid.Plane]);
      const WireGeo* pwg = wireReadout.WirePtr(wirid);
      auto const p1 = pwg->GetStart();
      auto const p2 = pwg->GetEnd();
      if ( sposs.str().size() ) sposs << ", ";
      sposs << "(" << setw(7) << std::fixed << p1.x() << ", "
                   << setw(7) << std::fixed << p1.y() << ", "
                   << setw(7) << std::fixed << p1.z() << ") - ";
      sposs << "(" << setw(7) << std::fixed << p2.x() << ", "
                   << setw(7) << std::fixed << p2.y() << ", "
                   << setw(7) << std::fixed << p2.z() << ")";
    }
    if ( print ) cout << " " << sposs.str() << endl;
  }
  for ( Index itpc=0; itpc<ev.ntpc; ++itpc ) {
    for ( Index ipla=0; ipla<ev.npla; ++ipla ) {
      Index nwir = lastwire[itpc][ipla] + 1;
      cout << "  TPC-plane " << itpc << "-" << ipla << " has " << setw(3) << nwir << " wires" << endl;
      assert( nwir == ev.nwirPerPlane[itpc][ipla] );
    }
  }

  if ( dorop ) {
    cout << myname << line << endl;
    cout << "Check ROP counts and channels." << endl;
    check("MaxROPs", wireReadout.MaxROPs(), ev.nrop);
    Index icry = 0;
    for ( auto const& cryid : pgeo->Iterate<geo::CryostatID>() ) {
      Index napa = wireReadout.NTPCsets(cryid);
      cout << "  Cryostat " << icry << " has " << napa << " APAs" << endl;
      assert( napa == ev.napa );
      for ( Index iapa=0; iapa<napa; ++iapa ) {
        APAID apaid(cryid, iapa);
        Index nrop = wireReadout.NROPs(apaid);
        cout << "    APA " << iapa << " has " << nrop << " ROPs" << endl;
        assert( nrop == ev.nrop );
        for ( Index irop=0; irop<nrop; ++irop ) {
          ROPID ropid(apaid, irop);
          Index ncha = wireReadout.Nchannels(ropid);
          Index icha1 = wireReadout.FirstChannelInROP(ropid);
          Index icha2 = icha1 + ncha - 1;
          cout << "      ROP " << irop << " has " << ncha << " channels: ["
               << icha1 << ", " << icha2 << "]" << endl;
          assert( ncha == ev.nchaPerRop[irop] );
          assert( icha1 == ev.firstchan[icry][iapa][irop] );
        }
      }
      ++icry;
    }
    assert( icry == ncry );
    cout << myname << line << endl;
    cout << "Check channel-ROP mapping." << endl;
    icry = 0;
    for ( Index icha=0; icha<ev.nchatot; ++icha ) {
      ROPID ropid = wireReadout.ChannelToROP(icha);
      Index icry = ropid.Cryostat;
      Index iapa = ropid.TPCset;
      Index irop = ropid.ROP;
      assert( icry == ev.chacry[icha] );
      assert( iapa == ev.chaapa[icha] );
      assert( irop == ev.charop[icha] );
    }
    cout << myname << line << endl;
    cout << "Check ROP-TPC mapping." << endl;
    for ( auto const& cryid: pgeo->Iterate<geo::CryostatID>() ) {
      Index napa = wireReadout.NTPCsets(cryid);
      cout << "  Cryostat " << icry << " has " << napa << " APAs" << endl;
      assert( napa == ev.napa );
      for ( Index iapa=0; iapa<napa; ++iapa ) {
        APAID apaid(cryid, iapa);
        Index nrop = wireReadout.NROPs(apaid);
        cout << "    APA " << iapa << " has " << nrop << " ROPs" << endl;
        assert( nrop == ev.nrop );
        for ( Index irop=0; irop<nrop; ++irop ) {
          ROPID ropid(apaid, irop);
          std::vector<geo::TPCID> rtpcs = wireReadout.ROPtoTPCs(ropid);
          Index nrtpc = rtpcs.size();
          assert( nrtpc > 0 );
          cout << "      ROP " << irop << " TPCs:";
          for ( Index irtpc=0; irtpc<nrtpc; ++irtpc ) {
            assert(rtpcs[irtpc].Cryostat == icry);
            cout << (irtpc > 0  ? "," : "") << " " << rtpcs[irtpc].TPC;
          }
          cout << endl;
        }
      }
    }
  } else {
    cout << myname << line << endl;
    cout << "Skipped APA and ROP tests." << endl;
  }  // end dorop

  cout << myname << line << endl;
  Index nspt = ev.posXyz.size();
  if ( nspt == 0 ) {
    cout << myname << "No space points found." << endl;
    cout << myname << "Creating space points." << endl;
    setExpectedValuesSpacePoints(pgeo.get(), wireReadout);
  } else {
    cout << myname << "Check " << nspt << " space points." << endl;
    assert( ev.posPla.size() == ev.posTpc.size() );
    assert( ev.posWco.size() == ev.posTpc.size() );
    Index ires = 0;
    int w = 9;
    for ( Index ispt=0; ispt<nspt; ++ispt ) {
      double x = ev.posXyz[ispt].x;
      double y = ev.posXyz[ispt].y;
      double z = ev.posXyz[ispt].z;
      geo::Point_t const xyz{x, y, z};
      TPCID tpcid = pgeo->FindTPCAtPosition(xyz);
      cout << "  (" << setw(w) << x << "," << setw(w) << y << "," << setw(w) << z << "): " << tpcid << endl;
      assert( tpcid.Cryostat != CryostatID::InvalidID );
      unsigned int itpc = tpcid.TPC;
      assert( itpc != TPCID::InvalidID );
      unsigned int npla = wireReadout.Nplanes(tpcid);
      assert( npla == ev.npla );
      assert( npla > 0 );
      for ( unsigned int ipla=0; ipla<npla; ++ipla ) {
        assert( ires < ev.posTpc.size() );
        PlaneID plaid(tpcid, ipla);
        WireID wirid;
        try { wirid = wireReadout.Plane(plaid).NearestWireID(xyz); }
        catch (geo::InvalidWireError const& e) {
          if (!e.hasSuggestedWire()) throw;
          cerr << "ERROR (non-fatal):\n" << e;
          wirid = e.suggestedWireID();
        }
        double xwire = wireReadout.Plane(plaid).WireCoordinate(geo::Point_t{0, x, y});
        cout << "    TPC " << setw(2) << itpc << " plane " << ipla
             << " nearest wire is " << setw(3) << wirid.Wire
             << " and coordinate is " << xwire << endl;
        assert( itpc == ev.posTpc[ires] );
        assert( ipla == ev.posPla[ires] );
        checkfloat(xwire, ev.posWco[ires], 2.e-4);
        ++ires;
      }  // end loop over planes
    }  // end loop over space points
    cout << "  # checked planes: " << ires << endl;
  }
  // Optical detectors.
  bool dophot = true;
  bool doAssert = true;   // Flag to turn off assertions while testing the test
  if ( dophot ) {
    Index nopt = pgeo->NOpDets();
    check("# Optical detectors expected", nopt, ev.nopdet, true, doAssert);
    Index nopchaReadout = ev.nopcha;
    Index nopchaHardware = ev.nopchaHardware ? ev.nopchaHardware : nopchaReadout;
    cout << " Expected optical readout channel count: " << nopchaReadout << endl;
    cout << "Expected optical hardware channel count: " << nopchaHardware << endl;
    cout << "         Geometry optical channel count: " << wireReadout.NOpChannels() << endl;
    check("# Optical channels", wireReadout.NOpChannels(), nopchaHardware, true, doAssert);
    cout << "Per-detector optical channel counts:" << endl;
    assert( ev.nopdetcha.size() == nopt );
    bool doAssert = true;  // True enable assertions in the indvidual channel checks.
    for ( Index iopt=0; iopt<nopt; ++iopt ) {
      ostringstream sslab;
      sslab << "  # channels for optical detector " << iopt;
      //bool print = iopt < maxchanprint;
      check(sslab.str(), wireReadout.NOpHardwareChannels(iopt), ev.nopdetcha[iopt], true, doAssert);
    }
    assert(doAssert);
    cout << " Opdet channels:" << endl;
    for ( Index iopt=0; iopt<nopt; ++iopt ) {
      Index noch = wireReadout.NOpHardwareChannels(iopt);
      for ( Index ioch=0; ioch<noch; ++ioch ) {
        ostringstream sslab;
        sslab << "  Det " << iopt << ", chan " << ioch;
        Index icha = wireReadout.OpChannel(iopt, ioch);
        check(sslab.str() + " (channel)", icha, ev.opdetcha[iopt][ioch], true, doAssert);
        if ( nopchaHardware == nopchaReadout ) {
          check(sslab.str() + " (OpDet)", wireReadout.OpDetFromOpChannel(icha), iopt, true, doAssert);
        }
        check(sslab.str() + " (HardwareChannel)", wireReadout.HardwareChannelFromOpChannel(icha), ioch, true, doAssert);
      }
    }
  }

  cout << myname << line << endl;
  cout << myname << "Done." << endl;
  return 0;
}

//**********************************************************************

int main(int argc, const char* argv[]) {
  ExpectedValues ev;
  setExpectedValues(ev);
  bool dorop = true;
  Index maxchanprint = 10;
  bool useExistingFcl = false;
  if ( argc > 1 ) {
    string sarg = argv[1];
    if ( sarg == "-h" ) {
      cout << argv[0] << ": . [dorop] [maxchan] [usefcl]" << endl;
      cout << argv[0] << ": [ChannelMapClass] [dorop] [maxchan] [usefcl]" << endl;
      cout << argv[0] << ": [Geometry/ChannelMapClass/sorter] [dorop] [maxchan] [usefcl]" << endl;
      cout << "    dorop: If true ROP mapping methods are tested [true]" << endl;
      cout << "  maxchan: Max # channels displayed for each ROP [10]" << endl;
      cout << "   usefcl: Take top-level fcl from current directory [false]" << endl;
      return 0;
    }
    string::size_type ipos = sarg.find("/");
    if ( ipos == string ::npos ) {
      if ( sarg != "." ) ev.chanmap = sarg;
    } else {
      ev.gname = sarg.substr(0, ipos);
      string::size_type jpos = sarg.find("/", ipos+1);
      if ( jpos == string::npos ) {
        ev.chanmap = sarg.substr(ipos+1);
      } else {
        ev.chanmap = sarg.substr(ipos+1, jpos-ipos-1);
        ev.sorter = sarg.substr(jpos+1);
      }
    }
  }
  if ( argc > 2 ) {
    string sarg = argv[2];
    dorop = sarg == "1" || sarg == "true" || sarg == ".";
  }
  if ( argc > 3 ) {
    istringstream ssarg(argv[3]);
    ssarg >> maxchanprint;
  }
  if ( argc > 4 ) {
    string sarg = argv[4];
    useExistingFcl = sarg == "1" || sarg == "true";
  }
  test_GeometryDune(ev, dorop, maxchanprint, useExistingFcl);
  cout << "Tests concluded." << endl;
  return 0;
}

//**********************************************************************

#endif
