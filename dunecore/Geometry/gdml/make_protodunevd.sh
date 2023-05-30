#3view_30deg 1x8x6 geometry v5, no wires, PDS ref
perl generate_protodunevd_v3_refactored.pl -o protodunevd_v3_nowires.xml -w=0 -s="parts"
perl make_refactored_gdml.pl -i protodunevd_v3_nowires.xml -o protodunevd_v3_refactored_nowires.gdml

rm protodunevd_v*_nowires.xml
rm protodune-vd*parts.gdml

perl generate_protodunevd_v3_refactored.pl -o protodunevd_v3_nowires.xml -w=1 -s="parts"
perl make_refactored_gdml.pl -i protodunevd_v3_nowires.xml -o protodunevd_v3_refactored.gdml

rm protodunevd_v*.xml
rm protodune-vd*parts.gdml



















