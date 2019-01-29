#Molecule Interaction Analycal Tool

# Lin Li:
# This tool is used to calculate electric field, forces, energy for a 2-atom system. The usage is:
# Usage: ./DelPhiForce.sh file1 file2 output_file
# file1 is a reference molecule, file2 is the prob molecule
# After the run, you will get an output_file.residue 

# Arhya Chakravorty
# Made some modifications to the existing code to allow paths to the scripts being called in the program. 
# Command line flags were added and a help message has been developed for that.
# User can chose the didlectric assignment method (Homogeneous/Gaussian).
# PairwiseInteractions can also be calculated between residue(s).

echo -e "\n"
echo -e "###################################################################################################"
echo -e "#### DelPhiForce is used to calculate electric field, forces, energy between two molecules.    ####"
echo -e "#### Please cite this paper:                                                                   ####"
echo -e "#### Lin Li, Arghya Chakravorty, and Emil Alexov. \"DelPhiForce, a tool for electrostatic       ####" 
echo -e "#### force calculations: Applications to macromolecular binding.\"                              ####"
echo -e "#### Journal of Computational Chemistry 38.9 (2017): 584-593.                                  ####"
echo -e "###################################################################################################"

help="Usage: ./DelPhiForce.sh \n\n \
      -1 \t\t Input structure file 1 (Field) (REQUIRED). \n\n \
      -2 \t\t Input structure file 2 (Probe) (REQUIRED WHEN PAIRWISE MODE IS OFF). \n\n \
      -o \t\t Output File Name (.* will be removed) (REQUIRED). \n\n \
      -d \t\t Nature of dielectric assignment (0 = homo/1 = gauss) (DEFAULT = 0). \n\n \
      -c \t\t Salt Concentration (M) (DEFAULT = 0.15) \n\n \
      -s \t\t Scale for Delphi run (grids/Angstroms) (DEFAULT = 2.0) \n\n \
      -e \t\t Path to Delphi executable (REQUIRED). \n\n \
      -x -y  \t\t Two text files respectively that contain the residue indices for the source/probe residues \n\n \
      -h \t\t Print this help message \n\n"

while getopts ":1:2:o:d:h:e:x:y:s:c:" opt;
do
    case $opt in
    1) infile1=$OPTARG
        echo "FIELD FILE 1: $infile1"
        if [ ! -e $infile1 ]
        then
            echo -e "NO SUCH FILE FOUND: $infile1\n\n"
            exit 1
        fi
        ;;
    2) infile2=$OPTARG
        echo "PROBE FILE 2: $infile2"
        if [ ! -e $infile2 ]
        then
            echo -e "NO SUCH FILE FOUND: $infile2\n\n"
            exit 1
        fi
        ;;
    o)  outfile=`echo $OPTARG | sed 's/\.[a-zA-Z0-9]*$//g'`
        ;;
    d)  dielec=$OPTARG
        if [ $dielec -eq 0 ] 
        then
          echo -e "WILL USE TRADITIONAL 2-DIELECTRIC DITRIBUTION"
        elif [ $dielec -eq 1 ]
        then
          echo -e "WILL USE GAUSSIAN SMOOTH DIELECTRIC DITRIBUTION"
        else
          echo -e "\n\nUNEXPECTED DIELECTRIC ASSIGNMENT.($dielec) "
          echo -e "SHOULD BE 0 = HOMO OR 1 = GAUSSIAN"
          echo -e "EXITING ... \n\n"
          exit 1
        fi
        ;;
    e)  delphi_exec=$OPTARG
        echo "DELPHI EXECUTABLE : $delphi_exec"
        if [ ! -e $delphi_exec ]
        then
            echo -e "DELPHI EXECUTABLE NOT FOUND: $delphi_exec\n\n"
            exit 1
        fi
        ;;
    x)  list1=$OPTARG;;
    y)  list2=$OPTARG;;
    s)  scale=$OPTARG;;
    h)  echo -e "$help\n\n"
        exit 1;;
	c)  salt=$OPTARG;;
    :)  echo -e "\n\n$help"
        exit 1;;
    \?) echo -e "\n\nINCORRECT ARGUMENT : -$OPTARG.\nTHE CORRECT WAY IS: \n$help"
        exit 1;;
    esac
