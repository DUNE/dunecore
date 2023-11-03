perl generate_protodunevd_v4_refactored.pl -o protodunevd_v4_nowires.xml -w=0 -s="parts"
perl make_refactored_gdml.pl -i protodunevd_v4_nowires.xml -o protodunevd_v4_refactored_nowires.gdml

rm protodunevd_v*_nowires.xml
rm protodune-vd*parts.gdml

perl generate_protodunevd_v4_refactored.pl -o protodunevd_v4.xml -w=1 -s="parts"
perl make_refactored_gdml.pl -i protodunevd_v4.xml -o protodunevd_v4_refactored.gdml

rm protodunevd_v*.xml
rm protodune-vd*parts.gdml



















