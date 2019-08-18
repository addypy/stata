/**************************************************** Quantitative Test Outline India *********************************************************************************

Name: Aditya Chhabra

Email: aditya0chhabra@gmail.com



*******************************************  INDEX  *********************************************************************************************************** 
Instructions

A.Preliminaries
1. Defining Globals(setting filepaths)
2. Importing

B. Cleaning
1. Renaming Variables
2. Preliminary Checking
3. Re-encoding
4. Further Checking
5. Checking and Correcting Inconsistencies across Variables
	A. Age & Age_codes
	B. Education Level
		(a) Extracting strings, categorisations, error checking & cleaning
		(b) Creating a Monotone increasing index of Education
6. Other Corrections
(a) Non-Problematic Variables (grouped ex-post)
(b) Problematic Variables
7. Other 
A. Re-scaling 6 point scale questions
B. Categorical Education Index
C. Dropping entries that lack credibility

C. Analysis
1. Labelling
2. Transformations 
3. Regression Loops
Regression loop 1 (quiet)
Regression loop 2
Regression loop 3 (quiet)
Regression loop 4
Regression loop 5 (quiet)
Regression loop 6

D. Graphical Representation
	1. Graph Loop 1 (All categorical Dummies)
		For 3 point scale questions 
		For 6 Point scale questions
	2. Graph Loop 2 (Education, Gender, Age, Possession)
		For 3 point scale questions
		For 6 Point scale question
E. Comment Analysis
	1. Basic Treatment
	2. Creating String based tags (and refining them through repetition)
	3. Labelling
	4. Comment Tag Plot loop
Optional
1.View saved graphs
2.Export graphs in png format	
********The End************************The End****************The End****************The End****************The End****************The End****************The End********





*******************************************************  INSTRUCTIONS  *********************************************************************************************************** 

If you wish to try this code out for yourself, please ENTER THE FOLLOWING DIRECTORIES of the Outline_India 
Test file specific to your Computer. 

It would be a wise to dedicate a separate folder for results, add the Parent file to this folder: ENTER this filepath in PATH




A. *************************************************** PRELIMINARIES *************************************************************************************************

	1. DEFINING GLOBALS 															*/

clear

set more off

global path =  "/Users/adityachhabra321996/Desktop/outline_india"


cd "$path"

// Do not bother changing this unless your file is named differently
global filename = "Quantitative Test_Outline India.xlsx"

/*
	2. IMPORT 
*/

import excel using "$path/$filename", sheet("Data") firstrow case(lower) clear



/*

****************************************************************************************************************************************************************************************************************************


B. ******************************************************   CLEANING   ************************************************************************************************************   

	1. RENAMING VARIABLES

Renaming for easier reference and integration of prefixes of variables that are similar in structure.
*/

rename surveylocation location 
rename f age_code
rename religionothers religion_oth
rename categoryothers category_oth
rename professionalstatus profession
rename professionalstatusothers profession_oth
rename highestlevelofeducationcomple edu_lev
*** Yes or No Questions ***
rename haveyouheardofaadharcard bin_aware
rename doyouhaveanaadharcard bin_own

*** mandate_ ***
*** the prefix mandate_ is  for referencing to all items/services for which this question was asked :
*** Q= Should an Aadhar card be mandatory for the following items?
*** Present coding : Y=1 N=2 Maybe=3
rename shouldaadharcardbemademandat idx_mandate
rename middaymealsingovtschools mandate_mmeal
rename mobilephoneconnections mandate_mob
rename openbankaccounts mandate_bank
rename drivinglicense mandate_dvrlic
rename fileincometaxpancard mandate_pan
rename collegedegree mandate_clg
rename passport mandate_pp
rename directcashtransferpension mandate_pension
rename directcashtransferlpg mandate_lpg
rename directcashtransfernrega mandate_nrega
rename directcashtransferscholarship mandate_scholar

*** scl_
*** the prefix scl_ is for referencing to all likert-scale based questions
*** how "satisfied/comfortable/etc" are you with the following :
*** Present coding : Very Negative=1, Somewhat Negative=2, Neutral=3, Somewhat Positive=4, Very Positive=5
rename howmucheasierwillanaadharca scl_lifeimp
rename doyouthinkaadharhasmadethe scl_accountability
rename howeasyorharddoyouthinkiti scl_procurement
rename howcomfortableoruncomfortable scl_discomfort
rename howmuchdoyoutrustthegovern scl_trust

*** cmt_
*** The prefix cmt_ is for all Comment based questions
*** These Columns have Natural language comments, which vary in language as well
rename whataccordingtoyouaretheove cmt_benefits
rename ah cmt_limitations
rename  whataccordingtoyouarethecha cmt_challenges

/*
	2. PRELIMINARY CHECKING															*/

drop aj ak
///Empty string vars^ that got imported
drop if location=="" & age==.
///Dropping empty Rows

codebook slno
codebook srno
codebook location

/// Since there are no people who identify as the third gender in this Sample, we can integrate this with the binary variables
/// Adding assert command so that we can be alerted by the code, should we use a different sample set
codebook gender
assert gender!=3
rename gender bin_gender

/*
	3. RE-ENCODING																	*/

/// New GENDER Coding : Male=1 Female=0
/// Similarly, for bin_aware(ie, "Have you heard of an Aadhar Card?" )
/// And, bin_possess(ie, "Do you possess an Aadhar Card")
/// replacing No with 0, Yes is already 1. Creating true binaries

foreach x of varlist bin* {
replace `x'=0 if `x'==2
}

///Re-encoding all Questions with YES|NO|MAYBE answers (MANDATE_*)
/// OLD-encoding= Y=1|N=2|M=3
/// NEW-encoding= Y=1|N=-1|M=0

foreach x of varlist mandate* {
replace `x'=-1 if `x'==2
}
foreach x of varlist mandate* {
replace `x'=0 if `x'==3
}


///Similarly, for what appears to be an index/aggregate for these questions
foreach x of varlist idx_mandate {
replace `x'=-1 if `x'==2
}
foreach x of varlist idx_mandate {
replace `x'=0 if `x'==3
}

/*
	4. FURTHER CHECKING								

CHECKING FOR EMPTY/SPARSE/CONSTANT variables								
																				*/

				/// Because Errors might stop the code from running if some Vars are
				///deleted during the analysis/ if the code is re-run but not from
				/// the beginning. 
				///~ capture~ surpresses errors from stopping the code
**
cap drop religion_oth 					/// No entries here.

