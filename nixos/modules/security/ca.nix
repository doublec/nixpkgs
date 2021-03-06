{ config, lib, pkgs, ... }:

with lib;

let

  caBundle = pkgs.runCommand "ca-bundle.crt"
    { files =
        config.security.pki.certificateFiles ++
        [ (builtins.toFile "extra.crt" (concatStringsSep "\n" config.security.pki.certificates)) ];
     }
    ''
      cat $files > $out
    '';

in

{

  options = {

    security.pki.certificateFiles = mkOption {
      type = types.listOf types.path;
      default = [];
      example = literalExample "[ \"\${pkgs.cacert}/etc/ca-bundle.crt\" ]";
      description = ''
        A list of files containing trusted root certificates in PEM
        format. These are concatenated to form
        <filename>/etc/ssl/certs/ca-bundle.crt</filename>, which is
        used by many programs that use OpenSSL, such as
        <command>curl</command> and <command>git</command>.
      '';
    };

    security.pki.certificates = mkOption {
      type = types.listOf types.string;
      default = [];
      example = singleton ''
        NixOS.org
        =========
        -----BEGIN CERTIFICATE-----
        MIIGUDCCBTigAwIBAgIDD8KWMA0GCSqGSIb3DQEBBQUAMIGMMQswCQYDVQQGEwJJ
        TDEWMBQGA1UEChMNU3RhcnRDb20gTHRkLjErMCkGA1UECxMiU2VjdXJlIERpZ2l0
        ...
        -----END CERTIFICATE-----
      '';
      description = ''
        A list of trusted root certificates in PEM format.
      '';
    };

  };

  config = {

    security.pki.certificateFiles = [ "${pkgs.cacert}/etc/ca-bundle.crt" ];

    # NixOS canonical location + Debian/Ubuntu/Arch/Gentoo compatibility.
    environment.etc."ssl/certs/ca-certificates.crt".source = caBundle;

    # Old NixOS compatibility.
    environment.etc."ssl/certs/ca-bundle.crt".source = caBundle;

    # CentOS/Fedora compatibility.
    environment.etc."pki/tls/certs/ca-bundle.crt".source = caBundle;

    environment.sessionVariables =
      { SSL_CERT_FILE          = "/etc/ssl/certs/ca-certificates.crt";
        # FIXME: unneeded - remove eventually.
        OPENSSL_X509_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
        # FIXME: unneeded - remove eventually.
        GIT_SSL_CAINFO         = "/etc/ssl/certs/ca-certificates.crt";
      };

  };

}
