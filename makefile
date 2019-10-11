default: all

all: commoncode libraries executables

CommonCode = library/L1Classes.so library/TauHelperFunctions3.o library/DrawRandom2.o library/Messenger.o
Libraries  = library/Histograms.o library/HelperFunctions.o

commoncode: $(CommonCode)	

libraries: $(Libraries)

executables: binary/FillHistograms binary/PlotComparison binary/MakeScalingPlot binary/ExportTextFile

library/L1Classes.so: include/L1Classes.h include/L1LinkDef.h
	mkdir -p library
	rootcint -f source/L1Classes.cpp -c include/L1Classes.h include/L1LinkDef.h
	g++ `root-config --cflags` source/L1Classes.cpp -o library/L1Classes.o -I. -c -fpic
	g++ -shared -o library/L1Classes.so library/L1Classes.o
	ln -s source/L1Classes_rdict.pcm .

library/TauHelperFunctions3.o: source/TauHelperFunctions3.cpp include/TauHelperFunctions3.h
	mkdir -p library
	g++ source/TauHelperFunctions3.cpp -Iinclude -o library/TauHelperFunctions3.o -c

library/DrawRandom2.o: source/DrawRandom2.cpp include/DrawRandom2.h
	mkdir -p library
	g++ source/DrawRandom2.cpp -Iinclude -o library/DrawRandom2.o -c

library/Messenger.o: source/Messenger.cpp include/Messenger.h
	mkdir -p library
	g++ source/Messenger.cpp -Iinclude -o library/Messenger.o -c `root-config --cflags`

library/Histograms.o: source/Histograms.cpp include/Histograms.h
	mkdir -p library
	g++ source/Histograms.cpp -Iinclude -o library/Histograms.o -c `root-config --cflags`

library/HelperFunctions.o: source/HelperFunctions.cpp include/HelperFunctions.h
	mkdir -p library
	g++ source/HelperFunctions.cpp -Iinclude -o library/HelperFunctions.o -c `fastjet-config --cxxflags` `root-config --cflags`

binary/FillHistograms: source/FillHistograms.cpp library/Histograms.o library/HelperFunctions.o
	mkdir -p binary
	g++ source/FillHistograms.cpp -Iinclude -o binary/FillHistograms $(CommonCode) \
		library/Histograms.o library/HelperFunctions.o \
		`fastjet-config --cxxflags --libs` `root-config --cflags --libs`

binary/PlotComparison: source/PlotComparison.cpp
	mkdir -p binary
	g++ source/PlotComparison.cpp -Iinclude -o binary/PlotComparison \
		`root-config --cflags --libs`

binary/MakeScalingPlot: source/MakeScalingPlot.cpp
	mkdir -p binary
	g++ source/MakeScalingPlot.cpp -Iinclude -o binary/MakeScalingPlot \
		`root-config --cflags --libs`

binary/ExportTextFile: source/ExportTextFile.cpp
	mkdir -p binary
	g++ source/ExportTextFile.cpp -Iinclude -o binary/ExportTextFile \
		`root-config --cflags --libs`

TestRun: TestRunPart1 TestRunPart2

DYLL_V9p3 = /eos/cms/store/group/cmst3/group/l1tr/cepeda/triggerntuples160/RelValZEE_14/crab_ZEE_noageing_106_V9_3//190910_103305/0000//
TestRunPart1: binary/FillHistograms
	mkdir -p output
	binary/FillHistograms --input `ls $(DYLL_V9p3)/* | head -n 10 | tr '\n' ',' | sed "s/,$$//g"` \
		--output output/DYLL_V9p3.root --StoredGen true --config config/20190823DY.config
	
TestRunPart2: binary/PlotComparison binary/MakeScalingPlot binary/ExportTextFile
	mkdir -p pdf
	binary/PlotComparison \
		--label "EGElectron (V9.3)","TkElectron (V9.3)","TkIsoElectron (V9.3)" \
		--file output/DYLL_V9p3.root,output/DYLL_V9p3.root,output/DYLL_V9p3.root \
		--numerator "EGTrackIDIso_PTEta15_000000","TkElectronTrackIDIso_PTEta15_000000","TkIsoElectron_PTEta15_000000" \
		--denominator "auto","auto","TkElectronIsoNoMatch_PTEta15_000000" \
		--title ";p_{T};Efficiency" --xmin 0 --xmax 40 --output pdf/V9p3_EGComparison.pdf \
		--legendx 0.45 --legendy 0.20
	mkdir -p dh
	binary/MakeScalingPlot --input output/DYLL_V9p3.root --output pdf/V9p3_EGScaling.pdf \
		--curves dh/V9p3_Scaling.dh \
		--reference 0.95 --DoEG true --DoEGTrack true --DoElectron true --DoIsoElectron true
	binary/MakeScalingPlot --input output/DYLL_V9p3.root --output pdf/V9p3_MuonScaling.pdf \
		--curves dh/V9p3_Scaling.dh \
		--reference 0.95 --DoTkMuon true
	mkdir -p txt
	binary/ExportTextFile --input dh/V9p3_Scaling.dh --output txt/V9p3_Scaling.txt


