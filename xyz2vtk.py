#!/usr/bin/env python2.7

"""
Written by Nicolas Celli 2019. It reads in
parameters from a CSV file beginning with xyz and with
a header defining the variable names.

"""

import os
import sys
import string
from sys import argv
import numpy as np


#====================================================
#- define input parser
#====================================================
def get_options():
  from optparse import OptionParser
  parser = OptionParser(usage="Usage: %prog [options] <input file>",description="""Converts any number of parameters on a regular xyz grid in either CSV or XYZ format into vtk format for rendering. Input has to be with a header indicating all fields. For example:                
dim1,dim2,dim3,par1name,par2name,par3name,...,parNname                                    
x,y,z,par1,par2,par3,...,parN                          
x,y,z,par1,par2,par3,...,parN                          
x,y,z,par1,par2,par3,...,parN                                                                   
...                                                                                               
                                                                                                      
with:                                                                                       
        dim1-3 and x,y,z being the coordinates                                                     
        par1-N being the values for each point                                                      
""")

  parser.add_option("--output",action="store",type="string",dest="output",default="mod.vtk",help="Specify the output filename for the vtk file")
  parser.add_option("--csv",action="store_true",dest="iscsv",default=False,help="Option to input CSV formatted files")
  parser.add_option("--type",action="store",type="string",dest="dtype",default="volume",help='Option to choose data type: "points" or "volume" ')
  (opts, args) = parser.parse_args()

  #-- check number of inputs
  if len(args)<1: parser.error("Specify at least one input file.")
  return (opts,args)


#====================================================
#- Run MAIN
#====================================================

(opts,args)=get_options()

filename = args[0]
print "output to:", opts.output
        

#====================================================
#- read in information
#====================================================

#- re-order input files wit x, then y and then z changing the fastest, using bash
print "sorting and removing duplicates"
filename_sorted='.'+filename+'.tmpxyz2vtk'

if opts.iscsv:
        bFS='-t,'
        FS=','
else:
        bFS=''
        FS=' '

shcmd='(head -n 1 '+filename+' && tail -n +2 '+filename+' | sort '+bFS+' -uk1,3 | sort '+bFS+' -nk3,3 -nk2,2 -nk1,1) > '+filename_sorted
os.system(shcmd)

#- read in arrays from file
with open(filename_sorted,'r') as f:


        #- initialise coordinate variables
        x=[]
        y=[]
        z=[]

        #- read header and define number of parameters
        header = f.readline()
        npar = len(header.replace("\n","").split(FS))

        #- read parameter names
        parnames = header.replace("\n","").split(FS)
        pars=[]

        #- initialise the parameter arrays
        for jj in range(npar):
                pars.append([])

        #- start reading the file. it assumes 3 coordinates followed by a number of parameters
        ii=0
        for line in f.readlines():
                words = line.split(FS)
                ii=ii+1
                if ii>0:
                    if len(words)> 0:
                            x.append(words[0])
                            y.append(words[1])
                            z.append(words[2])
                            for jj in range(npar):
                                pars[jj].append(words[jj])


#- define file dimensions
n=len(x)
xdim=len(np.unique(x))#+1     #- Not sure why is that NC 2019. Is required in some model...
ydim=len(np.unique(y))
zdim=len(np.unique(z))


#- print to screen useful information
print "n:",n
print "x size:",xdim
print "y size:",ydim
print "z size:",zdim
print "n of parameters:",npar
for parname in parnames:
        print " parameter name:",parname


#====================================================
#- write data to vtk polydata file
#====================================================

#- define header information
out = open(opts.output, 'w')
dims = str(xdim)+" "+str(ydim)+" "+str(zdim)

if opts.dtype == 'points':
        h1 = """# vtk DataFile Version 2.0
loop
ASCII
DATASET UNSTRUCTURED_GRID
POINTS """ + str(n) + """ double
"""

elif opts.dtype == 'volume':
        h1 = """# vtk DataFile Version 2.0
loop
ASCII
DATASET STRUCTURED_GRID
DIMENSIONS """ + dims + """
POINTS """ + str(n) + """ double
"""

h2 = '\n' + """POINT_DATA """ + str(n) + """
FIELD FieldData """ +str(npar)+"""
"""

#- write first header
out.write(h1)

#- write coordinates
for i in range(n):
        out.write(str(x[i])+" "+str(y[i])+" "+str(z[i])+'\n')
        
#- for unstructured grds, write cell information
if opts.dtype == 'points':
        #- cells
        out.write("CELLS "+ str(n)+ " "+ str(2*n)+'\n')
        for i in range(n):
                out.write("1 "+str(i)+"\n")

        # cell types
        out.write("CELL_TYPES " + str(n)+'\n')
        for i in range(n): out.write("1 \n")


#-write data header
out.write(h2)

#- write data fields
for jj in range(npar):
        print "writing data field",str(jj),str(parnames[jj])

        #- write data field header
        hj = str(parnames[jj])+" 1 "+str(n)+"  double"
        out.write(hj+'\n')

        #- write data
        for ii in range(n):
                sc=(pars[jj][ii])
                out.write(str(sc)+ "\n")
        out.write('\n')

#- finish
out.close()
os.remove(filename_sorted)
