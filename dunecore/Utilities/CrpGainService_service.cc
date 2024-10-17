////////////////////////////////////////////////////////////////////////
// Class:       CrpGainService
// Plugin Type: service (art v3_02_06)
// File:        CrpGainService_service.cc
//
// Generated at Thu Nov  7 16:24:55 2019 by Vyacheslav Galymov using cetskelgen
// from cetlib version v3_07_02.
////////////////////////////////////////////////////////////////////////

#include <iostream>

#include "CrpGainService.h"
#include "art/Framework/Services/Registry/ServiceDefinitionMacros.h"
#include "fhiclcpp/ParameterSet.h"

#include "larcore/Geometry/WireReadout.h"
#include "larcore/Geometry/Geometry.h"
#include "lardataobj/Simulation/SimChannel.h"
#include "art/Framework/Services/Registry/ServiceHandle.h"

#include "dunecore/ArtSupport/DuneToolManager.h"
#include "dunecore/DuneInterface/Tool/FloatArrayTool.h"

#include <TFile.h>
#include <TH2F.h>

using std::cout;
using std::endl;
using std::string;

// ctor
util::CrpGainService::CrpGainService(fhicl::ParameterSet const& ps)
{
  const string myname = "util::CrpGainService::ctor: ";
  m_LogLevel     = ps.get<int>("LogLevel");
  m_CrpDefGain   = ps.get<double>("CrpDefaultGain");
  m_CrpNLem      = ps.get<unsigned int>("CrpNumLem");
  m_LemViewChans = ps.get<unsigned int>("LemViewChans");  
  m_LemEffTool   = ps.get<string>("LemEffTool"); 

  if( !m_LemEffTool.empty() )
    {
      
      // try to load lem transparency map
      DuneToolManager* ptm = DuneToolManager::instance();
      if ( ptm == nullptr ) 
	{
	  cout << myname << "Unable to retrieve tool manaager." << endl;
	} 
      else
	{
	  m_plemeff = ptm->getShared<FloatArrayTool>(m_LemEffTool);
	  if( ! m_plemeff )
	    {
	      cout << myname << "Unable to retrieve lem efficiency tool " << m_LemEffTool << endl;
	    }
	}
    }
  else m_plemeff = nullptr;
  
  //
  m_LemTotChans    = m_LemViewChans * m_LemViewChans;
  m_CrpNLemPerSide = sqrt( m_CrpNLem );

  m_UseDefGain = ((m_plemeff == nullptr) && (m_lemgainmap.empty()));
  
  // geo service
  m_geo   = art::ServiceHandle<geo::Geometry>().get();
  m_wireReadout = &art::ServiceHandle<geo::WireReadout>()->Get();

  if(m_LogLevel >= 1 )
    {
      cout<<myname<<"Configurations\n";
      cout<<myname<<"  LogLevel :       "<<m_LogLevel<<endl;
      cout<<myname<<"  CrpNominalGain : "<<m_CrpDefGain<<endl;
      cout<<myname<<"  CrpNumLem :      "<<m_CrpNLem<<endl;
      cout<<myname<<"  LemViewChans :   "<<m_LemViewChans<<endl;
      cout<<myname<<"  LemEffTool :     "<<m_LemEffTool<<" (@"<<m_plemeff<<")"<<endl;
      cout<<myname<<"  Use nominal gain : "<<m_UseDefGain<<endl;
    }

  if( !checkGeoConfig() && !m_UseDefGain )
    {
      throw cet::exception("CrpGainService")
	<< "Bad geometry configuration detected. ";
    }

  if( m_plemeff ) {
    if( m_LemTotChans != m_plemeff->size() ){
      cout<<myname<<"WARNING the LEM transmission map does not match the expected size."<<endl;
    }
  }
  
  // dump
  int nlemeff = ps.get<int>("DumpLemEff", 0);
  if( nlemeff > 0 ) dumpLemEffMap( nlemeff );

} // ctor

//
//
bool util::CrpGainService::checkGeoConfig() const
{
  const string myname = "util::CrpGainService::checkGeoConfig: ";
  
  if( m_CrpNLemPerSide * m_CrpNLemPerSide != m_CrpNLem )
    {
      cout<<myname<<"ERROR the number of LEMs per CRP is non-square\n";
      return false;
    }

  for (geo::TPCID const& tpcid: m_geo->Iterate<geo::TPCID>())
    {
      if(m_wireReadout->Nplanes(tpcid) > 2)
	{
	  cout<<myname<<"ERROR wrong number of readout planes\n";
	  return false;
	}
      //
      for(geo::PlaneGeo const& plane : m_wireReadout->Iterate<geo::PlaneGeo>(tpcid))
	{
	  unsigned nwires = plane.Nwires();
	  if( nwires % m_LemViewChans != 0 )
	    {
	      cout<<myname<<"ERROR problem with number of channels per view\n";
	      return false;
	    }
	}
    }
  
  return true;
}


