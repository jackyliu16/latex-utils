{ pkgs
  , lib
  , ...
}:
args@{
  name
  , src
  , workingDirectory ? "."
  , inputFile ? "main.tex"
  , outputPath ? "output.pdf"
  , texPackages ? {}
  , scheme ? pkgs.texlive.scheme-basic
  , silent ? false
  , ...
}: with pkgs.lib.attrsets; 
let
  chosenStdenv = args.stdenv or pkgs.stdenvNoCC;

  searchPaths = lib.findLatexFiles { basePath = "${src}/${workingDirectory}"; };
  discoveredPackages = let
    eachFile = map (path: (lib.findLatexPackages { fileContents = (builtins.readFile "${src}/${workingDirectory}/${path}"); })) searchPaths;
    together = builtins.foldl' (a: b: a // b) {} eachFile;
  in if silent then together else builtins.trace "latex-utils: identified packages (add more with argument 'texPackages'): ${toString (attrNames together)}" together;
  
  allPackages = {
    inherit scheme;
    inherit (pkgs.texlive)
    # basic latex
    latex-bin
    latexmk

    # bibtex stuff
    biblatex
    biber
    csquotes
    ;
  } // discoveredPackages // texPackages;
  texEnvironment = pkgs.texlive.combine allPackages;

in chosenStdenv.mkDerivation rec {
  inherit name src;
  
  nativeBuildInputs = (args.nativeBuildInputs or []) ++ (with pkgs; [
    coreutils
    texEnvironment
  ]);

  phases = args.phases or ["unpackPhase" "buildPhase" "installPhase"];
  buildPhase = args.buildPhase or ''
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
  installPhase = args.installPhase or ''
    mkdir -p $out
    cp output.pdf $out/${outputPath}
  '';
}

