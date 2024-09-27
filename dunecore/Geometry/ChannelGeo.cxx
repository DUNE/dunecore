// ChannelGeo.cxx

#include "ChannelGeo.h"

#include "art/Framework/Services/Registry/ServiceHandle.h"
#include "larcore/Geometry/WireReadout.h"

//**********************************************************************

ChannelGeo::ChannelGeo(Index icha)
: ChannelGeo(icha,
             &art::ServiceHandle<geo::WireReadout>()->Get()) { }

//**********************************************************************

ChannelGeo::ChannelGeo(Index icha,
                       const geo::WireReadoutGeom* wireReadout)
: m_icha(icha), m_valid(false) {
  if ( icha >= wireReadout->Nchannels() ) return;
  m_valid = true;
  for ( geo::WireID wid : wireReadout->ChannelToWire(icha) ) {
    auto ends = wireReadout->WireEndPoints(wid);
    if ( ends.first.y() > ends.second.y() ) {
      auto firstPoint = ends.first;
      ends.first = ends.second;
      ends.second = firstPoint;
    }
    if ( m_ends.size() == 0 ) {
       m_bot = ends.first;
       m_top = ends.second;
    } else {
       if ( ends.first.y() < m_bot.y() ) m_bot = ends.first;
       if ( ends.second.y() > m_top.y() ) m_top = ends.second;
    }
    m_ends.push_back(ends);
  }
}

//**********************************************************************
