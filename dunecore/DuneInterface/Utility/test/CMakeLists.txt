# dunecore/dunecore/DuneInterface/Utility/test/CMakeLists.txt

# David Adams
# December 2022

# Build test for each component.

include(CetTest)

cet_test(test_DuneContextSelector SOURCES test_DuneContextSelector.cxx
)

cet_enable_asserts()
