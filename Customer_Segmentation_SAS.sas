

/*Customer Segmentation SAS Code*/

/*Using default workspace as our working directory*/
/*Import the data*/
proc import datafile="C:\Users\Amit Bhalerao\Documents\UIC Course work Fall'16\SAS\Project 2\DemoData.csv"
out=DemoData dbms=csv replace;

/*check the missing values in data*/
proc means data=DemoData n nmiss maxdec=0;
run;

/*setting mean value to the missing data*/
proc standard data=DemoData replace out=DemoData;
run;

/*correlation matrix before factor analysis*/
proc corr data=DemoData rank;
run;

/*Factor analysis normal standardization*/
proc standard data=DemoData out=DemoData_std mean=0 std=1;
run;

/*making factors number=5 */
proc factor data=DemoData_std rotate=varimax scree nfactors=5 fuzz=.4;
run;

/*create scores to check strength of factors*/
proc factor data=DemoData_std rotate=varimax scree nfactors=5 fuzz=.4 out=DemoData_factors;
run;

/*Cluster Analysis starts*/
options pageno=1;

/*Macro to randomize centroids*/
%macro loop (c);
options nomprint ;

%do s=1 %to 10;
%let rand=%eval(100*&c+&s);
proc fastclus data=DemoData_factors out=clus&Rand cluster=clus maxclusters=&c
converge=0 maxiter=200 replace=random random=&Rand;
ods output pseudofstat=fstat&Rand (keep=value);
var factor1--factor5;
title1 "Clusters=&c, Run &s";
run;
title1;

proc freq data=clus&Rand noprint;
tables clus/out=counts&Rand;
where clus>.;
run;
proc summary data=counts&Rand;
var count;
output out=m&Rand min=;
run;

data  Stats&Rand;
label count=' ';
merge fstat&rand
      m&rand (drop= _type_ _freq_)
	  ;
Iter=&rand;
Clusters=&c;
rename count=minimum value=PseudoF;
run;

proc append base=ClusStatHold data=Stats&Rand;
run;
%end;
options nomprint;
%Mend Loop;

/*Macro to iterate k between 4 to 9*/
%Macro OuterLoop;
proc datasets library=work;
delete ClusStatHold;
run;
%do clus=4 %to 9;
%Loop (&clus);
%end;
%Mend OuterLoop;

%OuterLoop;

/*graph to check pseudoF and decide k*/
proc gplot data=ClusStatHold;
plot pseudoF*minimum/haxis=axis1;
symbol value=dot color=blue pointlabel=("#clusters" color=black);
axis offset=(5,5)pct;
title "F by Min for Clusters";
run;
title;
quit;

/*Clusters with k=6 decided as the best and to go forward with*/
proc sort data=clus610;
by zipcode;
run;

/*saving clustered data separately */
data cluster_vars;
merge clus610 (keep=zipcode factor1--factor5 clus in=a) prefactor (in=b);
by zipcode;
run;
