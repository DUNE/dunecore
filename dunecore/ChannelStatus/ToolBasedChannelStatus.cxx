// ToolBasedChannelStatus.cxx

#include "dunecore/ChannelStatus/ToolBasedChannelStatus.h"
#include "dunecore/ArtSupport/DuneToolManager.h"
#include "dunecore/DuneInterface/Tool/IndexMapTool.h"  // Interface for channel status tools
#include "larcoreobj/SimpleTypesAndConstants/RawTypes.h" // raw::isValidChannelID()
#include "cetlib/container_algorithms.h"
#include "cetlib_except/exception.h"
#include "fhiclcpp/ParameterSet.h"
#include <iterator> // std::inserter()
#include <utility>  // std::pair<>

using Index     = ToolBasedChannelStatus::Index;
using Name      = ToolBasedChannelStatus::Name;
using ChannelID = ToolBasedChannelStatus::ChannelID;

//**********************************************************************

ToolBasedChannelStatus::ToolBasedChannelStatus(fhicl::ParameterSet const& ps)
: m_LogLevel(ps.get<Index>("LogLevel")),
  m_NChannel(ps.get<Index>("NChannel")),
  m_ToolName(ps.get<Name>("ToolName")) { }

//**********************************************************************

bool ToolBasedChannelStatus::IsPresent(ChannelID channel) const {
  return channel <= m_NChannel;
}

//**********************************************************************

bool ToolBasedChannelStatus::IsGood(ChannelID channel) const {
  return channelIsGood(indexMap(), channel);
}

//**********************************************************************

bool ToolBasedChannelStatus::IsBad(ChannelID channel) const {
  return channelIsBad(indexMap(), channel);
}

//**********************************************************************

bool ToolBasedChannelStatus::IsNoisy(ChannelID channel) const {
  return channelIsNoisy(indexMap(), channel);
}

//**********************************************************************

ToolBasedChannelStatus::ChannelSet ToolBasedChannelStatus::GoodChannels() const {
  const IndexMapTool* pimt = indexMap();
  if ( pimt == nullptr ) return ChannelSet();
  ChannelSet chans;
  for ( Index icha=0; icha<=m_NChannel; ++icha ) {
    if ( channelIsGood(pimt, icha) ) chans.emplace_hint(chans.end(), icha);
  }
  return chans;
}

//**********************************************************************

ToolBasedChannelStatus::ChannelSet ToolBasedChannelStatus::BadChannels() const {
  const IndexMapTool* pimt = indexMap();
  if ( pimt == nullptr ) return ChannelSet();
  ChannelSet chans;
  for ( Index icha=0; icha<=m_NChannel; ++icha ) {
    if ( channelIsBad(pimt, icha) ) chans.emplace_hint(chans.end(), icha);
  }
  return chans;
}

//**********************************************************************

ToolBasedChannelStatus::ChannelSet ToolBasedChannelStatus::NoisyChannels() const {
  const IndexMapTool* pimt = indexMap();
  if ( pimt == nullptr ) return ChannelSet();
  ChannelSet chans;
  for ( Index icha=0; icha<=m_NChannel; ++icha ) {
    if ( channelIsNoisy(pimt, icha) ) chans.emplace_hint(chans.end(), icha);
  }
  return chans;
}

//**********************************************************************

const IndexMapTool* ToolBasedChannelStatus::indexMap() const {
  auto pimt = DuneToolManager::instance()->getShared<IndexMapTool>(m_ToolName);
  return pimt ? &*pimt : nullptr;
}

//**********************************************************************

Index ToolBasedChannelStatus::indexMapStatus(const IndexMapTool* pimt, Index chan) const {
  return pimt == nullptr ? -1 : pimt->get(chan);
}

//**********************************************************************
