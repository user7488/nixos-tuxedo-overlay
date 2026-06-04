{ lib
, stdenv
, fetchurl
, rpmextract
, autoPatchelfHook
, perl
, gnused
, gnugrep
, coreutils
, which
, ghostscript
, file
, cups
, libusb1
}:

stdenv.mkDerivation rec {
  pname = "mfcj1010dwpdrv";
  version = "3.5.0-1";

  src = ./mfcj1010dwpdrv-3.5.0-1.i386.rpm;

  nativeBuildInputs = [
    rpmextract
    autoPatchelfHook
  ];

  buildInputs = [
    perl
    ghostscript
    cups
    libusb1
  ];

  unpackPhase = ''
    rpmextract $src
  '';

  installPhase = ''
    mkdir -p $out/share/cups/model
    mkdir -p $out/lib/cups/filter
    mkdir -p $out/opt

    cp -r opt/brother $out/opt/

    # Path to the printer driver files
    # We use x86_64 binaries
    
    DRIVER_DIR=$out/opt/brother/Printers/mfcj1010dw
    
    # Symlink the binary to where the scripts expect it (or patch script)
    # The filter script expects `br%sfilter` in `lpd/`
    ln -s $DRIVER_DIR/lpd/x86_64/brmfcj1010dwfilter $DRIVER_DIR/lpd/brmfcj1010dwfilter
    
    # Also link the config tool
    ln -s $DRIVER_DIR/lpd/x86_64/brprintconf_mfcj1010dw $DRIVER_DIR/lpd/brprintconf_mfcj1010dw

    # Patch the wrapper script: cupswrapper/brother_lpdwrapper_mfcj1010dw
    WRAPPER=$DRIVER_DIR/cupswrapper/brother_lpdwrapper_mfcj1010dw
    
    sed -i "s|/usr/bin/perl|${perl}/bin/perl|g" $WRAPPER
    
    # Patch $basedir
    # Original: my $basedir = `readlink $0`;
    # We'll hardcode it.
    sed -i "s|my \$basedir = \`readlink \$0\`;|my \$basedir = \"$DRIVER_DIR/\";|g" $WRAPPER
    sed -i "s|my \$basedir = \`realpath \$0\`;|my \$basedir = \"$DRIVER_DIR/\";|g" $WRAPPER
    
    # Remove the dynamic $PRINTER calculation logic which is fragile
    sed -i 's|if ( $basedir eq .*|if (0) {|' $WRAPPER
    
    # Patch $PRINTER
    # Original: $PRINTER =~ s/^\/opt\/.*\/Printers\///g;
    # We'll hardcode it.
    sed -i 's|my $PRINTER=$basedir;|my $PRINTER="mfcj1010dw";|' $WRAPPER
    
    # Disable subsequent regex replacements on $PRINTER since we hardcoded it
    sed -i 's|$PRINTER =~ s/^\/opt\/.*|# $PRINTER =~ ...|' $WRAPPER
    sed -i 's|$PRINTER =~ s/\/cupswrapper//g;|# $PRINTER =~ ...|' $WRAPPER
    sed -i 's|$PRINTER =~ s/\///g;|# $PRINTER =~ ...|' $WRAPPER

    # Patch exec_lpdconfig to find the config tool
    # Original: $lpddir = $basedir."/lpd/"; my $lpdconf = $LPDCONFIGEXE.$PRINTER;
    # It expects `brprintconf_mfcj1010dw` in PATH? No, line 901 just runs `$lpdconf_command`.
    # Wait, line 893-895:
    # $lpddir = $basedir."/lpd/";
    # my $lpdconf = $LPDCONFIGEXE.$PRINTER;
    # It doesn't use $lpddir in $lpdconf!
    # So we must ensure it uses absolute path.
    sed -i 's|my $lpdconf = $LPDCONFIGEXE.$PRINTER;|my $lpdconf = $lpddir.$LPDCONFIGEXE.$PRINTER;|' $WRAPPER


    # Patch the filter script: lpd/filter_mfcj1010dw
    FILTER=$DRIVER_DIR/lpd/filter_mfcj1010dw
    
    sed -i "s|/usr/bin/perl|${perl}/bin/perl|g" $FILTER
    
    # Patch $BR_PRT_PATH
    sed -i "s|my \$BR_PRT_PATH = Cwd::realpath (\$0);|my \$BR_PRT_PATH = \"$DRIVER_DIR/\";|g" $FILTER
    
    # Patch ghostscript and file
    sed -i "s|my \$GHOST_SCRIPT=\`which gs\`;|my \$GHOST_SCRIPT=\"${ghostscript}/bin/gs\";|g" $FILTER
    sed -i "s|\`file |\`${file}/bin/file |g" $FILTER
    
    # Patch other tools
    sed -i "s|\`grep |\`${gnugrep}/bin/grep |g" $FILTER
    sed -i "s| sed | ${gnused}/bin/sed |g" $FILTER
    sed -i "s|\`cat |\`${coreutils}/bin/cat |g" $FILTER
    sed -i "s|\`cp |\`${coreutils}/bin/cp |g" $FILTER
    sed -i "s|\`mv |\`${coreutils}/bin/mv |g" $FILTER
    sed -i "s|\`rm |\`${coreutils}/bin/rm |g" $FILTER
    sed -i "s|copy \"\$INPUT_TEMP\"|${coreutils}/bin/cp \"\$INPUT_TEMP\"|g" $FILTER
    
    
    # Install PPD
    cp $DRIVER_DIR/cupswrapper/brother_mfcj1010dw_printer_en.ppd $out/share/cups/model/brother-mfcj1010dw.ppd
    
    # Patch PPD to point to the filter in the store
    # We will install the wrapper script to $out/lib/cups/filter/
    
    # The PPD says: *cupsFilter: "application/vnd.cups-postscript 0 brother_lpdwrapper_mfcj1010dw"
    # We replace the command with absolute path.
    sed -i "s|brother_lpdwrapper_mfcj1010dw|$out/lib/cups/filter/brother_lpdwrapper_mfcj1010dw|g" $out/share/cups/model/brother-mfcj1010dw.ppd
    
    # Link wrapper to lib/cups/filter
    ln -s $WRAPPER $out/lib/cups/filter/brother_lpdwrapper_mfcj1010dw
    
    chmod +x $WRAPPER
    chmod +x $FILTER
    chmod +x $DRIVER_DIR/lpd/x86_64/*
  '';

  meta = with lib; {
    description = "Brother MFC-J1010DW printer driver";
    homepage = "http://www.brother.com/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" "i686-linux" ];
    maintainers = [ ];
  };
}