//
// get view charge
double util::CrpGainService::viewCharge( const sim::SimChannel* psc, unsigned itck ) const
{
  const string myname = "util::CrpGainService::viewCharge: ";
  
  double q = psc->Charge(itck);
  if(q <= 1.0E-3) return 0; //if 0 nothing to do -> return 0

  // default result: divide the charge equally between collection views
  q *= (0.5 * m_CrpDefGain);
  
  // use default gain value given if no other information is provided
  if( m_UseDefGain ) return q;

  //
  // otherwise ... 

  std::vector< geo::WireID > wids = m_wireReadout->ChannelToWire( psc->Channel() );
  geo::WireID wid  = wids[0];
  
  // get tpc
  geo::TPCID const& tpcid = wid;

  // this plane
  const geo::PlaneGeo& pthis = m_wireReadout->Plane(wid);
  // wire number in this plane
  int wire   = (int)(wid.Wire);

  // other plane
  unsigned widother = 0;
  if(wid.Plane == 0 ) widother = 1;
  const geo::PlaneGeo& pother = m_wireReadout->Plane({tpcid, widother});
  
  // get drift axis
  auto const [axis, _] = m_geo->TPC(wid).DriftAxisWithSign();
  int tcoord = -1;
  if( pthis.View() == geo::kZ )
    {
      if( axis == geo::Coordinate::X ) tcoord = 1;
      else if( axis == geo::Coordinate::Y ) tcoord = 0;
    }
  else if( pthis.View() == geo::kX || pthis.View() == geo::kY )
    {
      tcoord = 2;
    }

  if( m_LogLevel >= 3 )
    {
      cout<<myname<<"chan "<<psc->Channel()
	  <<" plane  "<<wid.Plane
	  <<" wire "<<wire
	  <<" view "<<pthis.View()
	  <<" viewother "<<pother.View()
	  <<" tcoord "<<tcoord<<endl;
    }

  if( tcoord < 0 || (tcoord == 2 && pother.View() != geo::kZ) )
    {
      cout<<myname<<"WARNING cannot figure out the coordinate system\n";
      // return the default value
      return q;
    }

  
  // get IDEs for this tick
  std::vector<sim::IDE> IDEs = psc->TrackIDsAndEnergies( itck, itck );
  if( IDEs.empty() )
    {
      cout<<myname<<"WARNING could not get IDEs for tick "<<itck<<endl;
      return q;
    }
  
  unsigned tpcnum = wid.TPC;
  
  //
  double qsum = 0.0;
  for(auto &ide: IDEs)
    {

      // get the wire number in the other view for this position
      int wother = pother.WireCoordinate( geo::Point_t{ide.x, ide.y, ide.z} );
      if( wother < 0 || wother >= (int)pother.Nwires() ) 
	{
	  cout<<myname<<"WARNING the wire number appeares to be incorrect "<<wother<<"\n";
	  continue;
	}
      
      double G = 0;
      if( tcoord < 2 ) // we are in view kZ
	{
          G = getCrpGain( tpcnum, wire, wother );
	}
      else // we are in view kX or kY
	{
          G = getCrpGain( tpcnum, wother, wire );
	}
      // the charge is divided equially between collectiong views
      // so the effective gain per view is 1/2 of the total effective CRP gain
      qsum += (0.5 * G) * ide.numElectrons;
    }
  
  //if( q != qsum )
  //cout<<q<<" "<<qsum<<endl;
  
  return qsum;
}

