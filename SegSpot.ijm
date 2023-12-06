/* 
 * SegSpot Macro: Spot detection, Spot count per cell, intensity and area measurement
 * 
 * Input: a microscopic image and RoiManager cell outlines 
 * Output: spot count table, measurement table, roiManager spot outlines
 * 
 * Installation: Save file under Fiji-win64>>Fiji.app>>plugins
 * 
 * Author: Sarah Lecinski, School of Physics, Engineering and Technology, and Dept.of Biology, University of York, 2023
 * Accessibility: Leake Group computational tools: https://github.com/york-biophysics/ImageJ-Macros
 *  
 */

// Set initial parameters
if (nImages == 0) {
	showMessage("Macro error", "There is no image open");
	exit
}
else {
	fileName = getInfo("image.filename");
	initialimagetitle= getTitle();
	StackSlice = nSlices;
	RoiCount = roiManager("count");
}
run("Set Measurements...", "area mean integrated display redirect=None decimal=3");
ChoicesChannel = newArray(1,2,3,4);
ChoiceThreshold = newArray("Default","Otsu","Huang","Minimum","Intermodes","MaxEntropy","RenyiEntropy","Yen"); 

// sest dialogue box
Dialog.create("Set parameters");
Dialog.addChoice("Automatic Threshold ", ChoiceThreshold);
Dialog.addCheckbox("Manual Threshold instead", false);
Dialog.addMessage("----To help segmentation----");
Dialog.addCheckbox("Add Background substraction (On a duplicate image - original untouched)", true);
Dialog.addNumber("if yes, rolling ball radius:", 10 );
Dialog.addMessage("--------");
Dialog.addChoice("Fluorescent channel", ChoicesChannel);
Dialog.addMessage("Dot size range");
Dialog.addNumber("Min size:", 0);
Dialog.addNumber("Max size:", 100);
Dialog.show();

Thresholdop = Dialog.getChoice();
ManualTresh = Dialog.getCheckbox();
RollingBall = Dialog.getCheckbox();
RBradius = Dialog.getNumber();
FluorescentChannel = Dialog.getChoice();
MinSize = Dialog.getNumber();
MaxSize = Dialog.getNumber();

C1 = "C1-"+initialimagetitle;
C2 = "C2-"+initialimagetitle;
C3 = "C3-"+initialimagetitle;
C4 = "C4-"+initialimagetitle;
ChoicesChannelName = newArray(C1,C2,C3,C4);
ImageAnalysedName = ChoicesChannelName[FluorescentChannel-1];


// Operation if stack image
selectWindow(initialimagetitle);
if (StackSlice != 1) {
	run("Split Channels"); 
	selectWindow(ImageAnalysedName);
	ImageAnalysedID = getImageID(); 
	}
	else { 
		selectWindow(initialimagetitle);
		ImageAnalysedID = getImageID(); 
	}

// Manage Overlay
if (Overlay.size != 0){
	run("To ROI Manager"); 
	RoiCount = roiManager("count");
}
	else {
		if (RoiCount == 0) {
			waitForUser("Create ROIs","Create ROI(s) and Click OK to continue \n if no ROI added, the entire image becomes the ROI");
			RoiCount = roiManager("count");
			if (RoiCount ==0){
				run("Select All");
				roiManager("Add");
				RoiCount = RoiCount+1;
			}
		}
	}	

// Set thresholding and binary mask
run("Select None");
selectImage(ImageAnalysedID);
run("Duplicate...", "title=---Duplicate");
selectWindow("---Duplicate");
if (RollingBall==true){
	run("Subtract Background...", "rolling="+RBradius);
}
run("Enhance Contrast...", "saturated=0.5 normalize");
run("Gaussian Blur...", "sigma=1");
if (ManualTresh==true){
	selectWindow("---Duplicate");
	waitForUser("make binary image");
	run("Make Binary");
	run("Convert to Mask");
	run("Fill Holes");
}
else {
	//setAutoThreshold("Minimum dark no-reset");
	setAutoThreshold(Thresholdop+" dark no-reset");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Fill Holes");
}

// Make table 
titleNewTab2 = "[Spot count table]"; 
run("New... ", "name="+titleNewTab2+" type=Table"); 
print(titleNewTab2,"\\Headings:Cell-Number \t Spot-count");

for (i=0; i<RoiCount; i++) { 
		RoiCountStart = roiManager("count");
		roiManager("select", i); 
		selectWindow("---Duplicate");
		run("Analyze Particles...", "size="+MinSize+"-"+MaxSize+" add");
		NewRoicount = roiManager("count");
		print(NewRoicount);
		SpotCount = NewRoicount - RoiCountStart;
		print(SpotCount);
		print(titleNewTab2, i +"\t"+SpotCount);
		RoiFirstSpot = NewRoicount - SpotCount;
		j = 1;
			for (k=RoiFirstSpot; k<NewRoicount; k++) { 
				roiManager("Select", k);
				roiManager("Rename", "Spot"+j+"_Cell"+i);
				j = j+1;
			}		
}

// Get Mesurement on original image
roiManager("Show None");
selectImage(ImageAnalysedID);
roiManager("Show All without labels");
roiManager("Deselect");
roiManager("Measure");
run("Tile");

//Display tables
selectWindow("Results");
selectWindow("Spot count table");
selectWindow("ROI Manager");
roiManager("show all");