**
cap codebook bin_aware 					
									///Implies that Everyone( in the Sample data) has heard about it 
cap drop bin_aware					
									///No variation, Constant, hence irrelevant
**
//dropping bad obs

///One Bad observation with age 2 & religion==7

drop if age<=7					
drop if religion>=7

cap gen err_tag=0


/*
	5. CHECKING & CORRECTING INCONSISTENCIES across Variables

		(A)
************************ Cross-validating Age / Age_codes **********************
																				*/

**************** Tagging Errors ****************	
											
gen age_err=0 								///tag for inconsitent age vis-a-vis age_codes

/*
Checking if age & age_code is consistent for codes 0-4]
Using the following equation, which represents a simple algebraic relationship b/w
Age & the intervals used in the Age_Codes column
																				*/
forval x=0/4 {
replace age_err=1 if ((age<18+11*(`x'-1))|(age>28+11*(`x'-1))) & age_code==`x'
quietly count if ((age<18+11*(`x'-1))|(age>28+11*(`x'-1))) & age_code==`x'
display "Obs with Age code `x' has `r(N)' errors"
}
//age_code=[5] does not have an upper limit 
replace age_err=1 if age<62 & age_code==5
count if age<62 & age_code==5 				///no errors here


/*
************* Correcting Age_code Errors *****************

Running a loop to CORRECT AGE_CODE [0-4] using Age. 

WHY?
ASSUMPTION-(assuming age is more accurate than age_code(categorical)!) 
EMPERICAL- (Cross-Validating with Education Level and/or Profession is also Fruitful & points to a higher accuracy oAge)
TECHNICAL-(Also, the function from age to age_code is not inversible)(ie, cannot map to a unique age value using a given age_code)
																				
																				*/
//Correction Loop for Codes 0/4
// Equation is similar to the one created to Tag errors earlier

foreach y of varlist age {
forval m=0/4 {
replace age_code=`m' if (age_err==1) & (6+(`m'*11)<`y') & (18+(`m'*11)>`y')
}
}

replace age_code=5 if age_err==1 & age>61     /////manual intervention for code5


************* Corrections Completed ******************

******************************************************

******************* Verifying ************************

//resetting err tag to check again
replace age_err=0

//running the Same error detection algorithm as above (for codes[0-4])
forval x=0/4 {
replace age_err=1 if ((age<18+11*(`x'-1))|(age>28+11*(`x'-1))) & age_code==`x'
quietly count if ((age<18+11*(`x'-1))|(age>28+11*(`x'-1))) & age_code==`x'
display "Corrected Age code `x' has `r(N)' errors"
}
count if age<62 & age_code==5 	//no errors here code[5]

assert age_err==0 																/////Assertion #

//If assertion is True, the error_tag can be dropped and we can move on 
drop age_err



/*

************** Age & Age_codes are now MUTUALLY CONSISTENT  ********************


********************************************************************************


			(B)
***************************** Education level **********************************
																				*/
//itrim() to Collapse multiple consecutive blanks into one blank
replace edu_lev= itrim(edu_lev)
// trimming trailing and leading blanks
replace edu_lev= trim(edu_lev)
//lowercase for uniformity if not already
replace edu_lev= lower(edu_lev)

/*
 Since the only available information on education is a String column with 
 irregularities, it is of no use to us in its present form

 So by extensively using Regular Expression commands, we CLEAN, EXTRACT, and 
 make it as HOMOGENEOUS as possible
						
																				*/

/*																				
				(a) ********************* EXTRACTING & CLEANING RELEVANT STRS 
  																				
1 ***********   ILLITERATE   **************				
																				*/
replace edu_lev="nil" if regexm(edu_lev,"ill")
replace edu_lev="nil" if edu_lev=="."
replace edu_lev="nil" if edu_lev==""


/* 
2 ***********   UPTO SCHOOL   *************
Regular expression search of 1 or 2 digit numbers at the beginning of string only
hence the use of ^ for only entries beginning with 1/2 Digit(s), 
such as "9th class, 10th pass, 9, 10, 5th," etc,
and neglecting entries such as " ba 1 year, bcom 2nd year" because of "^"
																				*/
																	
gen edu_school = regexs(0) if regexm(edu_lev,"^([0-9]|[0-9][0-9])+")

/*

3 ***********   Bachelors degrees   ***********	
 
BCOM/BBA/BA/BED/BA/BMUSIC/BTECH...ETC = searching "b" only at the beginning((^)) 
to avoid courses like MBA MA etc

//// This copies((Regex(0))) THE ENTIRE STRING if edu_lev starts with "b"									
																				*/

gen edu_deg_b= regexs(0) if regexm(edu_lev,"^(b.+)")

** Removing Dots [.], Spaces, Special characters, for Categorizations
//This Loop will iterate itself upto 20 times or until the condition is satisfied,
//whichever comes first. Useful when some commands may need to be iterated repeatedly 
// to solve the problem
//Punctuation iterator with conditional break: bachelors																				
forval i=1/20{
count if regexm(edu_deg_b,"[.]")!=0
local dots=r(N)
count if regexm(edu_deg_b," ")!=0
local spaces=r(N)
if (`dots'==0 & `spaces'==0){
display "All Dots & Blanks Removed after `i' iterations, Proceed"
continue, break
}
else {
display "The Variable edu_deg_b has `dots' dots & `spaces' blank spaces after `i' iterations" 
foreach y in edu_deg_b {
replace `y'= regexr(`y',"[.]","")
replace `y'= regexr(`y'," ","")
}
}
}


/*
Examples
(btech 1st year,  ba 2nd year) --> (btech, ba)

Extracting only the name of the degree, 
(just the first word that begins with (b^))
(this var used for the search already has the entire string (regex(0)) of all entries that start with "b")																								*/

gen edu_deg_b1= regexs(1) if regexm(edu_deg_b,"(^[a-z]+)")

//entries with "part1""part2"
replace edu_deg_b1 =regexr(edu_deg_b1,"(part*.)","")

/*
4 *********** Years of bachelor's degree completed *****************************
								
Wherever Year in  college, ie 1st year, 2nd year etc information is available,
it will be incorporated to make sure we use all information available
																				*/
gen edu_deg_b_year= regexs(1) if regexm(edu_deg_b,"([0-9]+)")

/*
5 *************** Double-Degree Bachelors ***************************************

Some individuals have mentioned second/parallel degrees, example, "ba+ bed"
																				*/
gen edu_deg_b2= regexs(1) if regexm(edu_deg_b,"[+]([a-z]+)")

/*
6 ************************** 	Diplomas ******************************************
																				*/
//Special Cases: diploma
replace edu_deg_b1=edu_lev if regexm(edu_lev,"^diploma")

/*
7 *************************** Masters degrees **********************************

only if at the start of string 
Note: it will also incorporate "mbbs" etc,

																				*/
gen edu_deg_m=""
replace edu_deg_m=edu_lev if regexm(edu_lev,"^m")

//Punctuation iterator with conditional break: Masters																			
forval i=1/20{
count if regexm(edu_deg_m,"[.]")!=0
local dots=r(N)
count if regexm(edu_deg_m," ")!=0
local spaces=r(N)
if (`dots'==0 & `spaces'==0){
display "All Dots & Blanks Removed after `i' iterations, Proceed"
continue, break
}
else {
display "The Variable edu_deg_m has `dots' dots & `spaces' blank spaces after `i' iterations" 
foreach y in edu_deg_m {
replace `y'= regexr(`y',"[.]","")
replace `y'= regexr(`y'," ","")
}
}
}																																								
																					
/*
8 ************************************ PHD ************************************* 
																				*/
gen edu_deg_doc="phd" if edu_lev=="phd"


/*
9 ************************** Special Case: MBBS *********************************
///MBBS is a bachelor's degree that begins with an ^M
																				*/
replace edu_deg_b1="mbbs" if edu_deg_m=="mbbs"
replace edu_deg_m="" if edu_deg_m=="mbbs"




********************************************************************************
/*  
	Erratic Entries

    3 Ambigious clustered entries,
   
	All from : karolbagh, 
	with great/gredeat/ great as a prefix before the name of course.
	possible interpretations- graduate, graduated, grad! two of these 
	are students acc to professional status code, one is not
	this person writes b2 as his qualification which is a language certification.
	however he is a salaried employee and great probably means grad, so putting 
	this down as a ba (a basic bachelor's degree)
	
	&
	
	entries left are ( . , phd, in.., voshpans? )
	vosh pans ~ das paas? 10th pass?
	
	& ii instead of 2 in years of degree completed
																				*/
******** Manual Corrections ******************

replace edu_deg_b1= "ba" if slno==249
replace err_tag=1 if slno==249 

replace edu_deg_b1= "bcom" if slno==250
replace err_tag=1 if slno==250

replace edu_deg_b1= "ba" if slno==264
replace err_tag=1 if slno==264

replace err_tag=1 if edu_lev=="vosh . pans"
replace edu_school="10"  if edu_lev=="vosh . pans"

replace err_tag=1 if edu_deg_b_year=="11"  
replace edu_deg_b_year="2" if edu_deg_b_year=="11"  

/* 
TAGGING ERROR COLUMN whenever corrections involve manual intervention & guesswork
these obs need to be treated as less accurate than others
																				*/

/* 
************************* CHECK ************************************************
Checking & finding no leftover obs. everything accounted for					
'No-observations' error code==2000, which is what we want
																				*/
capture {
codebook edu_lev if edu_school=="" & edu_deg_b1=="" & edu_deg_b2=="" & edu_deg_m=="" & edu_deg_doc=="" & edu_lev!="nil"
}
local rc = _rc
assert `rc'==2000																//assert #

//returns no obs																

/*

						(b)******************** CREATING AN EDUCATION INDEX

 

 POINTS
 Using information about (YEAR presently enrolled in/ YEARS completed) when 
 available considering 4 years of bachelors to be worth 1 point,
 Points are allotted as per YEARS in university
 the Norm in indian universities is, 
 3 years for a bachelors in science/arts/commerce,
 4 for btech, 
 5 for mbbs/llb, 
 2 or 3 for a diploma

Hence BA, BCOM, etc get (1+ 3/4)=1.75 points									*/

							///EMPTY INDEX///
gen edu_idx=.
						////Illiterate/////
							
replace edu_idx=0 if edu_lev=="nil"

						///// SCHOOL /////////
						
destring edu_school, replace
replace edu_idx=edu_school/12

/* 
	1 point for completing school, divided by 12 for proportional allocation of points

 every additional qualification gets +1 point. 
 so a doctorate would get 1 point each for completion of : 
			school+bachelors+masters+doctorate= 4

						///////Bachelors/////////                            
																				*/
destring edu_deg_b_year, replace

							
replace edu_idx=1+(3/4) if edu_deg_b1!="" & regexm(edu_deg_b1,"^bte")==0 & regexm(edu_deg_b1,"mbbs")==0 & regexm(edu_deg_b1,"^diploma")==0

					////// Double Bachelor cases   ////
					
replace edu_idx=1+2*(3/4) if edu_deg_b2!="" & regexm(edu_deg_b1,"^bte")==0 & regexm(edu_deg_b1,"mbbs")==0 & regexm(edu_deg_b1,"^diploma")==0

///checked manually and found only 3yr courses when information about YEAR OF STUDY was available
replace edu_idx=1+(edu_deg_b_year/4) if edu_deg_b_year!=.

						////// MBBS ///////
						
replace edu_idx=(1+5/4) if regex(edu_deg_b1,"mbbs")

						///////BTECH///////
						
replace edu_idx=1+(4/4) if regex(edu_deg_b1,"^bt")

					//////// Diploma  ///////
					
replace edu_idx=1+(2/4) if regexm(edu_deg_b1,"^diploma")

					////// Master's ///////
					
replace edu_idx=1+1+1 if edu_deg_m!=""

					////// PHD's //////
					
replace edu_idx=1+1+1+1 if edu_deg_doc!=""
replace edu_idx=0 if edu_idx==.



********************* EDUCATION_INDEX CREATED **********************************


********************************************************************************

/*
6.
********************* CORRECTING OTHER ERRORS **********************************

(a)
********** NON-PROBLEMATIC ************
Grouping NON-PROBLEMATIC vars together (ex-post)
																				*/
codebook religion		
codebook category		
codebook profession 
list age if profession==5 
																				/// Cross-validation # :(profession_code=retirement x age/age_code) 

/*
(b)
********** PROBLEMATIC  ************
																				*/
*1 
************* category_oth
codebook category_oth	
// has dot strings//
replace category_oth="" if category_oth=="." 
// dot str fixed //

list category if category_oth!=""
//checking consistency of category(5) category_oth. All have code =5 (others) as expected
codebook religion if category==5
/*
Confirms that all individuals with Blanks in category_oth variable when category==5 
are also Muslims, hence all category=5=others individuals are Muslims, 
we drop category_oth variable as it is INVARIANT
// Interpret category 5 (others) == Muslim, collinear with Religion==2 (Muslim)																	
																				*/

drop category_oth
																				
*2 
******* profession_oth
codebook profession_oth
//same dot string problem as above
replace profession_oth="" if profession_oth=="."
//fixed

//profession_oth should be non-empty only when profession_code=other
list profession profession_oth if profession_oth!="" & profession!=6
replace profession_oth="" if profession!=6
//merging shortform
replace profession_oth="Housewife" if profession_oth=="HW"
																				///Cross validation (housewife x gender) #
codebook bin_gender if profession_oth=="Housewife"

/*
*3
*************** idx_mandate

This is not an index by any measure.
Unclear about  what it represents.
methods considered: mean, median, mode. 
confirmed when encountered instances with all mandate question entries 
which were identical in values and order, however the suppossed index had different 
values for each														
																				*/
codebook idx_mandate																				
drop idx_mandate

/*
4.
**************** scl_discomfort

The question :
"How comfortable or uncomfortable are you with the government having access to 
your biometric data?" is a 
a decreasing level of comfort. 1=very comfortable ---> 5= very uncomfortable, it
constrasts with the other scl_vars which are all increasing in some positive 
aspect. scl_infocomfort is reverse coded and is interpreted as an increasing
comfort level

So new encoding:
1= very uncomfortable ---> 5= very comfortable
																				*/
gen scl_icomfort=.
foreach x in scl_discomfort {
replace scl_icomfort= `x'+2*(3-`x')
}
drop scl_discomfort

/*
********************************************************************************
7. Other 

(A) SCL_* RE-SCALING

replacing all scl vars from a scale of (1 2 3 4 5) to (-2, -1, 0, 1, 2) for 
integration & easier plotting with mandate_* & binary variables
																				*/
foreach x of varlist scl_* {
foreach z in `x' {
replace `z'=`z'-3 
}
}

/*
(B) Categorical Education Index 

(will be used for visual representation Later)
Since the somewhat continuous edu_idx numerical variable is more detailed than 
such a categorical variable, we will continue using edu_idx for our analysis and 
use the Categorical index only for graphical representation
*/

gen edu_interval=""
//not educated
replace edu_interval ="Illiterate" if edu_idx==0		
// upto class 6
replace edu_interval="Primary" if edu_idx>0 & edu_idx<=0.5 
// upto class 12
replace edu_interval="Secondary" if edu_idx<=1 & edu_idx>0.5 
/// enrolled / completed upto 4 years of a bachelor's degree
replace edu_interval="Higher" if edu_idx>1 & edu_idx<=2  
/// completed atleast 4 years of education after completing school (a 5 year bachelor's degree/masters/phd)
replace edu_interval="Advanced" if edu_idx>2 


/// also dropping education-related support variables
cap drop edu_deg* edu_school

/*
(C) Dropping Non-Credible Entries 

Entries that involved some manual intervention/ guesswork while correcting
*/
count if err_tag==1
// only 5 entries were tagged
drop if err_tag==1
drop err_tag



/*
C. ******************************************************   ANALYSIS     ******************************************************   


																						*/


		* 1 *******************************************  LABELS
label define binary 0 "Dont own an Aadhar Card" 1 "Own an Aadhar Card" 
label define threescale -1 "No" 0 "Maybe" 1 "Yes"
label define bin_gender 0 "Female" 1 "Male"
label define religion 1 "Hindu" 2 "Muslim" 3 "Sikh" 4 "Christian" 5 "Other" 6 "No Response" 
label define category 1 "General" 2 "ST" 3 "SC"  4 "OBC" 5 "Muslim(Other)" 6 "No Response"
label define profession 1 "Salaried employee" 2 "Self employed/business" 3 "Student" 4 "Unemployed " 5 "Retired" 6 "Other" 7 "No Response"
label define Age 0 "Below 18" 1 "Between 18 & 28 " 2 "Between 29 & 39" 3 "Between 40 & 50" 4 "Between 51 & 61" 5 "Above 62 "

label val age_code "Age"
label val bin_own "binary"
label val bin_gender "bin_gender"
label val religion "religion"
label val category "category"
label val profession "profession" 


foreach x of varlist mandate_* {
label val `x' "threescale"
}

/*
	      * 2 ************ TRANSFORMATIONS/ARRANGEMENT BY TYPE	
	  


					************ X Variables ************
				
				
					******* CONTINUOUS// SEMI-CONTINUOUS VARS*****

							1. edu_idx 2. age(age_sqrt) 
				
				
					****** CATEGORICAL Variables ********

			1. religion.(6) 2. category.(6) 3. location.(16) 4. profession.(6+2) 
			
		
						****** BINARY Variables ********
				
					      1. bin_gender 2. bin_own
																				*/
	
					******* SOME TRANSFORMATIONS **********
ladder edu_idx
/// leaving as is
ladder age
///transformation suggested for normality = sqrt has lowest chi2
gen age_sqrt= age^0.5
///separate regressions do show an increased rsquare

		******** TABULATIONS(DUMMY CREATION FOR CATEGORICAL VARIABLES) *******
						
tabulate location, gen(loc_)
tabulate religion, gen(rel_)
tabulate category, gen(cat_)
tabulate profession, gen(prof_)

order slno srno location bin* age* religion category profession profession_oth edu* mandate* scl* cmt*



/*
	      * 3 ************** REGRESSION LOOPS	************************ 
	  
																				*/
																				
/// Creating a list of all X_VARIABLES to be used repeatedly for multiple regressions
global xvar bin_gender bin_own age_sqrt edu_idx rel_1 rel_2 rel_3 rel_4 prof_1 prof_2 prof_3 prof_4 ///
prof_5 prof_6 prof_7 cat_1 cat_2 cat_3 cat_4 cat_5 cat_6 loc_1 loc_2 loc_3 loc_4 loc_5 loc_6 loc_7 ///
loc_8 loc_9 loc_10 loc_11 loc_12 loc_13 loc_14 loc_15 loc_16


/*

********************************************************************************
					RLOOP 1 (Quiet)
--------------------------------------------------------------------------------				
Description:
Regression loop for all Y-vars sequentially, on all X-vars given above, using 
OLS, Robust, Beta regressions, one at a time.
Stores in globals the following
R-Square Value: 
The Number of Significant Variables :

both referenced by the [Y variable]  and [Method of Estimation] used.
																				*/
foreach y of varlist mandate* scl*{
quietly regress `y' $xvar
local `y'ols_r2 = e(r2)
local `y'olsn = 0
foreach t in $xvar {
local `t'tval= _b[`t']/_se[`t'] 
if (``t'tval'>1.97 |``t'tval'<-1.97) & _b[`t']!=0{
local ++ `y'olsn
}
}
global `y'_olsR2= ``y'ols_r2'
global `y'_ols_V= ``y'olsn'
foreach method in robust beta {
quietly regress `y' $xvar , `method'
local `y'`method'_r2 = e(r2) 
local `y'`method'n =0
foreach m in $xvar {
local `m'tval= _b[`m']/_se[`m'] 
if (``m'tval'>1.97 |``m'tval'<-1.97) & _b[`m']!=0{
local ++ `y'`method'n
}
}
global `y'_`method'R2= ``y'`method'_r2'
global `y'_`method'_V= ``y'`method'n'
}
}


/*

********************************************************************************
				RLOOP 2
--------------------------------------------------------------------------------				
Description:
Prints on the screen/log file the R-square and the number of Statistically Significant
Variables corresponding to different choices of Regression for every Y variable     																				
																				*/
foreach y of varlist mandate* scl* {
display " 	Estimation Method   				 VARIABLE :  `y'   "
display ""
display "         	 		 R^2 VALUE(%)                              No. of statistically significant variables"
foreach method in ols robust beta {
display " 	 `method' "
global r`y'_`method'R2= round( ${`y'_`method'R2}*100 )
display " 				     	${r`y'_`method'R2} 					 	 ${`y'_`method'_V} "
display ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .. . . . . . . . ."
}
display "------------------------------------------------------------------------------------------------------------------------"
}

/*
COMMENTS
BETA Estimation is dominated by one of Robust or OLS for every Y-variable
Discarding the use of BETA Estimation from here on
																				*/
																				

																				
/*																				

********************************************************************************
				RLOOP 3 (Quiet)
--------------------------------------------------------------------------------				
Description:

Quietly extracts globals
[String of Significant Variables] :: ref by [Y variable][Method-Used]

[Beta Coefficients]		   :: ref by [Y variable][Method-Used] [Name of X-variable]
																				*/
foreach y of varlist mandate* scl* {
quietly regress `y' $xvar
foreach t in $xvar {
local `t'tval= _b[`t']/_se[`t'] 
if (``t'tval'>1.97 |``t'tval'<-1.97) & (_b[`t']!=0|_b[`t']!=.) {
global olssv`y' ${olssv`y'} `t' 
global `y'`t'ocf= _b[`t']
}
}
quietly regress `y' $xvar, robust
foreach r in $xvar {
local `r'tval= _b[`r']/_se[`r'] 
if (``r'tval'>1.97 |``r'tval'<-1.97) & (_b[`r']!=0|_b[`r']!=.) {
global robustsv`y' ${robustsv`y'} `r'  
global `y'`r'rcf= _b[`r']
}
}
}

