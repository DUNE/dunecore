// ToolRedirector.h
//
// Interface for a utility or tool redirects to a tool by returning the
// name of configuration of that tool.
// This is used by the the tool manager to identify redirecting tools
// and should be the base of any tool that does so.

#ifndef ToolRedirector_H
#define ToolRedirector_H

#include <string>

class ToolRedirector {

public:

  using Name = std::string;

  // Dtor.
  virtual ~ToolRedirector() {}

  // Return the redirected name.
  virtual Name getName() const =0;

};

#endif
