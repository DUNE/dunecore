// DuneToolManager.h
//
// David Adams
// April 2017
//
// This class provides access to DUNE tools. It is a quick and dirty
// implementation of a tool manager intended for use until we get something
// better from larsoft or art.
//
// Tools are typically obtained from the primary instance of this class which
// is accessed via DuneToolManager::instance(). The first call to this method
// locates the top-level fcl file and loads all the tool definitions. Tools
// are constructed when getPrivate or getPublic is called.
//
// This first call typically occurs during job initialization. The fcl file
// name may be provided or, if not, it is obtained from the command line
// (option -c). If that is also absent, the default tools_dune.fcl is used.
//
// It is also possible to construct additional tool managers from fcl file names.
// Tool instances are not shared between different tool managers. These
// managers might be assigned to different threads or used to locate tools
// that are not defined in the primary fcl file.
//
// [January 2023] If the returned tool is a tool redirector, than call it to
// retrieve the final tool.

#ifndef DuneToolManager_H
#define DuneToolManager_H

#include <string>
#include <vector>
#include <memory>
#include <iostream>
#include "fhiclcpp/ParameterSet.h"
#include "art/Utilities/make_tool.h"
#include "dunecore/ArtSupport/ToolRedirector.h"

class DuneToolManager {

public:  // Type aliases and subclasses.

  using Name = std::string;
  using NameVector = std::vector<Name>;
  using NameSet = std::set<Name>;

  class SharedToolEntry {
  public:
    virtual ~SharedToolEntry() =default;
  };

  template<class T>
  class TSharedToolEntry : public SharedToolEntry {
  public:
    using ToolPtr = std::unique_ptr<T>;
    TSharedToolEntry(ToolPtr& a_ptr) : m_ptr(std::move(a_ptr)) { }
    ~TSharedToolEntry() =default;
    T* get() { return m_ptr.get(); }
  private:
    ToolPtr m_ptr;
  };

  using SharedToolPtr = std::unique_ptr<SharedToolEntry>;
  using SharedToolMap = std::map<Name, SharedToolPtr>;

public:

  // Set/retrieve the primary fcl filename.
  // The name is assigned from setName the first time this method is called.
  // If setName is blank and the tool manager is not yet set, an attempt
  // is made to find the fcl name on the command line following "-c".
  // If a different name is provided in later calls, it is ignored and a
  // warning message is broadcast.
  static Name fclFilename(Name setName ="", int dbg =1);

  // Return the primary instance of this class.
  // The fcl file returned by fclFilename is read the first time this is called.
  static DuneToolManager* instance(Name fclname ="", int dbg =1);

  // Display a help message.
  static void help();

  // Ctor from FCL file name.
  explicit DuneToolManager(Name fclname);

  // Return a private (not shared) copy of a tool.
  template<class T>
  std::unique_ptr<T> getPrivate(Name name, bool doRedirect =true) {
    Name myname = "DuneToolManager::getPrivate: ";
    fhicl::ParameterSet psTool;
    if ( name.size() == 0 ) {
      std::cout << myname << "ERROR: Tool name is blank" << std::endl;
      return nullptr;
    } else if ( name[0] == '{' ) {    // Name is a tool cfg string
      makeParameterSet(name, psTool);
    } else if ( std::find(m_toolNames.begin(), m_toolNames.end(), name) != m_toolNames.end() ) {
      psTool = m_pstools.get<fhicl::ParameterSet>(name);
    } else {
      std::cout << myname << "ERROR: No such tool name: " << name << std::endl;
      return nullptr;
    }
    if ( doRedirect && ToolRedirector::isRedirecting(psTool) ) {
      std::unique_ptr<ToolRedirector> prd = art::make_tool<ToolRedirector>(psTool);
      Name rname = prd->getName();
      std::unique_ptr<T> ptoo = getPrivate<T>(rname);
      if ( ! ptoo ) {
        std::cout << myname << "ERROR: Redirection with name " << rname << " failed." << std::endl;
      }
      return ptoo;
    }
    return art::make_tool<T>(psTool);
  }

  // Return a shared tool.
  template<class T>
  T* getShared(Name name, bool doRedirect =true) {
    Name myname = "DuneToolManager::getShared: ";
    SharedToolMap::iterator itoo = m_sharedTools.find(name);
    if ( itoo != m_sharedTools.end() ) {
      SharedToolPtr& pent = itoo->second;
      if ( pent ) {
        if ( isRedirecting(name) ) {
          TSharedToolEntry<ToolRedirector>* prdent = dynamic_cast<TSharedToolEntry<ToolRedirector>*>(pent.get());
          ToolRedirector* prd = prdent->get();
          if ( prd == nullptr ) {
            std::cout << myname << "ERROR: Null redirector with name " << name << "." << std::endl;
            return nullptr;
          }
          Name rname = prd->getName();
          return getShared<T>(rname);
        } else {
          TSharedToolEntry<T>* ptent = dynamic_cast<TSharedToolEntry<T>*>(pent.get());
          if ( pent != nullptr ) return ptent->get();
        }
      }
      std::cout << myname << "ERROR: Null tool pointer for " << name << "." << std::endl;
      return nullptr;
    }
    if ( std::find(m_toolNames.begin(), m_toolNames.end(), name) != m_toolNames.end() ) {
      fhicl::ParameterSet psTool = m_pstools.get<fhicl::ParameterSet>(name);
      if ( doRedirect && ToolRedirector::isRedirecting(psTool) ) {
        std::unique_ptr<ToolRedirector> prd = art::make_tool<ToolRedirector>(psTool);
        m_sharedTools.emplace(name, new TSharedToolEntry<ToolRedirector>(prd));
        m_redirectingNames.insert(name);
      } else {
        std::unique_ptr<T> ptoo = art::make_tool<T>(psTool);
        m_sharedTools.emplace(name, new TSharedToolEntry<T>(ptoo));
      }
      // Now tool is known. Repeat call to fetch the tool.
      return getShared<T>(name, doRedirect);
    } else {
      std::cout << myname << "ERROR: No such tool name: " << name << std::endl;
      return nullptr;
    }
  }

  // Delete a shared tool.
  // Returns 0 if tool is deleted.
  // These tools are otherwise deleted when the tool manager is deleted. This method
  // provides the opportunity to ensure this destruction occurs before general C++
  // closeout, e.g. before Root objects begin to dissappear.
  int deleteShared(Name name);

  // Return the list of available tool names.
  const NameVector& toolNames() const;

  // Return if name references a redirecting tool.
  bool isRedirecting(Name name) const;

  // Display the list of available tools.
  void print() const;

private:

  Name m_fclname;
  fhicl::ParameterSet m_pstools;
  NameVector m_toolNames;
  SharedToolMap m_sharedTools;
  NameSet m_redirectingNames;

  // Convert a string into a paramter set.
  int makeParameterSet(Name scfg, fhicl::ParameterSet& ps);
  
};

#endif