/*
********************************************************************************
				RLOOP 4
--------------------------------------------------------------------------------				
Description: 
Displays the significant variables for both methods and for all Y variables
																				
foreach y of varlist mandate_* scl_* {
display " 				Significant Variables for `y'			"
display " 	OLS   "
di""
display "	 ${olssv`y'}         " 
display " . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "
display " 	ROBUST   "
di""
display "	 ${robustsv`y'}         " 
display "-----------------------------------------------------------------------"
}
*/
///shows duplicate values, better method below


/*

********************************************************************************
				RLOOP 5 (Quiet)
--------------------------------------------------------------------------------				
Description:

[R^2 values] are invariant across regression techniques for this data

So we consider only [the number of significant variables] for every technique
to decide the best method for the particular [Y variable]
Generating Globals of
[the highest number of Signficant Variables achievable] : reference reqd to [Y] only
[The method applicable for maximizing ^] : reference reqd to [Y] only
																				*/
foreach y of varlist mandate_* scl_* {
global maxSV`y'= max(${`y'_ols_V},${`y'_robust_V}, ${`y'_beta_V})
foreach method in  ols robust{
if ${`y'_`method'_V} == ${maxSV`y'} {
global methodmaxSV`y' `method'
di "`y'     :			 ${methodmaxSV`y'}"
break
}
}
}


