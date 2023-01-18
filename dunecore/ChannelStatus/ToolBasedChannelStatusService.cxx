 // ToolBasedChannelStatusService.cxx

#include "dunecore/ChannelStatus/ToolBasedChannelStatusService.h"

ToolBasedChannelStatusService::ToolBasedChannelStatusService(const fhicl::ParameterSet& ps)
: m_provider(new ToolBasedChannelStatus(ps)) {
}
