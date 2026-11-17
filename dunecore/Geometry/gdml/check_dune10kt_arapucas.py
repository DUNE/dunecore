#!/usr/bin/env python3
"""Check generated v6 GDML: python3 check_dune10kt_arapucas.py FILE [FILE ...].

Accepts wired and nowires full, 1x2x2 and 1x2x6 geometries. Checks optical
counts, inward orientation, window containment and the opaque lateral back.
"""
import math
import sys
import xml.etree.ElementTree as ET
from collections import Counter


def check(path):
    root = ET.parse(path).getroot()
    solids = {e.attrib['name']: e for e in root.find('solids')}
    volumes = {e.attrib['name']: e for e in root.find('structure')}
    definitions = {e.attrib['name']: e for e in root.find('define')}
    placements = {e.find('volumeref').attrib['ref']: e
                  for e in volumes['volCryostat'].findall('physvol')}
    frames = {n: e for n, e in placements.items() if n.startswith('volArapuca_')}
    windows = {n: e for n, e in placements.items() if n.startswith('volOpDetSensitive_')}
    assert len(frames) in (40, 120, 1500), len(frames)
    assert len(windows) == 4 * len(frames)
    xs = sorted({float(e.find('position').attrib['x']) for e in frames.values()})
    assert len(xs) == (3 if len(frames) == 1500 else 1)
    count = Counter()
    for name, frame in frames.items():
        fx, fy, fz = (float(frame.find('position').attrib[a]) for a in 'xyz')
        single = len(xs) == 3 and fx in (xs[0], xs[-1])
        wall = 'ArapucaSingleWalls' if single else 'ArapucaWalls'
        assert volumes[name].find('solidref').attrib['ref'] == wall
        rot = frame.find('rotationref').attrib['ref']
        direction = 1 if rot == 'rIdentity' else -1
        assert rot in ('rIdentity', 'rPlus180AboutY')
        if single:
            assert direction == (1 if fx == xs[0] else -1)
        cuts = []
        current = wall
        while current != 'ArapucaOut':
            subtraction = solids[current]
            pos = definitions[subtraction.find('positionref').attrib['ref']]
            box = solids[subtraction.find('second').attrib['ref']]
            cuts.append(([float(pos.attrib[a]) for a in 'xyz'],
                         [float(box.attrib[a]) / 2 for a in 'xyz']))
            current = subtraction.find('first').attrib['ref']
        assert len(cuts) == 4
        if single:
            # Cuts stop at the midplane: the entire negative-x back remains.
            assert all(math.isclose(c[0] - h[0], 0, abs_tol=1e-9) for c, h in cuts)
        for n in range(4):
            wn = name.replace('volArapuca_', 'volOpDetSensitive_') + f'-{n}'
            window = windows[wn]
            assert window.find('rotationref').attrib['ref'] == rot
            wx, wy, wz = (float(window.find('position').attrib[a]) for a in 'xyz')
            local = [direction * (wx - fx), wy - fy, direction * (wz - fz)]
            solid = volumes[wn].find('solidref').attrib['ref']
            assert solid == ('ArapucaSingleAcceptanceWindow' if single else 'ArapucaAcceptanceWindow')
            half = [float(solids[solid].attrib[a]) / 2 for a in 'xyz']
            assert math.isclose(local[0], 0.55 if single else 0, abs_tol=1e-9)
            assert math.isclose(local[1], 0, abs_tol=1e-9)
            assert any(all(abs(local[a] - c[a]) + half[a] <= h[a] + 1e-9
                           for a in range(3)) for c, h in cuts), (wn, local)
            assert all(abs(local[a]) + half[a] <= float(solids['ArapucaOut'].attrib['xyz'[a]]) / 2 + 1e-9
                       for a in range(3))
            count['single' if single else 'double'] += 1
    assert count['single'] == (4000 if len(xs) == 3 else 0)
    print(f'{path}: PASS ({dict(count)} sensitive windows)')


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    for path in sys.argv[1:]:
        check(path)
