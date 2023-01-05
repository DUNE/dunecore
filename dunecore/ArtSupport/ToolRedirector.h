// ToolRedirector.h
//
// Interface for a utility or tool redirects to a tool by returning the
// name of configuration of that tool.
// This is used by the the tool manager to identify redirecting tools
// and should be the base of any tool that does so.
// Concrete implementations are are required to provide a fcl param
// with key "tool_redirector" so the tool manager can reconize them
// as such.

#ifndef ToolRedirector_H
#define ToolRedirector_H

#include "fhiclcpp/ParameterSet.h"
#include <string>
#include <exception>

class ToolRedirector {

public:

  using Name = std::string;

  // Ctor.
  // We check the fcl parameter tool_redirector is present but p[lace
  // no requirements on the type of data it references.
  ToolRedirector(fhicl::ParameterSet const& ps);

  // Dtor.
  virtual ~ToolRedirector();

  // Return the redirected name.
  virtual Name getName() const =0;

public:

  // Exception returned if the tool_redirector key is missing.
  class MissingKeyException : public std::exception {
    public:
    const char* what() const throw();
  };

};

#endif
