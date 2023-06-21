// TextIndexMapTool.h
//
// David Adams
// May 2023
//
// Tool to read an index map from a text file.
// File format is one line per map entry with fields on each line
// separated by FieldSeparators numbered starting with 0.
// The field at index ValueIndex is mapped to the field at index IndexIndex.
//
// Lines beginning with # are skipped.
// Line splitting is done with StringManipulator::split with fullSplit=false.
// File conversion is done with stoi.
//
// The file name is FileName converted with TSystem::ExpandPathName,
// i.e. ~ and $XXX are resolved.
//
// Parameters:
//   LogLevel - Message logging level:
//              0: none
//              1: show config
//              2: check for duplicates
//          FileName: Name of the file
//   FieldSeparators: String holding the field separators. Blank --> " ".
//        IndexIndex: Index of index field.
//        ValueIndex: Index of value field.
//      DefaultValue: Value returned for any unmapped index.

#ifndef TextIndexMapTool_H
#define TextIndexMapTool_H

#include "art/Utilities/ToolMacros.h"
#include "dunecore/DuneInterface/Tool/IndexMapTool.h"
#include <vector>
#include <map>

class TextIndexMapTool : public IndexMapTool {

public:

  using Index = IndexMapTool::Index;

  // Ctor.
  TextIndexMapTool(fhicl::ParameterSet const& ps);

  // Dtor.
  ~TextIndexMapTool() override =default;

  // Return the channel status.
  Index get(Index icha) const override;

private:

  using String = std::string;
  using IndexVector = std::vector<Index>;
  using IndexMap = std::map<Index, Index>;

  // Parameters.
  Index m_LogLevel;
  String m_FileName;
  String m_FieldSeparators;
  Index m_IndexIndex;
  Index m_ValueIndex;
  Index m_DefaultValue;

  // Derived data.
  IndexMap m_map;

};


#endif
