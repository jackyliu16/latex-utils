{
  pkgs,
  lib,
  ...
}: args @ {
  name,
  src,
  workingDirectory ? ".",
  inputFile ? "main.tex",
  outputPath ? "output.pdf",
  texPackages ? {},
  scheme ? pkgs.texlive.scheme-basic,
  silent ? false,
  ...
}:
with pkgs.lib.attrsets; let
  # Make sure our derivation ends in .pdf
  fixedName =
    if pkgs.lib.strings.hasSuffix ".pdf" name
    then name
    else pkgs.lib.strings.concatStrings [name ".pdf"];
  chosenStdenv = args.stdenv or pkgs.stdenvNoCC;

  searchPaths = lib.findLatexFiles {basePath = "${src}/${workingDirectory}";}; 
  discoveredPackages = let
    gainPackFromPath = (path: (lib.findLatexPackages {fileContents = builtins.readFile path;}));
    eachFile = map gainPackFromPath searchPaths;
    # packNames = builtins.foldl' (a: b: a ++ b) [] eachFile; # [{a="A";} {b="B"};] => {a="A"; b="B";}
    packNames = builtins.concatLists (builtins.concatLists eachFile);
    detectTexPacks = filterAttrs (y: x: x != null) (genAttrs packNames (name: attrByPath [name] null pkgs.texlive));
  in
    if silent
    then packNames
    else lib.trace "identified packages (add more with argument 'texPackages'): ${toString (attrNames packNames)}." detectTexPacks;

  allPackages =
    {
      inherit scheme;
      inherit
        (pkgs.texlive)
        # basic latex
        latex-bin
        latexmk
        # bibtex stuff
        biblatex
        biber
        csquotes
        ;
    }
    # // discoveredPackages
    // texPackages;
  texEnvironment = pkgs.texlive.combine allPackages;
in
  pkgs.stdenvNoCC.mkDerivation rec {
    inherit src;
    name = fixedName;

    whatthefuck = { a = discoveredPackages; };

    nativeBuildInputs =
      args.nativeBuildInputs or []
      ++ (with pkgs; [
        coreutils
        texEnvironment
      ]);

    phases = args.phases or ["unpackPhase" "buildPhase" "installPhase"];

    buildPhase =
      args.buildPhase
      or ''
        export PATH="${pkgs.lib.makeBinPath nativeBuildInputs}";
        mkdir -p .cache/texmf-var
        cd ${workingDirectory}
        echo $PWD
        ls $PWD
        env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var \
          latexmk -f -interaction=nonstopmode -pdf -lualatex -bibtex \
          -jobname=output \
          ${inputFile}
      '';

    installPhase =
      args.installPhase
      or ''
        mv output.pdf $out
      '';
  }
