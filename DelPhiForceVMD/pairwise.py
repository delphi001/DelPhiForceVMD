import sys
# coding: utf-8

# In[50]:

source_resid = []
probe_resid = []

structFile = sys.argv[1]
listFile1 = sys.argv[2]
listFile2 = sys.argv[3]

# print("{} , {}, {} \n".format(structFile, listFile1, listFile2))

with open(listFile1,'r') as list1:
    for line in list1:
        if not line.startswith("!"):
            source_resid.append(line.split()[0])
            source_resid.append(line.split()[1])

with open(listFile2,'r') as list2:
    for line in list2:
        if not line.startswith("!"):
            probe_resid.append(line.split()[0])
            probe_resid.append(line.split()[1])
        
# print(source_resid,probe_resid)

probe_pdb = open("probe_"+structFile,'w')
source_pdb = open("source_"+structFile,'w')

with open(structFile,'r') as inPDB:
    for line in inPDB:
        if line[0:6] == "ATOM  " or "HETATM":
            if line[21:22] in probe_resid and line[22:26].strip() in probe_resid:
                probe_pdb.write(line)
            elif line[21:22] in source_resid and line[22:26].strip() in source_resid:
                source_pdb.write(line)
            else:
                #zero out the charges
                source_pdb.write("{}{:8.4f}{}\n".format(line[0:54], 0.0, line[62:69]))
            
probe_pdb.close()   
source_pdb.close()