//
//
double util::CrpGainService::crpGain( geo::Point_t const &pos ) const
{
  const string myname = "util::CrpGainService::crpGain: ";

  //geo::Point_t pos(x,y,z);
  if( m_UseDefGain ) return crpDefaultGain();
  
  // get tpc
  geo::TPCGeo const *tpcgeo = m_geo->PositionToTPCptr( pos );
  if( !tpcgeo )
    {
      cout << myname << "WARNING cannot find the point in a TPC" << endl;
      return crpDefaultGain();
    }
  
  auto const& tpcid = tpcgeo->ID();

  // get the planes: should be only 2 (see checkGeoConfig)
  auto const num_planes = m_wireReadout->Nplanes(tpcid);
  const geo::PlaneGeo& pfirst = m_wireReadout->Plane({tpcid, 0});
  const geo::PlaneGeo& plast  = m_wireReadout->Plane({tpcid, num_planes - 1});
  
  //pthis.View() == geo::kX || pthis.View() == geo::kY
  int ch[2] = {-1, -1};
  
  if( pfirst.View() == geo::kZ )
    {
      ch[0] = pfirst.WireCoordinate( pos );
      ch[1] = plast.WireCoordinate( pos );

      if( ch[0] < 0 || ch[0] >=  (int)pfirst.Nwires() ) 
	{
	  cout<<myname<<"WARNING the wire number appeares to be incorrect " << endl;
	  return crpDefaultGain();
	}

      if( ch[1] < 0 || ch[1] >=  (int)plast.Nwires() ) 
	{
	  cout<<myname<<"WARNING the wire number appeares to be incorrect " << endl;
	  return crpDefaultGain();
	}
    }
  else if( plast.View() == geo::kZ )
    {
      ch[0] = plast.WireCoordinate( pos );
      ch[1] = pfirst.WireCoordinate( pos );

      if( ch[0] < 0 || ch[0] >=  (int)plast.Nwires() ) 
	{
	  cout<<myname<<"WARNING the wire number appeares to be incorrect " << endl;
	  return crpDefaultGain();
	}
      
      if( ch[1] < 0 || ch[1] >=  (int)pfirst.Nwires() ) 
	{
	  cout<<myname<<"WARNING the wire number appeares to be incorrect " << endl;
	  return crpDefaultGain();
	}
    }
  else
    {
      cout<<myname<<"WARNING cannot figure out the coordinate system\n";
      return crpDefaultGain();
    }
  
  //
  return getCrpGain( tpcgeo->ID().TPC, ch[0], ch[1] );  
}


//
//
int util::CrpGainService::getLemId( unsigned crp, int chx, int chy ) const
{
  const string myname = "util::CrpGainService::getLemId: ";
  int iX = chx / m_LemViewChans;
  int iY = chy / m_LemViewChans;
  
  int id = iY + iX * m_CrpNLemPerSide;
  if( id >= (int)m_CrpNLem )
    {
      cout<<myname<<"WARNING LEM ID exceeds the number of declared LEMs: "
	  <<chx<<" "<<chy<<" "<<iX<<" "<<iY<<" "<<id<<endl;
      return -1;
    }
  
  // add offset corresponding to the CRP num
  // which should match the TPCID in geo !
  id += (int)crp * m_CrpNLem;
  
  return id;
}


//
//
double util::CrpGainService::getCrpGain( unsigned crp, int chx, int chy) const
{
  // transmission factor (dead areas)
  double T = getLemTransparency( chx, chy );

  // gain for this LEM per view
  double G = getLemGain( getLemId( crp, chx, chy ) );

  return G*T;
}

//
//
double util::CrpGainService::getLemTransparency( int chx, int chy ) const
{
  const string myname = "util::CrpGainService::getLemTransparency: ";
  
  // if no map is defined return 1 -> fully transparent
  if( !m_plemeff ) return 1.0;
  
  // 
  if( chx < 0 || chy < 0 ) return 0;
  
  // query transparency map
  unsigned iX  = (unsigned)chx % m_LemViewChans;
  unsigned iY  = (unsigned)chy % m_LemViewChans;
  unsigned idx = iX + iY * m_LemViewChans;
  if( idx >= m_plemeff->size() ){
    cout<< myname << "WARNING the index of LEM transmission map is too large"<<endl;
  }

  return m_plemeff->value(idx, 0.0);
}

// 
// variable gain map for LEM is not implemented yet
// so the return is the default gain value
double util::CrpGainService::getLemGain( int lemid ) const
{
  // wrong Id return default gain value
  if( lemid < 0 ) return m_CrpDefGain;
  
  // TO DO add variable gain map
  return m_CrpDefGain;
}

//
//
//
void util::CrpGainService::dumpLemEffMap(int nlems) const
{
  const string myname = "util::CrpGainService::dumpLemEffMap: ";
  cout<<myname<<"Dump LEM efficiecy map for a block "<<nlems<<" x "<<nlems<<"\n";
  //
  //if( m_plemeff == nullptr ) return;
  
  TFile *fout = TFile::Open("dumplemeffmap.root", "RECREATE");
  TH2F *hist  = new TH2F( "lemeffmap", "lemeffmap", 
			  nlems*m_LemViewChans, 0, nlems*m_LemViewChans,
			  nlems*m_LemViewChans, 0, nlems*m_LemViewChans );
  
  for( int iy = 0; iy<hist->GetNbinsY(); ++iy){
    for( int ix = 0; ix<hist->GetNbinsX(); ++ix){
      hist->SetBinContent(ix+1, iy+1, getLemTransparency( ix, iy ));
    }
  }
  hist->Write();
  fout->Close();
}

namespace util{
  DEFINE_ART_SERVICE(CrpGainService)
}
