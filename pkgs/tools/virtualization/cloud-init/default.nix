{ lib, pythonPackages, fetchurl }:

let version = "0.7.6";

in pythonPackages.buildPythonPackage rec {
  name = "cloud-init-0.7.6";
  namePrefix = "";

  src = fetchurl {
    url = "https://launchpad.net/cloud-init/trunk/${version}/+download/cloud-init-${version}.tar.gz";
    sha256 = "1mry5zdkfaq952kn1i06wiggc66cqgfp6qgnlpk0mr7nnwpd53wy";
  };

  preBuild = ''
    patchShebangs ./tools

    substituteInPlace setup.py \
      --replace /usr $out \
      --replace /etc $out/etc \
      --replace /lib/systemd $out/lib/systemd \
    '';

  pythonPath = with pythonPackages; [ cheetah jinja2 prettytable
    oauth pyserial configobj pyyaml argparse requests jsonpatch ];

  setupPyInstallFlags = ["--init-system systemd"];

  meta = {
    homepage = http://cloudinit.readthedocs.org;
    description = "provides configuration and customization of cloud instance";
    maintainers = [ lib.maintainers.madjar ];
    platforms = lib.platforms.all;
  };
}
