/*  
 * This macro calculates ratiometric FRET and NFRET values and displays the area of segmented cells.
 *    
 * Requirements: 
(1) Stack images (tif format) with 4 channels (3 fluorescence and 1 brightfield) and Stored Overlay or Selections in RoiManager 
(2) Autofluorescence/noise mean intensity for each channel to perform background correction (by subtraction) 
(3) Install the plugin ResultsToExcel -> Help >Update >ManageUpdate >ResultsToExcel >>> Restart Fiji __ More: https://imagej.net/User:ResultsToExcel
(4) Saved images in selected source file
 *   
 * Author: Sarah Lecinski, School of Physics, Engineering and Technology, and Dept.of Biology, University of York
 * Accessibility: Leake Group computational tools: https://github.com/york-biophysics/ImageJ-Macros
 * Associated paper: https://doi.org/10.1016/j.ymeth.2020.10.015
 * 
 */
 
requires("1.39r"); //necessary to use the is("composite") function
run("Set Measurements...", "area mean integrated display redirect=None decimal=3");
run("Close All");

titlesave = "ADD OUTPUT FILE TITLE HERE"

///--------  Dialogue box ---------//
#@ File(style="directory") Source_Directory
SavingPath1 = Source_Directory +"\\";
SavingPathforPlugin = replace(SavingPath1, "\\\\", "\\/") ;
#@ String (visibility=MESSAGE, value="<html><b>Autofluorescence/Noise Substraction:</b><br/>For each channel of your composite image, enter mean value to substract of the intensity mesured </html>", required=false) msg
#@ Integer(label="C1") BackgroudMeanC1
#@ Integer(label="C2") BackgroudMeanC2
#@ Integer(label="C3") BackgroudMeanC3

///__Batch mode setup

listFileInFolder = getFileList(SavingPath1);
Array.print(listFileInFolder);
//setBatchMode(true);

//___create and append value in a simple file

PathOnlyNfretDoc = SavingPath1+"1_"+titlesave+"_Nfret and Area_Table.csv";
HeadlineDoc = "File Name(image), Cell , Nfret Value, Area, Ratio-Fret/Donor ";
File.append(HeadlineDoc , PathOnlyNfretDoc); 

//___start Batch mode

for (b=0; b<lengthOf(listFileInFolder); b++) {
	filename = listFileInFolder[b];	
	print(filename);
	if (endsWith(filename, "tif")) {
		print(filename);
		print(SavingPath1);
		ImOpenPath = SavingPath1+filename ;
		print(ImOpenPath);
		ImOpenPathReady = replace(ImOpenPath, "\\\\", "\\/"); 
		print(ImOpenPathReady);
		open(ImOpenPathReady); // image is open macro start here
		print("done");
//////StartMacro//////////

		selectWindow(filename);
		Imagetitle = getTitle;
		//brightfield
		Brightfield = "C4-"+Imagetitle;		
		initialroiCount = roiManager("count");
		TestStack = is("composite");
		///__Get a stack/composite image if only one image loaded
		if (TestStack == true) {
			run("Split Channels");  
		}
			else {
				waitForUser("Composit image required", "Click OK when image replaced");
				Imagetitle =getTitle;
				run("Split Channels"); 
			}	
		//-------------------------------------------
		selectWindow(Brightfield);
		BrightfieldID = getImageID();
		/// Overlay and roiManager thing 
		if (Overlay.size != 0 ){
			run("To ROI Manager"); 
			initialroiCount = roiManager("count");
		}
			else {
				if (roiManager("count") == 0) {
				waitForUser("No selection","Create a ROI List and click OK to continue");
				initialroiCount = roiManager("count");
				}
			}		
		//-------------------------------------------
		///__Numerical sorting in roiManager 
		
		for (i=0; i<initialroiCount; i++) {	
			roiManager("select", i); 
			if ( i < 10 ) { 
				j="0"+i;
			}
				else { 
					j=i;
				}
			roiManager("rename", "cell-"+j+"_00");
		}
		//-------------------------------------------
		roiManager("deselect");

		///__measure intensity inside of selection for all frames except the brightfield

		for (i=0;i<nImages;i++) {
			selectImage(i+1);
			TestID = getImageID();
			if (TestID != BrightfieldID) {
				roiManager("Show All");
				roiManager("measure");
			}
		}
		roiManager("deselect");
		finalRoiCount = roiManager("count");
		//-------------------------------------------
		///__rewrite label and background substraction
		
		j = 0;
		x = 0; // to get value through the array for autofluorescence subsraction , as the value to substract needs to change when we change chanel
		AutoFluoarray = newArray(BackgroudMeanC1, BackgroudMeanC2, BackgroudMeanC3);
		
		for (i=0; i<nResults; i++) {
			roiManager("select",j); 
			InitialLabelName = getResultString("Label", i);
			Compositenumbername = substring(InitialLabelName, 0, 3); //get only the c1 c2 ect and remove the rest of the title
			newLabel = getInfo("roi.name");
		    setResult("Label", i, Compositenumbername+newLabel);
    		// substraction on all values and added in the result column
    		MeanAutoFluo = AutoFluoarray[x];
 		    MeanCorrected = getResult("Mean", i)-MeanAutoFluo;
 		    intDentCorrected = getResult("IntDen", i)-(getResult("Area", i)*MeanAutoFluo);
   		    setResult("Mean_NoiseCorrection", i, MeanCorrected);
   		    setResult(" IntDent_NoiseCorrection", i, intDentCorrected);    
    		j = j+1;
        		if (j == finalRoiCount) {
    				j=0;
    				x= x+1;
    			}
 		}
		//-------------------------------------------
		//Ratio and Nfret calculation
		
		for (i=0; i<initialroiCount; i++){
			roiManager("select",i);
			CellLabel = getInfo("roi.name");
			selectWindow("Results");
			Ifret = getResult("Mean_NoiseCorrection", initialroiCount+i);
			Idonor = getResult("Mean_NoiseCorrection", i);
			Iacceptor = getResult("Mean_NoiseCorrection", (2*initialroiCount)+i);
			Nfret = Ifret/sqrt(Idonor*Iacceptor); // Formula to calculate Nfret
			RatioFD = Ifret/Idonor;
			Area = getResult("Area", i); //extract the area
			setResult("CellLabel", i, CellLabel);
			setResult("Nfret Value", i, Nfret);
			// Ratio and Nfret and area values saved in the independant doc
			ToPrintinfile = Imagetitle+", "+CellLabel+", "+ Nfret+", "+ Area+", "+ RatioFD ; 
			File.append(ToPrintinfile, PathOnlyNfretDoc);
		}

		//run("Close All"); // close all images

		///__ Save the entire result table

		selectWindow("Results");
		run("Read and Write Excel", "no_count_column file=["+SavingPathforPlugin+"1"+titlesave+"_Result-table_Master_File.xlsx] stack_results");
		//run("Close");
		roiManager("deselect");
		//roiManager("delete");
///////// endMacro ////////
	}
}

showMessage("Batch analysis", "Run finished!");