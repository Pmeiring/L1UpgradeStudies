# L1UpgradeStudies code

## Table of contents

1. [Introduction](#introduction)
1. [Setup (on lxplus)](#setup-on-lxplus)
1. [More information on the binaries](#more-information-on-the-binaries)
   1. [binary/FillHistograms](#binaryfillhistograms)
   1. [binary/PlotComparison](#binaryplotcomparison)
   1. [binary/MakeScalingPlot](#binarymakescalingplot)
   1. [binary/ExportTextFile](#binaryexporttextfile)
1. [Histogram structure](#histogram-structure)



## Introduction

This is the code to make turn on and efficiencies

Config file [here](https://docs.google.com/spreadsheets/d/14CVVhA6ITSTmv0x0Z2BRJ7cLgMKabi6TWsDXbyffGBg/edit#gid=1735114236).
Copy paste the whole sheet into a text file, and feed the text file into the fill histogram executable to run things

The code is done in two parts.  First part is an executable to generate all the histograms.  The second part is to take the histograms and make efficiencies, turn-ons, and scalings.

The first step can take a while (few hours), and that's because of the file I/O to write out all the histograms.  If you are pressed for time, consider making a smaller config file with only the few relevant lines.  Then after the rush, or on the side, we can launch the full thing (it's always a good idea to have all objects ready for all the files).


Note:
1. Instructions on the config file sheet is coming
1. Instructions for new tree version is coming






## Setup (on lxplus)

1. Setup a recent CMSSW environment. The code is not bound to any specific CMSSW version. For example if you want to use CMSSW_10_6_0:
```
cmsrel CMSSW_10_6_0
cd CMSSW_10_6_0/src
cmsenv
git cms-init
```

2. Clone this repository (no restrictions on where)
```
git clone https://github.com/FHead/L1UpgradeStudies.git
```
3. Make sure you have `root` and `fastjet` in PATH. One can also check with:
```
root-config --version
fastjet-config --version
```
4. do `make` to compile everything
```
cd L1UpgradeStudies
make
```
5. test run by typing `make TestRun`

Take a look at the makefile for the TestRun for an example on how to run everything.



### How to install FastJet

Get download link to the latest FastJet version from http://www.fastjet.fr/  
```
mkdir FASTJET
wget http://www.fastjet.fr/repo/fastjet-3.3.2.tar.gz
tar xzf fastjet-3.3.2.tar.gz
cd fastjet-3.3.2
./configure --prefix=/yourpath/FASTJET
make install
```
Make sure the path to fastjet-config is in the PATH variable:

```
export PATH=${PATH}:/yourpath/FASTJET/bin/ 
```


## More information on the binaries

### binary/FillHistograms

makes all the histograms needed for later steps.  Input parameters as follows
1. `input`: comma-separated list of all root files
1. `output`: output file name (.root)
1. `StoredGen`: true/false.  Whether to use the gen jet info stored in the tree, or recluster on the fly
1. `config`: the config file to use

### binary/PlotComparison

this makes a plot with efficiencies or turn ons, or just simple distributions, or even cumulative distributions.  This executable is very versatile.  Input parameters as follows
1. `label`: comma-separated list of histogram labels (to be used in legends)
1. `file`: comma-separated list of files that contains the histograms
1. `numerators`: comma-separated list of histograms to be use as numerators
1. `denominators`: comma-separated list of histograms to be used as denominators.  Several possibilities here
   1. histogram name.  Takes the histogram from the file
   1. "auto".  Guesses the denominator name by adding "NoMatch"
   1. "simple".  Don't divide the numerator histogram by anything.  Just plot the distribution
   1. "cumulative".  Don't divide the numerator histogram, but instead draw the cumulative version of it (useful for isolation derivation)
1. `output`: output filename.
1. `title`: string to be passed into the histogram constructor.  For example: "title;x;y"
1. `xmin`, `xmax`, `ymin`, `ymax`: range of axes.  y range defaults to (0.0, 1.1) if omitted
1. `color`: comma-separated list of integers to be used as colors (see root TColor for the list) for each curve
1. `line`: comma-separated list of doubles.  Each one will draw a horizontal dashed line on the plot
1. `grid`: true/false.  Whether to enable grid.  Defaults to false.
1. `logy`: true/false.  Whether to do log y.  Defaults to false.
1. `legendx`, `legendy`: Location of the upper-left corner of legend.  Defaults to (0.35, 0.20)
1. `rebin`: integer, defaults to 1.  If not 1, the histograms will be rebinned using this number.

### binary/MakeScalingPlot

This executable fits stuff and gets the scalings, and writes results into a data helper (DH) file, in addition to producing a pdf for inspection.  Input parameters are -
1. `input`: the root file from the first step containing all the histograms
1. `output`: the output pdf file name.  Has to be pdf!
1. `curves`: the output DH file name.
1. `reference`: where to take as the reference point.  We typically use 95%
1. `prefix`: additional prefix to distinguish stuff in the DH file
1. `Do*`: a lot of booleans, all defaults to false.  The * can be {STAMuon, STADisplacedMuon, TkMuon, TkMuonStub, TkMuonStubS12, EG, EGExtended, EGTrack, Electron, ZElectron, IsoElectorn, Photon, PhotonPV, ElectronPV, PuppiJet, PuppiJetForMET, PuppiJetMin25, PuppiHT, PuppiMET, PFTau, PFIsoTau, CaloJet, CaloHT, TrackerJet, TrackerHT, TrackerMHT, TrackerMET, TkTau, CaloTkTau, TkEGTau, NNTauLoose, NNTauTight, CaloTau}.  Though it's best to look in the source code to see what is there

The main work horse of this is the ProcessFile(...) function, which fits and produces one scaling line.  In case we need to fit new things, we have to add these functions in the code, with one of the `Do*` switch if possible, to make sure things don't litter around too much.  The function is defined as

``` c++
void ProcessFile(PdfFileHelper &PdfFile, string FileName, string OutputFileName,
   string Prefix, vector<double> Thresholds,
   double Target, string Tag, string Name = "PT", int Type = TYPE_SMOOTH_SUPERTIGHT,
   int Scaling = LINEAR)
```

Here are the meaning of each of the thing

1. `PdfFileHelper &PdfFile`: this is one of the Yi helper class that makes multiple-page pdfs a breeze.  It makes the final pdf output file
1. `string FileName`: the file that contains all the histograms
1. `string OutputFileName`: the DH file filename.
1. `string Prefix`: the directory to use in the histogram file
1. `vector<double> Thresholds`: what thresholds to use in the scan
1. `double Target`: the famous 98%, or some other number you like.  We pass it from command line
1. `string Tag`: The tag to use to store the result in the DH file
1. `string Name`: The middle part of histogram to use (for example the `PT` in `TkElectron_PT_000000`)
1. `int Type`: what kind of fit to perform.  Several possibilies are coded
   1. `TYPE_FITFIX`: fits with the classic function `f(x)` we've been using for ages with three parameters: lambda, mu, sigma
   1. `TYPE_FITFIX2`: let the baseline float by modifying the function as `f(x) * ([3]-[4]) + [4]`, but fix `[3]` to 1.0
   1. `TYPE_FIT`: same modification as before, but fix `[4]` to 0 and let `[3]` float
   1. `TYPE_FITFLOAT`: let the baseline and the plateau float by modifying the function as `f(x) * ([3]-[4]) + [4]`
   1. `TYPE_FITTANH`: fits the turn on with a tanh() function
   1. `TYPE_SMOOTH_LOOSE`: a string model that attempts to go through all the points with a loose tension.
   1. `TYPE_SMOOTH_TIGHT`: same as above, a bit higher tension
   1. `TYPE_SMOOTH_SUPERTIGHT`: similarly, with even higher tension
   1. `TYPE_SMOOTH_ULTRATIGHT`: very tight strings!
1. `int Scaling`: what kind of scaling to fit in the end.  99.9% we put `LINEAR`.  There is also `QUADRATIC`, which fits a quadratic curve of `x = a2 y^2 + a1 y + a0`  (note the swap between x and y)



Note 1: The classic function is this one

```
f(x) = (ROOT::Math::normal_cdf([0]*(x-[1]), [0]*[2], 0) - exp(-[0]*(x-[1])+[0]*[0]*[2]*[2]/2)*ROOT::Math::normal
_cdf([0]*(x-[1]), [0]*[2], [0]*[0]*[2]*[2]))
```

Note 2: Since we only care about the point where the turn on passes x% (usually 95%), the string model is a fine thing to use.  Sometimes the fit just won't converge for some strange reason.  And the string model is much more stable and flexible - for example if the detail of the turn on curve is not described well by the classic curve nor the tanh() around 10-30% turn on range, rather than finding the best curve to fit, we can use the string to go through the points and extract the 95% with good confidence.  



### binary/ExportTextFile

This executable makes the text file to interface with the rate part of menu code.

There are two input arguments:
1. `input`: the DH file file name that contains all the turn on fit results
1. `output`: text file name to store the output

For this usually we need to go into the code and change what is exported.  Putting everything from command line seems silly, and exporting all the unnecessary things from the DH file is not helpful either.  If you open the source code, you can see three blocks

``` c++
vector<pair<string, string>> GName =
{
   pair<string, string>("StandaloneMuonIsoTanh", "StandaloneMuon"),
   ...
}
vector<pair<string, string>> TwoPartName =
{
   pair<string, string>("EG", "StandalonePhoton"),
   ...
};
vector<pair<string, string>> QuadraticName =
{
   pair<string, string>("TrackerMHT5METFit", "TrackerMHTQuadratic")
};
```

Each of the block contains a list of pairs.  First item in the pair is the identifier in the DH file.  Second item is the name you want it to appear in the final text file.

The first block is simple linear scaling.  The second one will look for barrel and endcap ("EGBarrel", "EGEndcap") and add a if statement in the final text file.  The last one is for quadratic cases - not really used so far.




## Histogram structure

Each object is in its own directory.  Within each directory, there are many many histograms.  Let's take TkElectron as example.  The naming convention is
1. TkElectronNoMatch_*_000000: The distribution without gen-match
1. TkElectron_*_000000: the distribution with gen-match, but no L1 PT requirement
1. TkElectron_*_00XX00: the distribution with gen-match, and with L1 PT > XX.  30 GeV = 003000, 10.5 GeV = 001050, etc.  The list is set by the "preset" column in the config file.

There are a number of distributions in the middle field
1. PT: PT distribution without any eta restriction
1. PTEta15: PT in barrel
1. PTEtaLarge: PT outside barrel
1. Response: L1PT/GenPT
1. ResponseEta15: response in barrel
1. ResponseEtaLarge: response outside barrel
1. ResponsePT`x`: response with PT > `x`, `x` = 10, 50, 100, 150, 200
1. ResponsePT10Eta15: response with PT > 10, barrel
1. ResponsePT10EtaLarge: response with PT > 10, outside barrel
1. Eta: eta distribution
1. EtaPT3to`x`: eta with PT = 3-`x`, `x` = 5, 6, 10, 15
1. EtaPT`x`: eta with PT > `x`, `x` = 15, 20, 25, 30, 100, 200
1. EtaDXY`x`: eta with DXY > `x`, `x` = 20, 50, 80
1. TkIso: isolation
1. TkIsoPT`x`: isolation with PT > `x`, `x` = 10, 20, 30, 40
1. TkIsoEta15: isolation within barrel
1. TkIsoEtaLarge: isolation outside barrel
1. TkIsoPT10Eta15: isolation within barrel, and PT > 10
1. TkIsoPT10EtaLarge: isolation outside barrel, and PT > 10
1. DR: matching DR distribution
1. DRPT`x`: matching DR, PT > `x`, `x` = 10, 20, 50
1. DREta15: matching DR inside barrel
1. DRPT10Eta15: matching DR inside barrel, PT > 10
1. DRPT20Eta15: matching DR inside barrel, PT > 20
1. DREtaLarge: matching DR outside barrel
1. DRPT10EtaLarge: matching DR outside barrel, PT > 10
1. DRPT20EtaLarge: matching DR outside barrel, PT > 20
1. DXY: DXY distribution
1. DXYPT`x`: DXY, PT > `x`, `x` = 15, 20, 30

So... If you want...

1. Matching efficiency vs PT: TkElectron_PT_000000 / TkElectronNoMatch_PT_000000
1. Matching efficiency vs eta: TkElectron_Eta_000000 / TkElectronNoMatch_Eta_000000
1. Turn on with threhsold 15: TkElectron_PT_001500 / TkElectron_PT_000000
1. Isolation distritbuion: TkElectron_TkIso_000000

For things involving isolation, sometimes you need to get it from different folders.  For example

1. Matching efficiency vs PT for TkIsoElectron: TkIsoElectron_PT_000000 / TkElectronIsoNoMatch_PT_000000















