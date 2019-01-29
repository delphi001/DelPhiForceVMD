####### May 10 #####
infile=$1
list1=$2
list2=$3


cp $infile source.rm_residue
while IFS= read -r line
do

  num=$(echo $line|awk '{if(substr($0,1,1)!="!") print $1}')
  chain=$(echo $line|awk '{if(substr($0,1,1)!="!") print $2}')

  awk -vnum=$num -vchain=$chain '{if(substr($0,23,4)+0 == num+0 && substr($0,22,1) == chain)print $0}' $infile

  awk -vnum=$num -vchain=$chain '{if(substr($0,23,4)+0 != num+0 || substr($0,22,1) != chain)print $0}' source.rm_residue > source.rm_residue2
  mv source.rm_residue2 source.rm_residue


  #echo $num $chain
done < $list2 > probe_${infile}

mv source.rm_residue source.charge
while IFS= read -r line
do

  num=$(echo $line|awk '{if(substr($0,1,1)!="!") print $1}')
  chain=$(echo $line|awk '{if(substr($0,1,1)!="!") print $2}')

  awk -vnum=$num -vchain=$chain '{if(substr($0,23,4)+0 == num+0 && substr($0,22,1) == chain)print $0,"charge"; else print $0}' source.charge > source.charge2
  mv source.charge2 source.charge

  #echo $num $chain
done < $list1 

awk '{if($(NF)== "charge") print substr($0,1,69);else  printf("%s  0.0000%7.4f\n",substr($0,1,54),$(NF))}' source.charge > source_${infile}

rm source.charge



