# ICEBERG, no wires
perl generate_iceberg_v2.pl -o iceberg_v2_nowires.gdml -w=0
perl make_gdml.pl -i iceberg_v2_nowires.gdml -o iceberg_v2_nowires.gdml
# full geometry, with wires
perl generate_iceberg_v2.pl -o iceberg_v2.gdml
perl make_gdml.pl -i iceberg_v2.gdml -o iceberg_v2.gdml