done

if [ $# -eq 0 ]
then
 #        echo "can't run, it need parameter... "
	# echo "Usage: ./DelPhiForce.sh file1 file2 output_file "
	# echo "file1 and file2 are in pqr format. file1 is a reference molecule, file2 is the prob molecule"
    echo -e "\n\n$help"
    exit
fi

if [ -z $dielec ]
then
	echo -e "NO DIELECTRIC ASSIGNMENT METHOD WAS PROVIDED. WILL DEFAULT TO HOMOGENOUS"
	dielec=0
fi

if [ -z $salt ]
then
	echo -e "SALT CONCENTRATION VALUE WAS NOT SPECIFIED. WILL DEFAULT TO 0.15 M"
	salt=0.15
elif [ `echo $salt '<' 0 | bc -l` -eq 1 ]
then
	echo -e "BAD SALT CONCENTRATION VALUE. CANNOT BE NEGATIVE".
	echo -e "SALT CONCENTRATION WILL BE SET TO DEFAULT OF 0.15 M"
	scale=2.0
else
	echo -e "SALT CONCENTRATION SET TO $salt M"
fi

if [ -z $delphi_exec ]
then
	echo -e "PROVIDE THE PATH OF THE DELPHI EXECUTABLE. IT IS A REQUIRED ARGUMENT."
	echo "EXITING..."
	exit 1
fi

if [ -z $scale ]
then
	echo -e "SCALE IS SET TO DEFAULT OF 2.0"
	scale=2.0
elif [ `echo $scale '<' 0 | bc -l` -eq  1 ]
then
	echo -e "BAD SCALE VALUE. CANNOT BE ZERO OR NEGATIVE".
	echo -e "SCALE WILL BE SET TO DEFAULT OF 2.0"
	scale=2.0
else
	echo -e "SCALE SET TO $scale"
fi

pairwise=0
if [ ! -z $list2 ] && [ ! -z $list1 ]
then
	echo -e "PAIRWISE INTERACTIONS ARE TURNED ON"
	echo -e "EXPECTING SOURCE RESIDUES IN $list1"
	echo -e "EXPECTING PROBE RESIDUES IN $list2"
	pairwise=1

	if [ ! -e $list1 ] || [ ! -e $list2 ]
	then
		echo "SOURCE/PROBE RESIDUE LIST FILES NOT FOUND..."
		echo "EXITING..."
		exit 1
	fi
else
	echo "PAIRWISE INTERACTIONS ARE OFF"
fi

if [ -z $infile2 ] && [ $pairwise -eq 0 ]
then
	echo "PAIRWISE INTERACTIONS ARE OFF YET PROBE STRUCTURE IS NOT PROVIDED"
	echo -e "\t----> A PROBE STRUCTURE FILE IS NEEDED WHEN PAIRWOSE CALCULATIONS ARE NOT ON"
	echo -e "\t----> EXITING..."
	exit 1
elif [ ! -z $infile2 ] && [ $pairwise -eq 1 ]
then
	echo "WILL IGNORE THE PROBE STRUCTURE FILE : $infile2"
fi


#set working directory
wdir=`dirname $0`

#IF PAIRWISE MODE IS ON
if [ $pairwise -eq 1 ]
then
	#python3 ${wdir}/pairwise.py $infile1 $list1 $list2
	bash ${wdir}/pairwise.sh $infile1 $list1 $list2
	origStructFile=$infile1
	infile1="source_${origStructFile}"
	infile2="probe_${origStructFile}"

	if [ ! -e $infile1 ] || [ ! -e $infile2 ]
	then
		echo "PYTHON RUN PROBABALY FAILED. LOAD PYTHON v3 + FOR SUCCESFUL RUNS"
		echo "EXITING..."
		exit
	fi
fi

echo -en "DELPHIFORCE STARTED AT "
date

### test if the pdb has chain ID ###
chainid=$(awk -v num=0 '{if((substr($0,1,6)=="ATOM  " ||substr($0,1,6)=="HETATM") && substr($0,22,1)==" ") num++}END{print num}' $infile2)

if [ $chainid -gt 0 ]
then
	echo -e "\nThe chain ID of the probe molecule is missing. \nPlease add the chain ID for the probe molecule.\n\n"
	exit
fi

### 0. generate $3_param.txt
echo  "GENERATING DELPHI PARAMETER FILE."
echo -e "perfil=70.0\nscale=${scale}\nin(modpdb4,file="temp_${outfile}_complex",format=pqr)\nindi=2.0\nexdi=80.0\nprbrad=1.4\nsalt=${salt}\nbndcon=2\nmaxc=0.01\nlinit=800\nin(frc,file="temp_${outfile}_frc")\nout(frc,file="frc.out")\nsite(a,p,f)\nenergy(s,c)" > ${outfile}_param.txt

if [ $dielec -eq 1 ]
then
  echo -e "\n\nGAUSSIAN = 1\nSIGMA=0.93\nSRFCUT=20\n" >> ${outfile}_param.txt
fi

#echo -e "gsize=165\nscale=2.0\nacenter(0.0,0.0,0.0)\nin(modpdb4,file="temp_$3_complex",format=pqr)\nindi=2.0\nexdi=80.0\nprbrad=1.4\nsalt=0.00\nbndcon=2\nmaxc=0.0001\nlinit=800\nin(frc,file="temp_$3_frc")\nout(frc,file="frc.out")\nsite(a,p,f)\nenergy(s,c)" > $3_param.txt

### 1. Neutralize f2 -> temp_$3_f2
echo "NEUTRALIZING PROB MOLECULE"
awk '{if(substr($0,1,6)=="ATOM  " || substr($0,1,6)=="HETATM")printf("%s%8.4f%7.4f\n",substr($0,1,54),0,substr($0,63,69)); else print $0}' $infile2 > temp_${outfile}_f2



### 2. Generate complex containing f1 and Neutralized f2 (temp_$3_f2) -> temp_$3_complex
echo "GENERATING COMPLEX CONTAINING REFERENCE MOLECULE AND NEUTRALIZED PROB MOLECULE."
cat $infile1 temp_${outfile}_f2 > temp_${outfile}_complex



### 3. Generate input frc file temp_$3_frc
cp $infile2 temp_${outfile}_frc



### 4. Run DelPhi to get the output frc file $3
echo "RUNNING DELPHI:"
### Getting delphicpp location

# echo $wdir
# echo "${wdir}/delphicpp ${outfile}_param.txt > ${outfile}_delphi.log"
# ~/soft/delphicpp_v73 $3_param.txt > $3_delphi.log
# ${wdir}/delphicpp ${outfile}_param.txt > ${outfile}_delphi.log
echo "RUNNING : ${delphi_exec} ${outfile}_param.txt > ${outfile}_delphi.log"
${delphi_exec} ${outfile}_param.txt > ${outfile}_delphi.log
echo "DELPHI RUN FINISHED."



### 5. create the outputfile
echo "CREATING THE OUTPUT FILE."
awk 'BEGIN{printf("\n\n\n\n\n\n\n\n\n\n\n\n")} {if(substr($0,1,6)=="ATOM  "|| substr($0,1,6)=="HETATM") printf("%10.4f\n",substr($0,55,62))}' $infile2 > temp_${outfile}_q
paste frc.out temp_${outfile}_q |awk '{printf("%s%10.4f\n",substr($0,1,60),$NF)}' > frc2.out

length=$(wc -l frc2.out |awk '{print $1}')


awk -v l=$length -v fx=0 -v fy=0 -v fz=0 -v g=0 '{ if(NR>12 && NR < l ) {printf("%s%12.4f%10.4f%10.4f%10.4f%10.4f\n",substr($0,1,60),substr($0,61,10),substr($0,21,10)*substr($0,61,10),substr($0,31,10)*substr($0,61,10),substr($0,41,10)*substr($0,61,10),substr($0,51,10)*substr($0,61,10)); g=g+substr($0,21,10)*substr($0,61,10);fx=fx+substr($0,31,10)*substr($0,61,10);fy=fy+substr($0,41,10)*substr($0,61,10);fz=fz+substr($0,51,10)*substr($0,61,10)} else if(NR==12) print "ATOM DESCRIPTOR       GRID PT.    GRID FIELDS: (Ex, Ey, Ez)       CHARGE    ENERGY        FORCES:(Fx, Fy, Fz)"; else if(NR!=l) print $0 }END{printf("Total force: %15.4f%15.4f%15.4f\n",fx,fy,fz);printf("Binding energy:%15.4f\n",g)}' frc2.out > ${outfile}.atom



awk -v str="" -v str2="" -v l=$length -v q=0 -v g=0 -v fx=0 -v fy=0 -v fz=0 -v flag=0 -v flag2=0 'BEGIN{print "RESDUE ID      NET CHARGE         G        Fx        Fy        Fz"} {if(NR>12 && NR<=l) {flag=substr($0,9,12);str=substr($0,6,15);if(flag2!=flag && flag2!="0") {printf("%s%10.4f%10.4f%10.4f%10.4f%10.4f\n",str2,q,g,fx,fy,fz); q=0;g=0;fx=0;fy=0;fz=0};flag2=flag;str2=str;q=q+substr($0,61,12);g=g+substr($0,73,10);fx=fx+substr($0,83,10);fy=fy+substr($0,93,10);fz=fz+substr($0,103,10)} ; if (NR>=l){print $0} }' ${outfile}.atom > ${outfile}.residue


#awk -vstr="" -vstr2="" -vl=$length -vq=0 -vg=0 -vfx=0 -vfy=0 -vfz=0 -vflag=0 -vflag2=0 'BEGIN{print "RESDUE ID      NET CHARGE         G        Fx        Fy        Fz"} {if(NR>12 && NR<l) {flag=substr($0,9,12);str=substr($0,6,15);if(flag2!=flag && flag2!="0") {printf("%s%10.4f%10.4f%10.4f%10.4f%10.4f\n",str2,q,g,fx,fy,fz); q=0;g=0;fx=0;fy=0;fz=0};flag2=flag;str2=str;q=q+substr($0,61,12);g=g+substr($0,73,10);fx=fx+substr($0,83,10);fy=fy+substr($0,93,10);fz=fz+substr($0,103,10)} else if (NR>=l){print $0} }' $3.atom > $3.residue


############# generate forece file in tcl format #############
echo "GENERATE FORCE FILE IN TCL FORMAT."
#~/LinLi/soft/ll/mybash/center.sh $2|awk '{print "Prob_Center: ", $0}'>> $3.atom
awk -v sumx=0 -v sumy=0 -v sumz=0 -v num=0 '{if($1=="ATOM" || $1=="HETATM") {sumx=sumx+substr($0,31,8);sumy=sumy+substr($0,39,8);sumz=sumz+substr($0,47,8);num=num+1 } }END{print sumx/num,sumy/num,sumz/num}' $infile2 |awk '{print "Prob_Center: ", $0}'>> ${outfile}.atom

x1=$(grep "Center" ${outfile}.atom |awk '{print $2}')
y1=$(grep "Center" ${outfile}.atom |awk '{print $3}')
z1=$(grep "Center" ${outfile}.atom |awk '{print $4}')

fx=$(grep "Total" ${outfile}.atom |awk '{print $3}')
fy=$(grep "Total" ${outfile}.atom |awk '{print $4}')
fz=$(grep "Total" ${outfile}.atom |awk '{print $5}')


x2=$(echo "$x1 + $fx"|bc -l)
y2=$(echo "$y1 + $fy"|bc -l)
z2=$(echo "$z1 + $fz"|bc -l)

#echo "{ $x1 $y1 $z1 } {$fx $fy $fz } {$x2 $y2 $z2}" 
echo "vmd_draw_arrow top {$x1 $y1 $z1} {$x2 $y2 $z2} red 30.00" > ${outfile}.tcl 

### 6. clean temporary files

rm frc2.out temp_${outfile}_complex  temp_${outfile}_f2  temp_${outfile}_frc  temp_${outfile}_q 

### 7. generate force on each residue
echo "GENERATING TCL FILE FOR EACH RESIDUE."
#for pn in $(awk '{if(substr($0,7,4)+0 >0) print substr($0,5,6)}' $3.residue)
#do 
#  echo $pn > list_$pn
#  ./ForceGen.sh list_$pn $2 $3.residue $3_$pn
#  cat $3_$pn.tcl >> $3_residue.tcl

  #rm list_$pn $3_$pn.tcl
#done

awk '{if(substr($0,7,4)+0 >0) print substr($0,5,6)}' ${outfile}.residue > list_temp

dir2=`dirname $infile2`
echo "source ${wdir}/draw_arrow.tcl" > ${outfile}_seeAll.tcl

if [ $pairwise -eq 0 ]
then
    echo "mol load pdb $infile1" >> ${outfile}_seeAll.tcl
    echo "mol load pdb $infile2" >> ${outfile}_seeAll.tcl
elif [ $pairwise -eq 1 ]
then
	echo "mol load pdb $origStructFile" > ${outfile}_seeAll.tcl
fi
echo "vmd_draw_arrow top {$x1 $y1 $z1} {$x2 $y2 $z2} green 30.00" >> ${outfile}_seeAll.tcl 

while IFS= read -r line
do
  chain=$(echo "$line" | awk '{print substr($0,1,1)}' )
  res=$(echo "$line" | awk '{print substr($0,2,length($0))+0 }' )

  pn=${chain}_${res}
  echo $line > list_${pn}

  ${wdir}/ForceGen.sh list_${pn} $infile2 ${outfile}.residue ${outfile}_${pn}
  cat ${outfile}_${pn}.tcl >> ${outfile}_residue.tcl
  cat ${outfile}_${pn}.tcl >> ${outfile}_seeAll.tcl

  rm list_$pn ${outfile}_${pn}.tcl

done < list_temp

rm list_temp

### 8. resize the foreces 
echo "RESIZE THE FORCES..."
ftot=$(echo $fx $fy $fz |awk '{print ($1^2+$2^2+$3^2)^0.5}')

size=$(echo "$ftot"|awk '{print 18/$1}')

#echo "fx,fy,fz,ftot,size: " $fx $fy $fz $ftot $size

sed "s/red 30\.0/blue $size/g" ${outfile}.tcl > temp_${outfile}.tcl
sed "s/green 30\.0/blue $size/g; s/red 30\.0/red $size/g" ${outfile}_seeAll.tcl > temp_${outfile}_seeAll.tcl
sed "s/red 30\.0/red $size/g" ${outfile}_residue.tcl > temp_${outfile}_residue.tcl

cp temp_${outfile}.tcl ${outfile}.tcl
cp temp_${outfile}_seeAll.tcl ${outfile}_seeAll.tcl
cp temp_${outfile}_residue.tcl ${outfile}_residue.tcl

rm temp_${outfile}.tcl temp_${outfile}_residue.tcl temp_${outfile}_seeAll.tcl



############## ARGO: ZHE REMOVE THIS FOLLOWING rm STATEMENT ###############
# rm ${outfile}.atom ${outfile}_delphi.log ${outfile}_param.txt ${outfile}*.tcl
########################################################################


if [ $pairwise -eq 1 ]
then
	rm source_${origStructFile} probe_${origStructFile}
fi

echo -e "CALCULATION FINISHED."
echo -en "DELPHIFORCE EXITS AT "
date

echo -e "\nTHE FOLLOWING FILES WERE CREATED:"
ls -1 ${outfile}* | head -7
echo -e "\n----------------------------------------------------------------\n"
