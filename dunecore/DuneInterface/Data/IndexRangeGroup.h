// IndexRangeGroup.h
//
// David Adams
// April 2019
//
// Data structure that holds a named group of index ranges.
// The intention is that the name is unique (in some context)
// and can be used as an identifier and to construct other
// (e.g. histogram) names. The label is expected to be used
// to construct titles and labels for histograms, plots, etc.
//
// An arbitrarry number of labesl (op to four  in the ctor) may
// be assigned to each range.

#ifndef IndexRangeGroup_H
#define IndexRangeGroup_H

#include "dune/DuneInterface/Data/IndexRange.h"

class IndexRangeGroup {

public:

  using Index = unsigned int;
  using IndexVector = std::vector<Index>;
  using Name = std::string;
  using NameVector = std::vector<Name>;
  using RangeVector = std::vector<IndexRange>;

  // Data.
  Name name;         // Name
  NameVector labels; // Label
  RangeVector ranges;

  // Ctor for empty (invalid) group.
  IndexRangeGroup() { };

  // Ctor from name, labels and ranges.
  IndexRangeGroup(Name a_name, const NameVector& a_labels, const RangeVector& a_ranges)
  : name(a_name), labels(a_labels), ranges(a_ranges) { }

  // Ctor from name and ranges (no labels).
  IndexRangeGroup(Name a_name, const RangeVector& a_ranges)
  : name(a_name), ranges(a_ranges) { }

  // Ctor from a single range.
  explicit IndexRangeGroup(const IndexRange& ran)
  : name(ran.name), labels(ran.labels), ranges(1, ran) { }

  // Ctor from a string: sran0 or name,sran0, name,sran0,sran1, ...
  // where sranN is the string used to construct range N.
  explicit IndexRangeGroup(std::string sgrp) {
    std::string srem = sgrp;
    std::string::size_type ipos = srem.find(",");
    if ( ipos == std::string::npos ) {
      IndexRange ran(srem);
      *this = IndexRangeGroup(ran);
      return;
    }
    std::string nameTmp = srem.substr(0, ipos);
    while ( ipos != std::string::npos ) {
      srem = srem.substr(ipos+1);
      ipos = srem.find(",");
      std::string sran = srem.substr(0, ipos);
      IndexRange ran(sran);
      if ( ! ran.isValid() ) return;
      ranges.push_back(ran);
    }
  }

  // Length of the range.
  Index size() const { return ranges.size(); }

  // Ordering operator.
  bool operator<(const IndexRangeGroup& rhs) const { return name < rhs.name; }

  // Other helpers.
  bool isValid() const { return name.size() || ranges.size(); }
  IndexRange range(Index iran) const {
    if ( iran >= size() ) return IndexRange();
    return ranges[iran];
  }
  IndexRange range(Name name) const {
    for ( const IndexRange& ran : ranges ) {
      if ( ran.name == name ) return ran;
    }
    return IndexRange();
  }
  Name label(Index ilab =0) const {
    if ( ilab >= labels.size() ) return "";
    return labels[ilab];
  }

  void getIndices(IndexVector& idxs) const {
    for ( const IndexRange& ran : ranges ) {
      for ( Index ival=ran.begin; ival<ran.end; ++ival ) idxs.push_back(ival);
    }
  }
};

std::ostream& operator<<(std::ostream& lhs, const IndexRangeGroup& ir) {
  lhs << ir.name << ": ";
  if ( ir.size() == 0 ) {
    lhs << "<empty>";
  } else {
    lhs << "[";
    bool first = true;
    for ( const IndexRange& ran : ir.ranges ) {
      if ( first ) first = false;
      else lhs << ", ";
      lhs << ran.name;
    }
    lhs << "]";
    first = true;
    for ( std::string lab : ir.labels ) {
      if ( first ) first = false;
      else lhs << ",";
      lhs << " " << lab;
    }
  }
  return lhs;
}

#endif