/*

********************************************************************************
				RLOOP 6
--------------------------------------------------------------------------------				
Description: 
Displays for every [Y variable] 

[The best Method]
[R2]
[Significant X-vars using Best Method]
[Beta Coefficients]
*/
foreach y of varlist mandate* scl* {
di "------------------------------------------------------------------------------------"
di ""
display "VARIABLE: `y'" 
di ""
di ""
if `"${methodmaxSV`y'}"'=="robust"  {
display "Method Used : ROBUST"
di ""
di "R-Square: ${r`y'_robustR2} % " 
di""
di "................................................................................"
di "X-Variables 			Robust Beta Coefficient (if significant) "
di "................................................................................"
di ""
foreach z in $xvar {
if regexm("${robustsv`y'}","`z' ") {
display "  `z'  "
display "						${`y'`z'rcf} "
di ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "
}
else {
}
break
}
}
if `"${methodmaxSV`y'}"'=="ols" {
display "Method Used : OLS"
di "R-Square: ${r`y'_olsR2} %"
di ""
di "................................................................................"
di "X-Variables 			OLS Beta Coefficient (if significant) " 
di "................................................................................"
di ""
foreach x in $xvar {
if regexm("${olssv`y'}","`x' ") {
display "  `x' "
display "      					${`y'`x'ocf} "
di ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "
}
else{
}
break
}
}
}



