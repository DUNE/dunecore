////////////////////////////////////////////////////////////////////////
// Class:       issue19191
// Plugin Type: analyzer (art v2_11_03)
// File:        issue19191_module.cc
//
// Generated at Thu Dec  6 12:02:48 2018 by Saba Sehrish using cetskelgen
// from cetlib version v3_03_01.
////////////////////////////////////////////////////////////////////////

#include "art/Framework/Core/EDAnalyzer.h"
#include "art/Framework/Core/ModuleMacros.h"
#include "art/Framework/Principal/fwd.h"
#include "fhiclcpp/fwd.h"

#include "larcore/Geometry/WireReadout.h"
#include "art/Framework/Services/Registry/ServiceHandle.h"

#include <cassert>

class issue19191 : public art::EDAnalyzer {
public:
  explicit issue19191(fhicl::ParameterSet const& p);

private:
  void analyze(art::Event const& e) override;
};

issue19191::issue19191(fhicl::ParameterSet const& p) : EDAnalyzer(p) {}

void issue19191::analyze(art::Event const&)
{
  auto const& wireReadout = art::ServiceHandle<geo::WireReadout>()->Get();
  auto channels = wireReadout.ChannelsInTPCs();
  assert(std::is_sorted(channels.begin(), channels.end()));
  assert(std::unique(channels.begin(), channels.end()) == channels.end());
  assert(std::adjacent_find(channels.begin(), channels.end()) == channels.end());
  assert(channels.size() == wireReadout.Nchannels());
}

DEFINE_ART_MODULE(issue19191)
