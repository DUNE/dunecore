include_directories("${dunedaqdataformats_DIR}/../../../include")
include_directories("${dunedetdataformats_DIR}/../../../include")
include_directories("${nlohmann_json_DIR}/../../../include")
include_directories("${HighFive_DIR}/../../../include")
art_make(
	 LIBRARY_NAME dunedaqhdf5utils2
         LIB_LIBRARIES
	 cetlib::cetlib
         cetlib_except::cetlib_except
         messagefacility::MF_MessageLogger
         HDF5::HDF5
         pthread
         z
) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - deprecated: use art_make_library(), art_dictonary(), and cet_build_plugin() with explicit source lists and plugin base types

install_headers()
install_source()

add_subdirectory(hdf5filelayout)
add_subdirectory(hdf5sourceidmaps)
add_subdirectory(hdf5rawdatafile)

