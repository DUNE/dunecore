// DuneContextToolRedirector.h
//
// David Adams
// January 2023
//
// Interface for a tool that uses DUNE context to select a name.
// Typically that name is a tool name or a brace-delimited string:
// {...} that contains the fcl description of a tool.
// Note this is a ToolRedirector and concrete implementations are
// required to provide a fcl param with key "tool_redirector" so
// the tool manager recognizes them as such.

#ifndef DuneContextToolRedirector_H
#define DuneContextToolRedirector_H

#include "dunecore/DuneInterface/Data/DuneContext.h"
#include "dunecore/ArtSupport/ToolRedirector.h"
#include <string>

class DuneContextToolRedirector : public ToolRedirector {

public:

  using Name = std::string;
  using Context = DuneContext;

  // Ctor.
  DuneContextToolRedirector(fhicl::ParameterSet const& ps);

  // Dtor.
  virtual ~DuneContextToolRedirector() {}

  // Return name based on context.
  // Pointer is passed so implementation can cast and can handle
  // missing context (null pointer).
  virtual Name getNameInContext(const Context* pcon) const =0;

  // Get context from the context manager and call the above method.
  // This is used by the tool manager.
  virtual Name getName() const;

};

#endif
