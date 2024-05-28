// VIPA_manual_SINGLE
// This part of the code is used to generate the ratiometric and mask stacks from the original raw stack

// Fabien Miart 18-10-2023

// OPEN YOUR STACK OF IMAGES CONTAINING THE THREE CHANNELS BEFORE RUNNING THE MACRO (containing RGB, GFP and Transmitted light channels)


source_dir = getDirectory("Select the main directory");

// Create MASKS directory if it doesn't exist
masks_dir = source_dir + File.separator + "MASKS";
if (!File.exists(masks_dir))
    File.makeDirectory(masks_dir);
masksprep_dir = source_dir + File.separator + "MASKS_prep";
if (!File.exists(masksprep_dir))
    File.makeDirectory(masksprep_dir);
masksprep2_dir = source_dir + File.separator + "MASKS_prep2";
if (!File.exists(masksprep2_dir))
    File.makeDirectory(masksprep2_dir);
masksprep3_dir = source_dir + File.separator + "MASKS_prep3";
if (!File.exists(masksprep3_dir))
    File.makeDirectory(masksprep3_dir);
skeleton_dir = source_dir + File.separator + "SKELETONS";
if (!File.exists(skeleton_dir))
    File.makeDirectory(skeleton_dir);
results_dir = source_dir + File.separator + "RESULTS";
if (!File.exists(results_dir))
    File.makeDirectory(results_dir);
    
    
// ---------------------------------
// STEP1 : GENERATION OF THE SEEDLING MASK
	// STEP1.1 : MANAGING OF THE IMAGES STACK
rename("Image");
waitForUser("Be sure C1 =mRFP, C2=eGFP, C3=TL and click OK");			
run("Split Channels");
selectWindow("C1-Image");
rename("mRFP");
run("Duplicate...", "title=mRFPref duplicate");
selectWindow("C2-Image");
rename("eGFP");
run("32-bit");
selectWindow("mRFP");
run("32-bit");
run("Select None");

	// STEP1.2 : PROCESSING OF THE eGFP Channel AS A REFERENCE CHANNEL
selectWindow("eGFP");
run("Smooth", "stack");
run("Threshold...");
setAutoThreshold("Huang dark");
waitForUser("Define your Threshold, apply it, Select NaN, Apply on all images, and click OK");			
run("NaN Background", "stack");
resetThreshold();

	// STEP1.3 : GENERATION OF THE RATIOMETRIC IMAGE
imageCalculator("Divide create 32-bit stack", "eGFP","mRFP");
selectWindow("Result of eGFP");
rename("Resultratio");
run("royal");
resetMinAndMax();
			//Attention l'enhance contrast peut être à modifier
run("Enhance Contrast", "saturated=0.35");
run("Enhance Contrast", "saturated=0.35");
run("Enhance Contrast", "saturated=0.35");
run("Enhance Contrast", "saturated=0.35");
selectWindow("eGFP");
close();
selectWindow("mRFP");
close();
selectWindow("mRFPref");
close();
selectWindow("Resultratio");
run("Duplicate...", "duplicate");
run("Duplicate...", "duplicate");
selectWindow("Resultratio-1");
run("8-bit");
setAutoThreshold("MinError dark");
setOption("BlackBackground", true);
run("Convert to Mask", "method=MinError background=Dark calculate black");
//run("Fill Holes", "stack");

selectWindow("Resultratio-1");
waitForUser("save stack as image sequence in tif in masksprep directory");
//run("Image Sequence... ", "format=TIFF use save=" + masksprep_dir);
close();

selectWindow("Resultratio");
run("8-bit");
setMinAndMax(0, 88);
run("Apply LUT", "stack");
saveAs("Tiff", results_dir + File.separator + "Result_ratio");
close();

	// STEP1.4 : PRE-PROCESSING TO GENERATE A PERFECT MASK
if (File.exists(masksprep_dir)) {
	list = getFileList(masksprep_dir);
	for (t=0; t<list.length; t++) {
		if (endsWith(list[t], ".tif")) {
	    	open(masksprep_dir + "/" + list[t]);
			
			setBatchMode(true);
			rename("Image");
			run("Morphological Filters", "operation=Closing element=[Vertical Line] radius=4");
			selectWindow("Image");
			close();
			selectWindow("Image-Closing");
			//run("Fill Holes");
			setBatchMode(false);
			saveAs("Tiff", masksprep2_dir + "/" + list[t] + ".tif");
			close();
		showProgress(t, list.length);
		}
	}
}		
if (File.exists(masksprep2_dir)) {
	list = getFileList(masksprep2_dir);
	for (d=0; d<list.length; d++) {
		if (endsWith(list[d], ".tif")) {
	    	open(masksprep2_dir + "/" + list[d]);

			setBatchMode(true);
			rename("Image");
			run("Morphological Filters", "operation=Opening element=Disk radius=3");
			selectWindow("Image");
			close();
			selectWindow("Image-Opening");
			setBatchMode(false);			
			saveAs("Tiff", masksprep3_dir + "/" + list[d] + ".tif");
			close();
		showProgress(d, list.length);
		}
	}
}

