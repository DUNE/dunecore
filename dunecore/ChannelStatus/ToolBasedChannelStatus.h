// ToolBasedChannelStatus.h
//
// David Adams
// January 2023
//
// Channel status provider that takse the lists of good, band and noisy
// channel from an index map tool.
//
// Parameters:
//   LogLevel: 0 for silent, 1 for init, ...
//   NChannel: Valid channels are {0, 1, ..., NChannel-1}
//   ToolName: Name of config of the underlying tool (IndexMapTool)

#ifndef ToolBasedChannelStatus_H
#define ToolBasedChannelStatus_H

#include "larcoreobj/SimpleTypesAndConstants/RawTypes.h" // raw::ChannelID_t
#include "larevt/CalibrationDBI/Interface/ChannelStatusProvider.h"
#include <string>
#include <memory> // std::unique_ptr<>

// Utility libraries
namespace fhicl {
  class ParameterSet;
}
class IndexMapTool;

class ToolBasedChannelStatus : public lariov::ChannelStatusProvider {

public:

  using Index = unsigned int;
  using Name = std::string;
  using ChannelID = raw::ChannelID_t;
  using ChannelSet = lariov::ChannelStatusProvider::ChannelSet_t;

  // Configuration
  explicit ToolBasedChannelStatus(fhicl::ParameterSet const& pset);

  // Return whether the specified channel is physical and connected to wire
  virtual bool IsPresent(ChannelID channel) const override;

  // Return whether the specified channel is physical and good
  virtual bool IsGood(ChannelID channel) const override;

  // Return whether the specified channel is bad in the current run
  virtual bool IsBad(ChannelID channel) const override;

  // Return whether the specified channel is noisy in the current run
  virtual bool IsNoisy(ChannelID channel) const override;

  // Returns a copy of set of good channel IDs for the current run
  virtual ChannelSet GoodChannels() const override;

  // Returns a copy of set of bad channel IDs for the current run
  virtual ChannelSet BadChannels() const override;

  // Returns a copy of set of noisy channel IDs for the current run
  virtual ChannelSet NoisyChannels() const override;

  // Returns the ID of the largest known channel
  ChannelID MaxChannel() const { return m_NChannel - 1; }

  // Returns the ID of the largest present channel
  ChannelID MaxChannelPresent() const { return MaxChannel(); }

public:  // Helpers

  // Return the index map tool.
  const IndexMapTool* indexMap() const;

  // Retrieve the index map status for a channel.
  Index indexMapStatus(const IndexMapTool* pimt, Index chan) const;

  // Convert index map status to that defined here.
  // No range check.
  bool statusIsGood(Index ista) const  { return !statusIsBad(ista) && !statusIsNoisy(ista); }
  bool statusIsBad(Index ista) const   { return ista == 1; }
  bool statusIsNoisy(Index ista) const { return ista == 2; }

  // Evaluate the status defined here from the index map and channel.
  // No range check.
  bool channelIsGood(const IndexMapTool* pimt, Index icha) const {
    return statusIsGood(indexMapStatus(pimt, icha));
  }
  bool channelIsBad(const IndexMapTool* pimt, Index icha) const {
    return statusIsBad(indexMapStatus(pimt, icha));
  }
  bool channelIsNoisy(const IndexMapTool* pimt, Index icha) const {
    return statusIsNoisy(indexMapStatus(pimt, icha));
  }

private:

  // Config data.
  Index m_LogLevel;
  Index m_NChannel;
  Name m_ToolName;

};

#endif
