// DuneRunToolRedirector.h
//
// David Adams
// January 2023
//
// Tool that returns another tool name based on run number.
// The run number is obtained from DuneContextManager.
//
// The names are specified with a vector of range strings
//   RUN1:RUN2:NAME - NAME used for RUN1 <= run < RUN2
//   RUN1::NAME     - NAME returned for run >= RUN1
// If there are overlaps, later ranges replace the earlier ones.
//
// Parameters:
//   tool_redirector - Required to be bool in base ToolRedirector.
//   LogLevel - Message logging level (0=none, 1=ctor, 2=each call, ...)
//   DefaultName - Returned for run not in any range
//   Ranges - run-name ranges RUN1:RUN2:NAME

#ifndef DuneRunToolRedirector_H
#define DuneRunToolRedirector_H

#include "art/Utilities/ToolMacros.h"
#include "fhiclcpp/ParameterSet.h"
#include "dunecore/DuneCommon/Utility/DuneContextToolRedirector.h"
#include <string>
#include <vector>
#include <map>

class DuneRunToolRedirector : public DuneContextToolRedirector {

public:

  using Name = std::string;
  using NameVector = std::vector<Name>;
  using Index = unsigned int;
  using NameMap = std::map<Index, Name>;

public:

  // Ctor.
  DuneRunToolRedirector(fhicl::ParameterSet const& ps);

  // Dtor.
  ~DuneRunToolRedirector() override =default;

  // Return the name corresponding to a run number.
  Name getNameFromRun(Index run) const;

  // Implement the interface.
  // Extract run from context and return the corresponding name.
  Name getNameInContext(const Context* pcon) const;

private:

  // Parameters.
  Index m_LogLevel;
  Name m_DefaultName;
  NameVector m_Ranges;

  // Derived config.
  NameMap m_names;

};


#endif
