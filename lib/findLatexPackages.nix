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
    let 
      contentsLines = builtins.splitString "\n" fileContents;
      preprocessLines = builtins.filter (line: !(isPackageLines line)) contentsLines;
      processedLines = builtins.map ifPackageNameFormatCorrect preprocessLines;
      texPackages = filterAttrs (y: x: x != null) (genAttrs packageNames (name: attrByPath [name] null pkgs.texlive));

      isPackageLines = line: let # str -> Bool
        res = builtins.match ''\\(usepackage|Requirepackage).*'' line;
      in res != null;
      gainPackageName = line: let # str -> List[str]
        matchers = builtins.tail (builtins.match ''\\(usepackage|RequirePackage).*\{(.*)}}'' line); # [ ~~"usepackage"~~ "a" "b" ]
        res = builtins.filter (ps: ps != false) builtins.map ifPackageNameFormatCorrect matchers;   
      in res;
      ifPackageNameFormatCorrect = one: let # str -> Bool
        res = builtins.match ''^[a-z](?|.*--)[a-z-]*[a-z]$'' one;
      in res != null;
    in
     gainPackageName 
