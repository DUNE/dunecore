 // ToolBasedChannelStatusService.cxx

#include "ToolBasedChannelStatusService.h"

ToolBasedChannelStatusService::ToolBasedChannelStatusService(const fhicl::ParameterSet& ps)
: m_provider(new ToolBasedChannelStatus(ps)) {
}
