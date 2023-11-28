# Finding LaTex Packages name as list
# INPUT:str         // the content of a file though readFiles
# OUTPUT:List[str]  // a list of packages names
{
  pkgs,
  lib,
  ...
}: let
in
  {fileContents}:
    with pkgs.lib.attrsets;
    with pkgs.lib.strings; 
    with pkgs.lib.lists;
    let 
      inherit (builtins) trace match head tail split filter readFile isList isNull elemAt pathExists;
      inherit (pkgs.lib) concatMap concatLists subtractLists splitString genAttrs unique remove
        hasSuffix isDerivation;
      contentsLines = splitString "\n" fileContents;
      # Check if line contains package information
      preprocessLines = builtins.filter (line: !(isPackageLines line)) contentsLines; # List[str]: the line contains package info
      processedPackages = unique (builtins.concatMap gainPackageNameFromLine preprocessLines); # List[str]: the line contains package name

      texPackages = filterAttrs (y: x: x != null) processedPackages (genAttrs processedPackages (name: attrByPath [name] null pkgs.texlive));

      isPackageLines = line: let # str -> Bool
        res = builtins.match ''\\(usepackage|Requirepackage).*'' line;
      in res != null;
      gainPackageNameFromLine = line: let # str -> List[str]
        matchers = builtins.tail (builtins.match ''\\(usepackage|RequirePackage).*\{(.*)}}'' line); # [ ~~"usepackage"~~ "a" "b" ]
        # Check if each name provide by matcher is correct
        # TODO: add more trace output when incorrect.
        res = builtins.filter (ps: ps != false) builtins.map ifPackageNameFormatCorrect matchers;   
      in res;
      ifPackageNameFormatCorrect = one: let # str -> Bool
        res = builtins.match ''^[a-z](?|.*--)[a-z-]*[a-z]$'' one;
      in res != null;
    in
     texPackages 
