#!/usr/bin/env python3
"""Synthetic PAL/USA/Japan selection and app-update survival checks (Linux host).

No game disc or console connection is needed. Uses this port's real ISO/CISO
reader and AddressSanitizer/UndefinedBehaviorSanitizer. CXX may override clang++.
"""
from pathlib import Path
import os
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='dusklight-storage-') as directory:
    work=Path(directory)
    executable=work/'storage-test'
    subprocess.run([os.environ.get('CXX','clang++'),'-std=c++20','-O1','-g',
        '-fsanitize=address,undefined','-fno-omit-frame-pointer',
        '-I',str(root/'ps5/src'),'-I',str(root/'ps5/nod/include'),
        str(root/'ps5/src/ps5_storage.cpp'),str(root/'ps5/nod/nod.cpp'),
        str(root/'ps5/tests/storage_test.cpp'),'-o',str(executable)],check=True)
    subprocess.run([str(executable),str(work/'fixtures')],check=True)