*********************************************************************************************************************************************************



/* 

D. ************************************* GRAPHICAL REPRESENTATION **********************************************************************************************


*/


// checking & correcting labels for chart titles
desc mandate_*
/// labels are fine here
desc scl_*
////essential labels
label var scl_icomfort "How comfortable are you with the government having access to biometric data?"
label var scl_accountability "Do you think Aadhar has made the government more accountable?"
label var scl_procurement "How easy do you think it is to get an Aadhar card?"



/*
************************** IMPORTANT************************** IMPORTANT************************** IMPORTANT************************** IMPORTANT**************************

The code in the lines below uses the above regression results to plot a LOT OF GRAPHS using 
the list of significant variables found using either Robust or OLS estimation.

It then Combines only the relevant categorical dummies  of each categorical variable
After this step, it immediately discards all individual graphs which it combines.

PLEASE MAKE SURE
1. YOU HAVE SPECIFIED A SEPARATE FOLDER IN THE PATH AT THE BEGINNING
2. DO NOT SKIP OVER THE GRAPHICS OFF CODE JUST BELOW



Note: If the Execution stops here and returns an error code rc=603,
	Just change the working directory, accessible from `File'--> on your Toolbar above
	and run the do file again.
																				*/

																			
************************************************************************************************************************************************************



