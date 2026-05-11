# README_Win

This document specifies instructions to build QuantLib Python add-in on Windows with MSVC (Visual Studio).

## Prerequisites

We assume the following folder structure.

```
QuantLib/...
QuantLib-SWIG/...
```

Make sure Boost is available and configured in Visual Studio.

Compile QuantLib using Visual Studio in configuration *Release*.

## Code Generation via SWIG

SWIG is an executable to generate glue-code between C++ and Python. A pre-build Windows version is available [here](https://www.swig.org/download.html).

QuantLib code generation is executed as follows:

```
swig.exe -python -c++ -outdir src\QuantLib -o src\QuantLib\quantlib_wrap.cpp ..\SWIG\quantlib.i
```

Note: make sure `swig.exe` is available in your `PATH` variable or use the full path to the executable instead, e.g. `C:\swig\swigwin-4.2.1\swig.exe`.

If execute successfully, SWIG generates the files

```
src\QuantLib\quantLib_wrap.cpp
src\QuantLib\QuantLib.py
```

## QuantLib Include Path

Setuptools requires the path to QuantLib as environment variable.

```
set QL_DIR=..\..\QuantLib
```

## Boost Include Path

Setuptools requires the path to Boost as environment variable. Use e.g.

```
set INCLUDE=C:\boost\boost_1_81_0-64-msvc-14.2
```

Note: Make sure to use the same Boost version as used for compiling QuantLib.

## Build Python Add-in

Python add-in is build via

```
python setup.py build
```

Install it in the *current* Python environment via

```
python setup.py install
```

Test installation in Python via

```
import QuantLib as ql
ql.__version__
```

This should output the version of the custom-build QuantLib library.
