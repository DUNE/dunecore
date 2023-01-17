 // ToolBasedChannelStatusService.cxx

#include "dunecore/ChannelStatus/ToolBasedChannelStatusService.h"

ToolBasedChannelStatusService::ToolBasedChannelStatusService(fhicl::ParameterSet const& ps)
: m_provider(new ToolBasedChannelStatus(ps)) {
}