File.openSequence(masksprep3_dir, "virtual");
			
	// STEP1.4 : CLEANING OF THE SEEDLING MASK
run("8-bit"); // If the manual crops disapears at when you change slice, click manually on Image/Type/8-bits before doing crop with "X"
waitForUser("Draw a rectangle area where the cotyledons are touching the hypocotyl and hit ctrl+X, repeat it slide by slide");			
waitForUser("SAVE as Image sequence in the 'MASKS' folder");
//run("Image Sequence... ", "format=TIFF use save=" + masks_dir);
close();
	
// ---------------------------------
// STEP2 : ANALYSIS OF THE SEEDLING SKELETON

if (File.exists(masks_dir)) {
	list = getFileList(masks_dir);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], ".tif")) {
	    	open(masks_dir + "/" + list[i]);
			
			// STEP2.1 : COMPUTATION OF THE SEEDLING SKELETON
			setBatchMode(true);
			rename("Image");
			
			run("Skeletonize (2D/3D)");
			run("Analyze Skeleton (2D/3D)", "prune=none prune calculate");
			
			// STEP2.2 : IMPROVEMENT
			selectWindow("Image");
			close();
			selectWindow("Tagged skeleton");
			close();
			selectWindow("Longest shortest paths");
			rename("image");
			//run("Threshold...");
			
			// WARNING: This threshold need sometimes to be adjusted is something went wrong
			setThreshold(16, 250);
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Dilate");
			run("Dilate");
			run("Dilate");
			run("Dilate");
			run("Erode");
			// WARNING: This particles size need sometimes to be adjusted is something went wrong
			run("Analyze Particles...", "size=2000-Infinity show=Masks exclude");
			selectWindow("image");
			close();
			selectWindow("Mask of image");
			rename("image");
			run("Create Selection");
			setBatchMode(false);
			
			// STEP2.3 : ANALYSIS OF THE SKELETON
			run("Geodesic Diameter", "label=image distances=[Chessknight (5,7,11)] show image=image export");
			saveAs("Tiff", skeleton_dir + "/" + list[i] + "-midline" + ".tif");
			close();
						
		showProgress(i, list.length);
		}
	}
}

// ---------------------------------
// STEP3 : ATTRIBUTION OF EACH ROI TO THE RIGHT IMAGE


for (i=0 ; i<roiManager("count"); i++) {
	// rename current ROI
	roiManager("Select", i);
	roiManager("Rename", leftPad(i, 4) + "-0000-0000");
	
	run("Clear Results");
}

run("Plots...", "width=1000 height=340 font=14 draw_ticks list minimum=0 maximum=0 interpolate");
roiManager("deselect");
roiManager("Multi Plot");
roiManager("Save", results_dir + File.separator + "RoiSet.zip");


selectWindow("Plot Values");
saveAs("Results", results_dir + File.separator + ".csv");
roiManager("reset");
selectWindow("Profiles");
saveAs("Tiff", results_dir + "/" + "profiles.tif");

if (isOpen(".csv")) {
     selectWindow(".csv");
     run("Close" );
}
if (isOpen("Results")) {
     selectWindow("Results");
     run("Close" );
}
if (isOpen("image-GeodDiameters")) {
     selectWindow("image-GeodDiameters");
     run("Close" );
}
if (isOpen("profiles.tif")) {
     selectWindow("profiles.tif");
     run("Close" );
}
selectWindow("Resultratio-2");
close();
print("Finished macro ! Check input folder for results.");

// fUNCTION THAT TRANSLATE A NUMERICAL VALUE TO A STRING
// ADDING ZEROS IN ORDER TO OBTAIN A FIXE NUMBER OF NUMBERS
// ExAmple: leftPad(12, 4) -> "0012"
function leftPad(i, width) {
   s = "" + i;
   while (lengthOf(s) < width)
      s = "0" + s;
    return s;
}