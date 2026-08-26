#include "art/Framework/Services/Registry/ServiceRegistry.h"
#include "fhiclcpp/make_ParameterSet.h"
#include "fhiclcpp/intermediate_table.h"

#include "dunecore/ArtSupport/ArtServiceHelper.h"

#include <memory>

namespace {
  // The single ArtServiceHelper instance.  It is intentionally *not* a
  // function-local static with program lifetime: services such as
  // TFileService write ROOT files in their destructors, which requires
  // a live ROOT/Cling interpreter.  Destroying the services at program
  // exit is unsafe because the interpreter's own static state may
  // already have been torn down (unspecified static destruction order
  // across translation units/shared libraries).  Holding the instance
  // here lets callers destroy it deterministically via
  // ArtServiceHelper::unload_services() while ROOT is still alive.
  std::unique_ptr<ArtServiceHelper>& helper_instance()
  {
    static std::unique_ptr<ArtServiceHelper> instance;
    return instance;
  }
}

ArtServiceHelper::ArtServiceHelper(fhicl::ParameterSet&& pset) :
  activityRegistry_{},
  sharedResources_{},
  servicesManager_{std::move(pset), activityRegistry_, sharedResources_}
{
  servicesManager_.forceCreation();
}

void ArtServiceHelper::load_services(std::string const& config)
{
  std::istringstream iss{config};
  load_services(iss);
}

void ArtServiceHelper::load_services(std::istream& config)
{
  cet::filepath_lookup lookup{"FHICL_FILE_PATH"};
  load_services(fhicl::ParameterSet::make
                (fhicl::parse_document(config, lookup)));
}

void ArtServiceHelper::load_services(std::string const& filename, FileOnPath_t)
{
  cet::filepath_lookup lookup{"FHICL_FILE_PATH"};
  load_services(fhicl::ParameterSet::make(filename, lookup));
}

void ArtServiceHelper::load_services(fhicl::ParameterSet const& pset)
{
  // Make sure each service has a value for the "service_type" parameter
  fhicl::ParameterSet post_processed_pset;
  auto const& input = pset.has_key("services") ? pset.get<fhicl::ParameterSet>("services") : pset;
  auto const service_names = input.get_pset_names();
  for (auto const& service_name : service_names) {
    auto service_pset = input.get<fhicl::ParameterSet>(service_name);
    service_pset.put("service_type", service_name);
    post_processed_pset.put(service_name, service_pset);
  }

  // (Re)create the single helper instance.  Using a member function
  // here lets us call the private constructor.  Ownership is held by a
  // namespace-scope unique_ptr so the services can be destroyed
  // deterministically via unload_services() (see the note above).
  auto& instance = helper_instance();
  instance.reset(new ArtServiceHelper{std::move(post_processed_pset)});
}

void ArtServiceHelper::unload_services()
{
  helper_instance().reset();
}