set graphics off



/*
****************************************************************************************************************************************************************** 
								GRAPH LOOP1
******************************************************************************************************************************************************************

*/


** A. QUESTIONS OF A THREE POINT SCALE (YES, NO, MAYBE)
																	
foreach y of varlist mandate_*  {
if `"${methodmaxSV`y'}"'=="robust" {
foreach z in $xvar {
if regexm("${robustsv`y'}","`z' |`z'") {
graph hbar (mean) `y' if `z'==1 , asyvars ytitle(`: variable label `z'') ymticks(-1(0.5)1) yline(0) legend(off) ///
 nodraw saving(`y'_`z'_r.gph , replace)
break
}
}
break
}
else if `"${methodmaxSV`y'}"'=="ols" {
foreach o in $xvar {
if regexm("${olssv`y'}","`o' |`o'") {
graph hbar (mean) `y' if `o'==1 , asyvars ytitle(`: variable label `o'')  ymticks(-1(0.5)1) yline(0) legend(off) ///
nodraw saving(`y'_`o'_o.gph , replace)
break
}
}
break
}
foreach topic in rel cat loc prof {
quietly graph dir `y'_`topic'_*
local sep `r(list)'
capture noisily graph combine `sep', ycommon xcommon  col(1) /*
*/ caption("{bf: Should an Aadhar Card be Mandatory for}" "{bf:`: variable label `y''}", box bexpand size(*0.95) justification(center)) /*
*/ title("{it: NO					Maybe					Yes}", span justification(center)) nodraw saving(C_`y'_`topic'.gph, replace)
if _rc!=4027 {
foreach x in `sep' {
cap graph drop `x'
cap erase `x'
}
}
}
}


** B. QUESTIONS OF A 6 POINT SCALE


foreach y of varlist scl_*  {
if `"${methodmaxSV`y'}"'=="robust" {
foreach z in $xvar {
if regexm("${robustsv`y'}","`z' |`z'") {
graph hbar (mean) `y' if `z'==1 , asyvars ytitle(`: variable label `z'') ymticks(-2(1)2) yline(0) legend(off) ///
nodraw saving(`y'_`z'_r.gph, replace)
break
}
}
break
}
else if `"${methodmaxSV`y'}"'=="ols" {
foreach o in $xvar {
if regexm("${olssv`y'}","`o' |`o'") {
graph hbar (mean) `y' if `o'==1 , asyvars ytitle(`: variable label `o'') ymticks(-2(1)2) yline(0) legend(off) ///
 nodraw saving(`y'_`o'_o.gph, replace)
break
}
}
break
}
foreach topic in rel cat loc prof  {
quietly graph dir `y'_`topic'_*
local sep `r(list)'
capture noisily graph combine `sep', ycommon xcommon  col(1) ///
caption("{bf: `: variable label `y''}", size(*.8) box bexpand justification(center)) ///
title("<- {it: Not at all  -  Not really   -  Neutral  -   Somewhat  -  Very} - >", size(*0.95) justification(center) span) ///
nodraw saving(C_`y'_`topic'.gph, replace)
if _rc!=4027 {
foreach x in `sep' {
cap graph drop `x'
cap erase `x'
}
}
}
}




/*
******************************************************************************************************************************************************************
												GRAPH LOOP 2
******************************************************************************************************************************************************************
This loop is to graph separately variables that differ in structure from our categorical dummies
For example, we have 

// binaries-
 gender & possession

// continuous/semi-continuous-
 Age & Educational level 
For these we will use their categorical equivalents 


																				*/

																				
																				
																				
/// A. 3 POINT SCALE : YES NO MAYBE
																				
capture noisily {
foreach y of varlist mandate*  { 
quietly graph dir `y'_* 
local spill `r(list)'
foreach x in `spill' {
if regexm("`x'","^`y'_bin_own") {
graph hbar (mean) `y', over(bin_own, axis(off) sort(1))  blabel(name, pos(outside)) asyvars ymticks(-1(0.5)1) /*
*/ nodraw title("{it: <-- NO				Maybe				Yes -->}", span justification(center)) ///
caption("Do you have an Aadhar Card?", ring(0)) yline(0) legend(on) ///
ytitle("Should an Aadhar Card be Mandatory for" "`: variable label `y''") saving(F_`y'_own.gph, replace)
continue
}
if regexm("`x'","^`y'_bin_gender") {
graph hbar (mean) `y', over(bin_gender, axis(off) sort(1))  blabel(name, pos(inside) color(white)) ymticks(-1(0.5)1) /*
*/ asyvars nodraw title("{it: <-- NO				Maybe				Yes -->}", span justification(center)) ///
caption("Gender", ring(0)) yline(0) legend(on) ytitle("Should an Aadhar Card be Mandatory for" "`: variable label `y''") saving(F_`y'_gender.gph, replace)
continue
}
if regexm("`x'","^`y'_age_sqrt") {
graph hbar (mean) `y', over(age_code, axis(off) sort(1) )   blabel(name, pos(outside)) asyvars ymticks(-1(0.5)1) /*
*/ nodraw title("{it: <-- NO				Maybe				Yes --> }", span justification(center)) /*
*/ caption("Age", ring(0)) yline(0) legend(on) ytitle("Should an Aadhar Card be Mandatory for" "`: variable label `y''") saving(F_`y'_age.gph, replace)
continue
}
if regexm("`x'","^`y'_edu_idx") {
graph hbar (mean) `y', over(edu_interval, axis(off) sort(1))   blabel(name, pos(outside)) asyvars ymticks(-1(0.5)1) /* 
*/ nodraw 	title("{it: <-- NO				Maybe				Yes --> }", span justification(center)) /*
*/ caption("Highest Level of Education", ring(0)) yline(0) legend(on) /* 
*/ ytitle("Should an Aadhar Card be Mandatory for" "`: variable label `y''") saving(F_`y'_edu.gph, replace)
continue
}
else {
display " Check for `x' "
}
quietly graph dir `y'_*
local dump `r(list)'
foreach d in `dump' {
cap graph drop `d'
cap erase `d'
}
}
}
}

//// B. LIKERT SCALE QUESTIONS

capture noisily {
foreach y of varlist scl* {
quietly graph dir `y'_*
local spill `r(list)'
foreach x in `spill' {
if regexm("`x'","^`y'_bin_own") {
graph hbar (mean) `y', over(bin_own, axis(off)  sort(1)) blabel(name, pos(outside))  asyvars nodraw /*
*/title("<- {it: Not at all  -  Not really   -  Neutral  -   Somewhat  -  Very} - >", size(*0.95) /*
*/justification(center) span) caption("Do you have an Aadhar Card?", ring(0) size(*.8))  yline(0) ymticks(-2(1)2) legend(on) /*
*/ytitle("`: variable label `y''") saving(F_`y'_own.gph, replace)
continue
}
if regexm("`x'","^`y'_bin_gender") {
graph hbar (mean) `y', over(bin_gender, axis(off)  sort(1)) blabel(name, pos(inside) color(white))  asyvars nodraw /*
*/ title("<- {it: Not at all  -  Not really   -  Neutral  -   Somewhat  -  Very} - >", size(*0.95) /*
*/ justification(center) span) caption("Gender", ring(0) size(*.8))  yline(0) ymticks(-2(1)2) legend(on) /*
*/ ytitle("`: variable label `y''") saving(F_`y'_gender.gph, replace)
continue
}
if regexm("`x'","^`y'_age_sqrt") {
graph hbar (mean) `y', over(age_code, axis(off)  sort(1)) blabel(name, pos(outside))  asyvars nodraw /*
*/ title("<- {it: Not at all  -  Not really   -  Neutral  -   Somewhat  -  Very} - >", size(*0.95) justification(center) span) /*
*/  ymticks(-2(1)2) caption("Age" , ring(0) size(*.8) )  ytitle("`: variable label `y''")  saving(F_`y'_age.gph, replace) 
continue
}
if regexm("`x'","^`y'_edu_idx") {
graph hbar (mean) `y', over(edu_interval, axis(off)  sort(1)) blabel(name, pos(outside))  asyvars nodraw /*
*/ title("<- {it: Not at all  -  Not really   -  Neutral  -   Somewhat  -  Very} - >", size(*0.95) /*
*/ justification(center) span) caption("Highest Level of Education", ring(0) size(*.8) )  yline(0) ymticks(-2(1)2)  /*
*/ legend(on) ytitle("`: variable label `y''") saving(F_`y'_edu.gph, replace)
continue
}
else {
display " Check for `x' "
}
quietly graph dir `y'_*
local dump `r(list)'
foreach d in `dump' {
cap graph drop `d'
cap erase `d'
}
}
}
}



*********************************************************************************************************************************************************



/*

E. ************************************************* COMMENT ANALYSIS & PLOT *********************************************************************************

																								
*********************************************************************************************************************************************************
																				*/
* 1. BASIC TREATMENT																				
/// dropping double-blanks, leading & trailing blanks

foreach x in benefits limitations challenges {
foreach y in cmt_`x' {
replace `y'=itrim(`y')
replace `y'=trim(`y')
replace `y'=lower(`y')
}
}


*********************************************************************************************************************************************************

/*

 2. GENERATING A THREE POINT TAG

Using regular expression matching, we cast wide NETS that `catch' all relevant 
words. we extend & refine this NET every time we match by adding words/ expressions
used from our previously matched entries in the same context.
Each time we do this our NET improves and leads us to better matching.

+1= Positive comment
-1= Negative comment

0=BOTH positive & negative comments for the same topic

.= missing if no relevant comment

** check report for detailed info
																				*/


gen tag_lpg=.

local lpgstr "lpg|gas|subsidy"

replace tag_lpg=1 if regexm(cmt_benefits,"`lpgstr'")
replace tag_lpg=-1 if (regexm(cmt_limitations,"`lpgstr'") | regexm(cmt_challenges,"`lpgstr"))
replace tag_lpg=0 if regexm(cmt_benefits,"`lpgstr'") & ( regexm(cmt_limitations,"`lpgstr'") | regexm(cmt_challenges,"`lpgstr"))
gen tag_bank=.

local bankstr "bank |a/c|a /c|acc|kha+ta"
replace tag_bank=1 if regexm(cmt_benefits,"`bankstr'")
replace tag_bank=-1 if (regexm(cmt_limitations,"`bankstr'") | regexm(cmt_challenges,"`bankstr'"))
replace tag_bank=0 if regexm(cmt_benefits,"`bankstr'") & (regexm(cmt_limitations,"`bankstr'") | regexm(cmt_challenges,"`bankstr'"))

gen tag_mobile=.

local mobstr "mob|sim|phone"
replace tag_mobile=1 if regexm(cmt_benefits,"`mobstr'")
replace tag_mobile=-1 if (regexm(cmt_limitations,"`mobstr'") | regexm(cmt_challenges,"`mobstr'"))
replace tag_mobile=0 if regexm(cmt_benefits,"`mobstr'") & (regexm(cmt_limitations,"`mobstr'") | regexm(cmt_challenges,"`mobstr'"))

gen tag_id=.

local infostr1 "pan|lic|passport|id|proof|id |addr|"
local infostr2 "driv| dl |pehcha+n|private|data|info|"
local infostr3 "misuse|identity|print|doc"

local info_str "`infostr1'`infostr2'`infostr3'"

replace tag_id=1 if regexm(cmt_benefits,"`info_str'")
replace tag_id=-1 if (regexm(cmt_limitations,"`info_str'") | regexm(cmt_challenges,"`info_str'"))
replace tag_id=0 if regexm(cmt_benefits,"`info_str'") & (regexm(cmt_limitations,"`info_str'") | regexm(cmt_challenges,"`info_str'"))


gen tag_pension=.
local pensionstr "pens?t?ion|vridh"
replace tag_pension=1 if regexm(cmt_benefits,"`pensionstr'")
replace tag_pension=-1 if (regexm(cmt_limitations,"`pensionstr'") | regexm(cmt_challenges,"`pensionstr'"))
replace tag_pension=0 if regexm(cmt_benefits,"`pensionstr'") & (regexm(cmt_limitations,"`pensionstr'")| regexm(cmt_challenges,"`pensionstr'"))

gen tag_crime=.
local crimestr "crime|chor|fraud|prev"
replace tag_crime=1 if regexm(cmt_benefits,"`crimestr'")
replace tag_crime=1 if (regexm(cmt_limitations,"`crimestr'") | regexm(cmt_challenges,"`crimestr'"))
replace tag_crime=0 if regexm(cmt_benefits,"`crimestr'") & (regexm(cmt_limitations,"`crimestr'") | regexm(cmt_challenges,"`crimestr'"))

gen tag_accountability=.
local accountstr "transp|transper|bhrasht|brasht|bersth|barast|accountab|corrup"
replace tag_accountability=1 if regexm(cmt_benefits,"`accountstr'")
replace tag_accountability=-1 if (regexm(cmt_limitations,"`accountstr'") | regexm(cmt_challenges,"`accountstr'"))
replace tag_accountability=0 if  regexm(cmt_benefits,"`accountstr'") & (regexm(cmt_challenges,"`accountstr'")|regexm(cmt_limitations,"`accountstr'"))

gen tag_comfort=.

local comfort_str1 "time|samay|jaldi|late|kira|problem|office|der"
local comfort_str2 "money|corr|broker|[0-9]|[0-9][0-9]|[0-9][0-9][0-9]|doc|delay"
local comfort_str3 "ba+r |a+sa+n|addr|mis?d?take|gala?t|proof|print|rs|rup|pais|charge"
local comfort_str4 "sign|paper|ka+g?a+|forma?l|line|public|janta|karv?w?ai|do+ba+ra|chak+ar"

local comfort_str "`comfort_str1'|`comfort_str2'|`comfort_str3'|`comfort_str4'"

replace tag_comfort=1 if regexm(cmt_benefits,"`comfort_str'")
replace tag_comfort=-1 if (regexm(cmt_limitations,"`comfort_str'") | regexm(cmt_challenges,"`comfort_str'"))
replace tag_comfort=0 if regexm(cmt_benefits,"`comfort_str'") & (regexm(cmt_limitations,"`comfort_str'") | regexm(cmt_challenges,"`comfort_str'"))

gen tag_school=.
local schoolstr "ad+mis+|school|bach"
replace tag_school=1 if regexm(cmt_benefits,"`schoolstr'")
replace tag_school=-1 if (regexm(cmt_limitations,"`schoolstr'") | regexm(cmt_limitations,"`schoolstr'"))
replace tag_school=0 if regexm(cmt_benefits,"`schoolstr'") & (regexm(cmt_limitations,"`schoolstr'") | regexm(cmt_limitations,"`schoolstr'"))

foreach x of varlist tag_*  {
summ `x' if `x'!=.
}

/*
*********************************************************************************************************************************************************
3. LABELS
*** Adding Labels to Values
// Gets a Negative label if it is mentioned in one of the two critical columns
// Gets a Positive label if it is mentioned in the "benefit" column
// Gets 0, (both) if it has been talked about in both negative & positive connotations
// that is, if the topic is mentioned in the benefit column and atleast one of the two critical columns
																				*/

label define tag -1 "Negative" 0 "Both" 1 "Positive"
foreach t of varlist tag_*  {
label values `t' "tag"
}


*** Adding labels to Tag counts for Graphical representation

label var tag_comfort "Comments about the discomfort/ ease of getting an Aadhar Card"
label var tag_school "Comments about Aadhar for School Admissions"
label var tag_accountability "Forecasts aboutcorruption/ accountability because of Aadhar"
label var tag_crime "Forecasts about criminal activity because of Aadhar"
label var tag_pension "Comments about the discomfort/ ease of gettng pensions because of Aadhar"
label var tag_mobile "Comments about Aadhar's role while getting Mobile phone connections"
label var tag_lpg "Comments about the discomfort/ ease of getting LPG subsidies because of Aadhar "
label var tag_bank "Comments about Aadhar's role while managing banking activities"
label var tag_id "Comments/ Concerns about Aadhar's role in managing identities"


/*

****************************************************************************************************
4.									COMMENT PLOT LOOP


This loop first checks if the opinion about a relevant topic diverges or is uniform
if it is uniformly appreciative, there are no criticisms and the graph will not be informative

It then plots horizontal bars for topics of atleast some DIVERGENCE IN OPINIONS, using all the predictor
variables we have with us, the binary variables, and all our categorical variables

It then combines two topics at a time and erases the rest to conserve memory

																				*/
foreach y of varlist tag_* {
quietly summ `y' 
local minim=r(min)
if `minim'!=-1 {
display " The filter `y' shows that this topic has no criticisms, only appreciative comments "
break
}
else {
foreach x in location religion bin_gender bin_own age_code edu_interval category profession {
graph hbar (mean) `y', over(`x', sort(1)) asyvars  blabel(name, pos(inside) color(white)) caption(" `x'", ring(0)) ///
legend(off) nodraw title("Criticism    		              Appreciation", span justification(center)) ///
ytitle("") yline(0)   ymticks(-1(0.5)1) saving(`y'_`x'.gph, replace)
}
graph combine `y'_bin_own.gph `y'_bin_gender.gph , caption("`: variable label `y''", justification(center)) c(1) nodraw saving(cmt_`y'_bin.gph, replace)
graph combine `y'_religion.gph `y'_category.gph, , caption("`: variable label `y''", justification(center)) r(1) nodraw saving(cmt_`y'_catrel.gph, replace)
graph combine `y'_age_code.gph `y'_edu_interval.gph , caption("`: variable label `y''", justification(center)) r(1) nodraw saving(cmt_`y'_ageedu.gph, replace)
graph combine `y'_location.gph `y'_profession.gph , caption("`: variable label `y''", justification(center)) r(1) nodraw saving(cmt_`y'_locprof.gph, replace)
}
quietly graph dir `y'_*
local cmdrop `r(list)'
foreach c in `cmdrop' {
cap drop `c'
cap erase `c'
}
}



*********************************************************************************************************************************************************


/*

																			Optionals
*********************************************************************************************************************************************************																			

1. if you wish to view any of the graphs created, you may do that by setting graphics on

set gr on

graph dir

2. if you want to export the gph images to view separately as gph files. here is the export code to easily export them all

set gr on
set more on

graph dir 
local exp `r(list)'

global graphpath "$path/graphs"

foreach x in `exp' { 
if regexm("`x'",".gph$") {
local px="`x'"
local px=regexr("`px'","gph","png")
graph use `x'
graph export "$graphpath/`px'", replace
erase `x'
}
else {
break
}
}










************************************************************ CODE ENDS ****************************************************************************************************


***********************************************************************************************************************************************************************************