DYLL_V7p5p2 = /eos/cms/store/cmst3/group/l1tr/cepeda/triggerntuples10X/DYToLL_M-50_14TeV_TuneCP5_pythia8/crab_DYLL_200PU_V7_5_2/190324_103140/0000//
myfillhistograms: binary/FillHistograms
	mkdir -p output
	binary/FillHistograms --input `ls $(DYLL_V7p5p2)/* | head -n 10 | tr '\n' ',' | sed "s/,$$//g"` \
		--output output/MyTestOutput.root --StoredGen true --config config/mycustom.config
	
MatchingEff_EG_TkE_PT: binary/PlotComparison
	mkdir -p pdf
	binary/PlotComparison \
		--label "EGElectron (V7.5.2)","TkElectron (V7.5.2)" \
		--file output/MyTestOutput.root,output/MyTestOutput.root \
		--numerator "EGTrackID_PT_000000","TkElectronTrackID_PT_000000" \
		--denominator "auto","auto" \
		--title ";p_{T};Efficiency" --xmin 0 --xmax 40 --output pdf/MatchingEff_EG_TkE_PT.pdf \
		--legendx 0.45 --legendy 0.20 \
		--rebin 10

MatchingEff_EG_Eta_PTbinned: binary/PlotComparison
	mkdir -p pdf
	binary/PlotComparison \
		--label "5 < pT < 10","10 < pT < 20","20 < pT < 30","30 < pT < 40" \
		--file output/MyTestOutput.root,output/MyTestOutput.root,output/MyTestOutput.root,output/MyTestOutput.root \
		--numerator "EGTrackID_EtaPT5to10_000000","EGTrackID_EtaPT10to20_000000","EGTrackID_EtaPT20to30_000000","EGTrackID_EtaPT30to40_000000" \
		--denominator "auto","auto","auto","auto" \
		--title "EGElectron (V7.5.2);#eta;Efficiency" --xmin -3 --xmax 3 --output pdf/MatchingEff_EG_Eta_PTbinned.pdf \
		--legendx 0.45 --legendy 0.20 \
		--rebin 10

MatchingEff_TkE_Eta_PTbinned: binary/PlotComparison
	mkdir -p pdf
	binary/PlotComparison \
		--label "5 < pT < 10","10 < pT < 20","20 < pT < 30","30 < pT < 40" \
		--file output/MyTestOutput.root,output/MyTestOutput.root,output/MyTestOutput.root,output/MyTestOutput.root \
		--numerator "TkElectronTrackID_EtaPT5to10_000000","TkElectronTrackID_EtaPT10to20_000000","TkElectronTrackID_EtaPT20to30_000000","TkElectronTrackID_EtaPT30to40_000000" \
		--denominator "auto","auto","auto","auto" \
		--title "TkElectron (V7.5.2);#eta;Efficiency" --xmin -3 --xmax 3 --output pdf/MatchingEff_TkE_Eta_PTbinned.pdf \
		--legendx 0.45 --legendy 0.20 \
		--rebin 10

MatchingEff_EG_TkE_PT_Etabinned: binary/PlotComparison
	mkdir -p pdf
	binary/PlotComparison \
		--label "EGElectron | 0 < eta < 1.479","EGElectron | 1.479 < eta < 2.8","TkElectron | 0 < eta < 1.479","TkElectron | 1.479 < eta < 2.8" \
		--file output/MyTestOutput.root,output/MyTestOutput.root,output/MyTestOutput.root,output/MyTestOutput.root \
		--numerator "EGTrackID_PTEta0to1p479_000000","EGTrackID_PTEta1p479to2p8_000000","TkElectronTrackID_PTEta0to1p479_000000","TkElectronTrackID_PTEta1p479to2p8_000000" \
		--denominator "auto","auto","auto","auto" \
		--title ";p_{T};Efficiency" --xmin 0 --xmax 40 --output pdf/MatchingEff_EG_TkE_PT_Etabinned.pdf \
		--legendx 0.45 --legendy 0.20 \
		--rebin 10