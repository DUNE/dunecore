// ToolRedirector.h
//
// Interface for a tool that returns a string that is typically a tool
// name or a bracket-delimited fcl configuration string for a tool.
// It is constructed from a fcl parameter set and throws an exception
// if the boolean field "tool_redirector" is not present.
// This the tool manager will redirect any request whose fcl parameter
// set has the value true for this field.
// Redirect meants to use the parameter set to construct a tool of
// type ToolRedirector and then use the name returned by getName() to
// construct the requested tool.

#ifndef ToolRedirector_H
#define ToolRedirector_H

#include "fhiclcpp/ParameterSet.h"
#include <string>
#include <exception>

class ToolRedirector {

public:

  // Return the name of the redirection key.
  static const char* key() { return "tool_redirector"; }

  // Check if a parameter set has the boolean key tool_redirector.
  static bool hasRedirection(const fhicl::ParameterSet& ps) noexcept;

  // Return true if the parameter set has the redirection key and
  // it ha the value true.
  static bool isRedirecting(const fhicl::ParameterSet& ps) noexcept;


public:

  using Name = std::string;

  // Ctor.
  // We check the fcl parameter tool_redirector is present but p[lace
  // no requirements on the type of data it references.
  ToolRedirector(const fhicl::ParameterSet& ps);

  // Dtor.
  virtual ~ToolRedirector();

  // Return the redirected name.
  virtual Name getName() const =0;

public:

  // Exception returned if the tool_redirector key is missing.
  class FhiclException : public std::exception {
    public:
    FhiclException(std::string msg);
    const char* what() const noexcept;
    private:
    std::string m_msg;
  };

};

#endif
