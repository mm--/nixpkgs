{ stdenv, buildPythonApplication, fetchFromGitHub, isPyPy, lib
, defusedxml, future, psutil, setuptools
# Optional dependencies:
, bottle, pysnmp
, hddtemp
, netifaces # IP module
, py-cpuinfo
}:

buildPythonApplication rec {
  pname = "glances";
  version = "3.2.3";
  disabled = isPyPy;

  src = fetchFromGitHub {
    owner = "nicolargo";
    repo = "glances";
    rev = "v${version}";
    sha256 = "1nc8bdzzrzaircq3myd32w6arpy2prn739886cq2h47cpinxmvpr";
  };

  # Some tests fail in the sandbox (they e.g. require access to /sys/class/power_supply):
  patches = lib.optional (doCheck && stdenv.isLinux) ./skip-failing-tests.patch;

  # On Darwin this package segfaults due to mismatch of pure and impure
  # CoreFoundation. This issues was solved for binaries but for interpreted
  # scripts a workaround below is still required.
  # Relevant: https://github.com/NixOS/nixpkgs/issues/24693
  makeWrapperArgs = lib.optionals stdenv.isDarwin [
    "--set" "DYLD_FRAMEWORK_PATH" "/System/Library/Frameworks"
  ];

  doCheck = true;
  preCheck = lib.optional stdenv.isDarwin ''
    export DYLD_FRAMEWORK_PATH=/System/Library/Frameworks
  '';

  propagatedBuildInputs = [
    bottle
    defusedxml
    future
    netifaces
    psutil
    pysnmp
    setuptools
    py-cpuinfo
  ] ++ lib.optional stdenv.isLinux hddtemp;

  meta = with lib; {
    homepage = "https://nicolargo.github.io/glances/";
    description = "Cross-platform curses-based monitoring tool";
    changelog = "https://github.com/nicolargo/glances/blob/v${version}/NEWS.rst";
    license = licenses.lgpl3Only;
    maintainers = with maintainers; [ jonringer primeos koral ];
  };
}
