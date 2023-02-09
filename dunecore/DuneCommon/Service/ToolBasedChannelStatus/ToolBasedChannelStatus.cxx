// ToolBasedChannelStatus.cxx

#include "ToolBasedChannelStatus.h"
#include "dunecore/ArtSupport/DuneToolManager.h"
#include "dunecore/DuneInterface/Tool/IndexMapTool.h"  // Interface for channel status tools
#include "larcoreobj/SimpleTypesAndConstants/RawTypes.h" // raw::isValidChannelID()
#include "cetlib/container_algorithms.h"
#include "cetlib_except/exception.h"
#include "fhiclcpp/ParameterSet.h"
#include <iterator> // std::inserter()
#include <utility>  // std::pair<>
#include <iomanip>

using Index     = ToolBasedChannelStatus::Index;
using Name      = ToolBasedChannelStatus::Name;
using ChannelID = ToolBasedChannelStatus::ChannelID;
using std::cout;
using std::endl;

//**********************************************************************

ToolBasedChannelStatus::ToolBasedChannelStatus(fhicl::ParameterSet const& ps)
: m_LogLevel(ps.get<Index>("LogLevel")),
  m_NChannel(ps.get<Index>("NChannel")),
  m_ToolName(ps.get<Name>("ToolName")) {
  Name myname = "ToolBasedChannelStatus::ctor: ";
  bool havetool = indexMap() != nullptr;
  Name msg = havetool ? "INFO: Channel status tool is present." : "WARNING: Channel status tool not found.";
  if ( m_LogLevel ) {
    cout << myname << "LogLevel: " << m_LogLevel << endl;
    cout << myname << "NChannel: " << m_NChannel << endl;
    cout << myname << "ToolName: " << m_ToolName << endl;
    cout << myname << msg << endl;
  }
}

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

ToolBasedChannelStatus::Status_t
ToolBasedChannelStatus::Status(ChannelID chan) const {
  return indexMapStatus(indexMap(), chan);
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
  Name myname = "ToolBasedChannelStatus::indexMap: ";
  auto pimt = DuneToolManager::instance()->getShared<IndexMapTool>(m_ToolName);
  auto pimt_bare = pimt ? &*pimt : nullptr;
  if ( m_LogLevel >= 3 ) {
    cout << myname << "Fetched tool " << m_ToolName << " @ " << std::hex << pimt_bare << std::dec << endl;
  }
  return pimt_bare;
}

//**********************************************************************

Index ToolBasedChannelStatus::indexMapStatus(const IndexMapTool* pimt, Index chan) const {
  return pimt == nullptr ? -1 : pimt->get(chan);
}

//**********************************************************************
