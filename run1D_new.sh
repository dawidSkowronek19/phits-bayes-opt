#!/bin/bash

first_target='W'
target_center=17.55

first_target_thickness=$1  #U-238 
fidelity=$2

if [ "$fidelity" == "low" ]; then
        maxcas=20000
        maxbch=2
elif [ "$fidelity" == "high" ]; then
        maxcas=25000
        maxbch=10
fi
        

#file section
workdir="./results/${first_target}_${first_target_thickness}"
#if [ -d $workdir ]; then
#  rm -rf "nazwa_katalogu"
#  echo "Katalog został usunięty."
#fi
mkdir -p $workdir
mkdir -p $workdir/dchain
#targets boundary positions
first_target_end=$(echo "$target_center + $first_target_thickness/2.0" | bc -l)
first_target_start=$(echo "$target_center - $first_target_thickness/2.0" | bc -l)


cat > $workdir/run.inp << EOF

\$OMP 12
 [ T i t l e ]
input file for Solaris Linac simulations
RURA O ŚREDNICY 4 cm, źródło: gauss o szerokości 2 cm
[ P a r a m e t e r s ]
 icntl    =          0    # (D=0) 3:ECH 5:NOR 6:SRC 7,8:Check geometry 11:DSH 12:DUMP, 8=geometry check
 maxcas   =        $maxcas    # (D=10) number of particles per one batch
 maxbch   =        $maxbch   # (D=10) number of batches
 emin(2)  = 1.000000000E-10 # (D=1.0) cut-off energy of neutron (MeV)
 dmax(2)  =  20.0000000     # (D=emin(2)) data max. energy of neutron (MeV)
 emin(12) = 1.000000000E-01 # (D=1.d9) cut-off energy of electron (MeV)
 emin(13) = 1.000000000E-01 # (D=1.d9) cut-off energy of positron (MeV)
 emin(14) = 1.000000000E-03 # (D=1.d9) cut-off energy of photon (MeV)
 dmax(12) =  1000.00000     # (D=emin(12)) data max. energy of electron (MeV)
 dmax(13) =  1000.00000     # (D=emin(13)) data max. energy of positron (MeV)
 dmax(14) =  1000.00000     # (D=emin(14)) data max. energy of photon (MeV)
 igamma   =           2     # (D=0) 0:No, 1:Old, 2:EBITEM, 3:EBITEM+Isomer
 ipnint   =           1     # (D=0) 0: no, 1: consider photo-nuclear reaction
 negs     =           1     # (D=0) =1 EGS photon and electron
 mdbatima = 800
#  must option for DCHAIN 
 jmout    =           1     # (D=0) Density echo, 0:input, 1:number density
 e-mode   =           0     # (D=0) Event generator mode is not recommended for DCHAIN calculation
 istdev=-1 #execute PHITS in restart calculation mode
 kmout=1   #the values of dmax for each nucleus in the materials are shown in the output file, file(6) (D=phits.out)
 #
 set: c1[-5.]
 set: c2[5]
 set: c3[-342.]
 set: c4[-341.]
 set: c5[22.46]
 set: c6[32.46]
 set: c7[10]
 set: c8[10]
 set: c9[1]
 set: c10[1000.] #emaxn
 set: c11[500.]  #emaxe
 set: c12[1.E-07]    #emingh
 set: c13[500.]    #emaxgh
 set: c14[1000]   #nbin
 set: c15[$first_target_start]   #pos. of beginning of the 1st target
 set: c16[$first_target_end]   #pos. of end of the 1st target
 set: c19[$(echo "$first_target_end + 1.0" | bc -l)]
set: c20[$(echo "$first_target_end + 1.1" | bc -l)]

EOF

cat >> $workdir/run.inp << 'EOF'
[ S o u r c e ]
  totfact = 1.0             # You have to input your AmBe source intensity (neutron/s) here
   s-type =  11             # ellipsoid source
     proj =  electron       # kind of incident particle         
       e0 =  c11       # energy of beam [MeV/n]
       x0 =   0.0000        # (D=0.0) center of x-axis [cm]
       y0 =   0.0000        # (D=0.0) center of y-axis [cm]
       z0 =   0.0000        # minimum position of z-axis [cm]
       z1 =   0.0000        # maximum position of z-axis [cm]
       rx =   0.0000 # -0.50000        # phase space angle of x-axis [rad]
       ry =   0.0000 # 0.50000        # phase space angle of y-axis [rad]
       x1 =   0.40000        # Mean value of x-corrdinate Gaussian [cm]
       x2 =   0.0000        # Sigma of x-corrdinate Gaussian [cm]
   xmrad1 =   0.0000       # 1.0000        # Mean value of x-angle Gaussian [mrad]
   xmrad2 =   0.0000       #5.0000        # Sigma of x-angle Gaussian [mrad]
       y1 =   0.40000        # Mean value of y-corrdinate Gaussian [cm]
       y2 =   0.0000        # Sigma of y-corrdinate Gaussian [cm]
   ymrad1 =   0.0000       #2.00000        # Mean value of y-angle Gaussian [mrad]
   ymrad2 =   0.0000       #10.00000        # Sigma of y-angle Gaussian [mrad]
      dir =   1.0000        # z-direction of beam [cosine]

[ M a t e r i a l ]
$ Steel, rho=7.8 g/cm3
mat[1]    24000 -0.190 $ Cr 
          25055 -0.020 $ Mn 
          26000 -0.695 $ Fe 
          28000 -0.095 $ Ni
mat[2]    H 2 O 1  
mat[3]   6000 -0.000124 $ C 
         7014 -0.755268 $ N 
         8016 -0.231781 $ O 
         18000 -0.012827 $ Ar

mat[4]   1001 -0.148605 $paraffin
         6012 -0.851395

mat[5]   1001 -0.022100 $concrete
         6012 -0.002484 
         8016 -0.574930 
         11023 -0.015208 
         12000 -0.001266 
         13027 -0.019953 
         14000 -0.304627 
         19000 -0.010045 
         20000 -0.042951 
         26000 -0.006435
mat[6]   1002  2.        $Heavy Water
         8016  1.
mat[7]   74000 -1.000000 $ Tungsten density=19.3
mat[8]   42000 -1.000000 $ Mo density=10.2
mat[9]   13027 -1.000000 $ Al desity=2.6989
mat[10]  3000 -0.267585  $LiF density=2.635
         9000 -0.732415
mat[11]  1001 -0.143716     $ poliethylene, density 9.3
         6000 -0.856284		
$ Lead rho = 11.35 g/cm3 
$mat[12]  82000 -1.000000
$
$ Berylium rho = 1.848000 g/cm3 
$mat[12]  4009 -1.000000
$ W
mat[13]   74000 -1.000000
$
$ Cu, d=8.96
mat[15]	    29000 -1.000000
$ Stop aluminium 6061-O, 2.7 g/cm3
mat[16]	 12000 -0.010000 
		 13027 -0.972000
		 14000 -0.006000
		 22000 -0.000880
		 24000 -0.001950
		 25055 -0.000880
		 26000 -0.004090
		 29000 -0.002750
		 30000 -0.001460
$ LaBr3 d= 5.08 g/cm3
mat[17]    57138      0.25  
		   35079      0.75
$ Plate glass d=2.4
mat[18] 
		8000 -0.459800
		11000 -0.096441
		14000 -0.336553
		20000 -0.107205		   
[ Mat Name Color ]
$    mat   name      color
1 steel red
2 water blue
3 air  cyan 
4 paraffin yellow
5 concrete green
6 deuter black

[ S u r f a c e ]
$Swiat
  10  rpp   -150. 250. -200. 200. -200. 300.
$ Podloga 
  11  rpp   -150. 250. -200. -130. -200. 300.
$ Sufit
  12  rpp   -150. 250. 170. 200. -200. 300.
$ Sciana tylna
  13  rpp   -150. 250. -130. 170. 270. 300.
$ Sciana przednia
  14  rpp   -150. 250. -130. 170. -200. -170.
$ Sciana prawa
  15  rpp   220. 250 -130. 170. -170. 270 
$ Sciana lewa
  16  rpp -150. -120. -130. 170. -170. 270  
$ Jonowod + zakonczenie
  17 c/z   0. 0. 1.9	
  18 c/z   0. 0. 1.7
  19 c/z   0. 0. 3.64
  20 pz    -30.
  21 pz    -30.03
  22 pz    0.0
  23 pz    1.5
  24 pz    1.48  
  25 rpp    -7. 7. -7. 7. c15 c16
$  27 TRC 0. 0. 11.5 0. 0. 4.9 0.45 0.1
  27 KZ 16.4 0.0061611 -1.
  28 rpp -5.5 5.5 2.25 4.25 11. 11.49
  30 rpp -5.5 5.5 -4.25 -2.25 11. 11.49
  29 PZ 11.4
  31 rpp -19.5 19.5 -16. -12. 11.5 66.5
  32 rpp -10.5 10.5 -12. -7. 11.5 66.5
  33 rpp -10.5 -7.5 -7. -1. 11.5 66.5
  34 rpp 7.5 10.5 -7. -1. 11.5 66.5
  35 rpp -10.5 -7.5 -7. -1. 27.5 50.5
  36 rpp 7.5 10.5 -7. -1. 27.5 50.5
  37 rpp -11. 11. -24. -16. 11.5 19.5
  38 rpp -11. 11. -23.5 -16.5 12. 19.
  39 rpp -11. 11. -24 -16. 58.5 66.5
  40 rpp -11. 11. -23.5 -16.5 59. 66.
  41 rpp -19. -11. -24. -16. 11.5 66.5
  42 rpp -18.5 -11.5 -23.5 -16.5 11.5 66.5
  43 rpp 11. 19. -24. -16. 11.5 66.5
  44 rpp 11.5 18.5 -23.5 -16.5 11.5 66.5
  45 rpp -19. -11. -130 -24. 11.5 19.5
  46 rpp -18.5 -11.5 -130 -24. 12. 19.
  47 rpp 11. 19. -130 -24. 11.5 19.5
  48 rpp 11.5 18.5 -130 -24. 12. 19.  
  49 rpp -19. -11. -130. -24. 58.5 66.5
  50 rpp -18.5 -11.5 -130. -24. 59. 66.
  51 rpp 11. 19. -130. -24. 58.5 66.5
  52 rpp 11.5 18.5 -130. -24. 59. 66.
  53 rpp -11. 11. -24. -16. 35. 43.
  54 rpp -11. 11. -23.5 -16.5 35.5 42.5
  55 rpp -11. 11. -124. -116. 11.5 19.5
  56 rpp -11. 11. -123.5 -116.5 12. 19.
  57 rpp -11. 11. -124. -116. 58.5 66.5	
  58 rpp -11. 11. -123.5 -116.5 59. 66.
  59 rpp -19. -11. -124. -116. 19.5 58.5
  60 rpp -18.5 -11.5 -123.5 -116.5 19.5 58.5
  61 rpp 11. 19. -124. -116. 19.5 58.5
  62 rpp 11.5 18.5 -123.5 -116.5 19.5 58.5

$ 
  96 rpp -8. 8. -7. 8. c16+1. c16+1.1  $ Detektor 1
  97 rpp -8.1 -8. -7. 8. c15-1. c16+1.1 
  $$11.5 21.5 $ Detektor 2	
  98 rpp 8. 8.1 -7. 8. c15-1. c16+1.1 
  $$ 11.5 21.5 $ Detektor 3
  99 rpp -8.1 8.1 8. 8.1 c15-1. c16+1.1 
  $$ 11.5 21.5 $ Detektor 4
  95 rpp -5. 5. -36.1 -36. 11.5 21.5 $ Detektor 5
  94 rpp -2.5 2.5 4. 9. 1.5 1.6 $ Detektor 6
$$  93 RCC 27. 0. 14.04 5.08 0. 0. 2.54
$$  92 RCC 26.8 0. 14.04 6.0 0. 0. 2.79
$$  91 RCC 32.08 0. 14.04 0.5 0. 0. 2.54
$ 


$ detector box




[ C e l l ]
 100   -1         10 
 101    3   -0.001205 -10 #302 #116 #117 #118 #119 #124 #125 $$#126 #127 #128 #129
        #130 #131 #132 #133 #134 #135
        #136 #137 #138 #139 #140 #141 #142 #143 #144 #145 #146 #147 #148 #149 #150 #151 #152 #153 #154 #155 #111 #112 #113 #114 #115 #156
        #303 #304 #305 #306 #307
		$ #121 #122 #123 #308 #309 #310
$Podloga
 111    5   -2.3      -11 
$Sufit
 112    5   -2.3      -12
$Tylna sciana
 113    5   -2.3      -13
$ Sciana przednia
 114    5   -2.3      -14 
$ Sciana przednia
 115    5   -2.3      -15 
$ Sciana przednia
 156    5   -2.3      -16
$ Beam pipe
 116  1 -7.8 -17 21 -24 #117
$ Inside the beam pipe 
 117  3 -0.0000001205 -18 20 -23
$ Beam pipe ending
 118 1 -7.8 -19 22 -23 # 116 #117 
$ First W Target
 119 13 -19.3 -25 $ #121

$ Air cone in the copper
$$ 121 3 -0.001205 -27 29
$ Aluminiowe klamry
$$ 122 16 -2.7 -28
$ Aluminiowe klamry
$$ 123 16 -2.7 -30
$ 1 Czesc podstawki
 124 1 -7.8 -31
$ 2 Czesc podstawki
 125 11 -9.3 -32
$ 3 Czesc podstawki
$$ 126 11 -9.3 -33 #128
$ 4 Czesc podstawki
$$ 127 11 -9.3 -34 #129
$ powietrze w podstawce 1
$$ 128 3   -0.001205 -35
$ powietrze w podstawce 1
$$ 129 3   -0.001205 -36 
$ belka aluminiowa poprzeczna 1
 130 16 -2.7 -37 #131
 $ powietrze w belce aluminiowej poprzecznej 1
 131 3 -0.001205 -38
$ belka aluminiowa poprzeczna 2
 132 16 -2.7 -39 #133
$ powietrze w belce aluminiowej poprzecznej 2
 133 3 -0.001205 -40
$ belka aluminiowa podluzna 1
 134 16 -2.7 -41 #135
$ powietrze w belce aluminiowej podluzniej 1
 135 3 -0.001205 -42
$ belka aluminiowa podluzna 2
 136 16 -2.7 -43 #137
 $ powietrze w belce aluminiowej podluzniej 2
 137 3 -0.001205 -44
$ Noga 1
138 16 -2.7 -45 #139
$ powietrze w nodze 1
139 3 -0.001205 -46
$ Noga 2
140 16 -2.7 -47 #141
$ powietrze w nodze 2
141 3 -0.001205 -48
$ Noga 3
142 16 -2.7 -49 #143
$ powietrze w nodze 3
143 3 -0.001205 -50
$ Noga 4
144 16 -2.7 -51 #145
$ powietrze w nodze 4
145 3 -0.001205 -52
$ belka aluminiowa poprzeczna 3
 146 16 -2.7 -53 #147
$ powietrze w belce aluminiowej poprzecznej 1
 147 3 -0.001205 -54
$ belka aluminiowa dolna 1
 148 16 -2.7 -55 #149
$ powietrze w belce aluminiowej poprzecznej 1
 149 3 -0.001205 -56
$ belka aluminiowa dolna 2
 150 16 -2.7 -57 #151
$ powietrze w belce aluminiowej dolnej 2
 151 3 -0.001205 -58
$ belka aluminiowa dolna 3
 152 16 -2.7 -59 #153
$ powietrze w belce aluminiowej dolnej 3
 153 3 -0.001205 -60
$ belka aluminiowa dolna 4
 154 16 -2.7 -61 #155
$ powietrze w belce aluminiowej dolnej 4
 155 3 -0.001205 -62 
$Detector 1
 302    3   -0.001205 -96                        
$Detector 2
 303    3   -0.001205 -97
$Detector 3
 304    3   -0.001205 -98
$Detector 4
 305    3   -0.001205 -99
$Detector 5
 306   3   -0.001205 -95
$Detector 6
 307   3   -0.001205 -94 
$ Detektor LaBr3
$$ 308 17 -5.08 -93
$ Oslona aluminiowa LaBr3
$$ 309 16 -2.7 -92 #308 #310
$ szklo w LaBr3
$$ 310 18 -2.4 -91

 [volume]
 reg vol
 302 16.*15.*0.1
 303 0.1*15.*(c16-c15+2.1)
 304 0.1*15.*(c16-c15+2.1)
 305 16.2*0.1*(c16-c15+2.1)
 306 10.*10.*0.1
 307 14.*14.*0.1
 119 196.*c16 - 196.*c15


EOF



cat >> $workdir/run.inp << EOF
[ T - T r a c k ]
	title = For Diagnosis: electron current throug the surface perpendicular to the z axis just after the source 
     mesh =  xyz            # mesh type is xyz scoring mesh
   x-type =    2            # y-mesh is linear given by ymin, ymax and ny
     xmin =  -2.            # minimum value of y-mesh points
     xmax =   2.            # maximum value of y-mesh points
       nx =   100            # number of y-mesh points
   y-type =    2            # x-mesh is linear given by xmin, xmax and nx
     ymin =  -2.            # minimum value of x-mesh points
     ymax =   2.            # maximum value of x-mesh points
       ny =   100            # number of x-mesh points
   z-type =    2            # z-mesh is linear given by zmin, zmax and nz
     zmin =   0.10           # minimum value of z-mesh points
     zmax =   1.0          # maximum value of z-mesh points
       nz =    1            # number of z-mesh points
   e-type =    1            # e-mesh is given by the below data
       ne =    1            # number of e-mesh points
             0.01  c11
     unit =    1            # unit is [1/cm^2/source]
  2D-type =    3            # 1:Cont, 2:Clust, 3:Color, 4:xyz, 5:mat, 6:Clust+Cont, 7:Col+Cont
     axis =   xy            # axis of output
     file = track_xy.out    # file name of output for the above axis
     part =  electron
    gshow =    3            # 0: no 1:bnd, 2:bnd+mat, 3:bnd+reg 4:bnd+lat
   epsout =    1            # (D=0) generate eps file by ANGEL   
#
EOF

cat >> $workdir/run.inp << EOF
[ T - T r a c k ]
	title = For Diagnosis: electron current through the surface perpendicular to the z axis just after the source 
     mesh =  xyz            # mesh type is xyz scoring mesh
   x-type =    2            # y-mesh is linear given by ymin, ymax and ny
     xmin =  -2.            # minimum value of y-mesh points
     xmax =   2.            # maximum value of y-mesh points
       nx =   100            # number of y-mesh points
   y-type =    2            # x-mesh is linear given by xmin, xmax and nx
     ymin =  -2.            # minimum value of x-mesh points
     ymax =   2.            # maximum value of x-mesh points
       ny =   1           # number of x-mesh points
   z-type =    2            # z-mesh is linear given by zmin, zmax and nz
     zmin =   0.0           # minimum value of z-mesh points
     zmax =   0.10          # maximum value of z-mesh points
       nz =    1            # number of z-mesh points
   e-type =    1            # e-mesh is given by the below data
       ne =    1            # number of e-mesh points
             0.01  c11
     unit =    1            # unit is [1/cm^2/source]
     axis =   x            # axis of output
     file = track_x.out    # file name of output for the above axis
     part =  electron
    gshow =    3            # 0: no 1:bnd, 2:bnd+mat, 3:bnd+reg 4:bnd+lat
   epsout =    1            # (D=0) generate eps file by ANGEL 
#
EOF

cat >> $workdir/run.inp << EOF
[ T - Deposit ]
    title = Heat deposition in the beam dump
     mesh = xyz            # mesh type is region-wise
   x-type =  2           # y-mesh is linear given by ymin, ymax and ny
     xmin =  -7.            # minimum value of y-mesh points
     xmax =   7.            # maximum value of y-mesh points
       nx =   100            # number of y-mesh points
   y-type =   2            # x-mesh is linear given by xmin, xmax and nx
     ymin =  -7.            # minimum value of x-mesh points
     ymax =   7.            # maximum value of x-mesh points
       ny =   100           # number of x-mesh points
   z-type =    2            # z-mesh is linear given by zmin, zmax and nz
     zmin =   c15           # minimum value of z-mesh points
     zmax =   c16          # maximum value of z-mesh points
       nz =    4            # number of z-mesh points
     unit =    0            # unit is [Gy/source]
 material =  all            # (D=all) number of specific material
   output =  dose           # total deposit energy
     axis =   xy           # axis of output
     file = deposit_beam_dmp.out     # file name of output for the above axis
     part =  all      
\$	 multiplier = all \$ The following is subsection of multiplier.
\$	 mat        mset1
\$      all (0.624151e16)          \$ Fux per 1mA	 
    gshow =    1            # 0: no 1:bnd, 2:bnd+mat, 3:bnd+reg 4:bnd+lat
   epsout =    1            # (D=0) generate eps file by ANGEL
   y-txt = Energy Deposit [J/(kg mA)]
# 
EOF
cat >> $workdir/run.inp << EOF
[ T - T r a c k ]
    title = Energies of gammas induced in BD
     mesh = xyz            # mesh type is region-wise
   x-type =  2           # y-mesh is linear given by ymin, ymax and ny
     xmin =  -7.            # minimum value of y-mesh points
     xmax =   7.            # maximum value of y-mesh points
       nx =   1            # number of y-mesh points
   y-type =   2            # x-mesh is linear given by xmin, xmax and nx
     ymin =  -7.            # minimum value of x-mesh points
     ymax =   7.            # maximum value of x-mesh points
       ny =   1           # number of x-mesh points
   z-type =    2            # z-mesh is linear given by zmin, zmax and nz
     zmin =   c15           # minimum value of z-mesh points
     zmax =   c16          # maximum value of z-mesh points
       nz =    4            # number of z-mesh points
    e-type =   3            # e-mesh is log given by emin, emax and ne
     emin =   0.0009      # minimum value of e-mesh points
     emax =   c11      # maximum value of e-mesh points
       ne =   1000            # number of e-mesh points
     unit =    1            # unit is [1/cm^2/source]
     axis =   eng            # axis of output
     file = gammas_beam_dump.out  # file name of output for the above axis
     part = photon
	 multiplier = all \$ The following is subsection of multiplier.
     part  = photon
     emax  = c11
      mat        mset1
      all (0.624151e16)          \$ Fux per 1mA	 
    gshow =    1            # 0: no 1:bnd, 2:bnd+mat, 3:bnd+reg 4:bnd+lat
   epsout =    1            # (D=0) generate eps file by ANGEL   
	y-txt = Flux [1/(cm^2 mA)]
#

EOF
cat >> $workdir/run.inp << EOF
[ T - T r a c k ] 
title = All particles flux for 1mA in W target
mesh = reg
reg = 119
  e-type = 2
  ne = 1
    emin =   0.     # minimum value of e-mesh points
    emax =   c10      # maximum value of e-mesh points
	unit = 1
	file = particles_flux_in_Pb.out
	axis = reg
	part = photon neutron
	multiplier = all
    mat mset1
all (0.624151e16)          \$ Fux per 1mA	 	
	
EOF

cat >> $workdir/run.inp << EOF
[ T - T r a c k ]
    title = Energies of neutrons induced in BD
     mesh = xyz            # mesh type is region-wise
   x-type =  2           # y-mesh is linear given by ymin, ymax and ny
     xmin =  -7.            # minimum value of y-mesh points
     xmax =   7.            # maximum value of y-mesh points
       nx =   1            # number of y-mesh points
   y-type =   2            # x-mesh is linear given by xmin, xmax and nx
     ymin =  -7.            # minimum value of x-mesh points
     ymax =   7.            # maximum value of x-mesh points
       ny =   1           # number of x-mesh points
   z-type =    2            # z-mesh is linear given by zmin, zmax and nz
     zmin =   c15           # minimum value of z-mesh points
     zmax =   c16          # maximum value of z-mesh points
       nz =    4            # number of z-mesh points
    e-type =   3            # e-mesh is log given by emin, emax and ne
     emin =   0.0000001      # minimum value of e-mesh points
     emax =   c11           # maximum value of e-mesh points
       ne =   500            # number of e-mesh points
     unit =    1            # unit is [1/cm^2/source]
     axis =   eng            # axis of output
     file = neutrons_beam_dump.out  # file name of output for the above axis
     part = neutron
	 multiplier = all \$ The following is subsection of multiplier.
     part  = neutron
     emax  = c11
      mat        mset1
      all (0.624151e16)          \$ Fux per 1mA	 
    gshow =    1            # 0: no 1:bnd, 2:bnd+mat, 3:bnd+reg 4:bnd+lat
   epsout =    1            # (D=0) generate eps file by ANGEL   
	y-txt = Flux [1/(cm^2 mA)]	
#
EOF


cat >> $workdir/run.inp << EOF
[ T - C r o s s ]
    title = angle distribution of neutrons induced in BD
     mesh =  xyz            # mesh type is xyz scoring mesh
   x-type =    2            # x-mesh is linear given by xmin, xmax and nx
     xmin =  -7.0000      # minimum value of x-mesh points
     xmax =   7.0000      # maximum value of x-mesh points
       nx =   1            # number of x-mesh points
   y-type =    2            # y-mesh is linear given by ymin, ymax and ny
     ymin =  -7.00000      # minimum value of y-mesh points
     ymax =   7.00000      # maximum value of y-mesh points
       ny =    1            # number of y-mesh points
   z-type =    2            # z-mesh is linear given by zmin, zmax and nz
     zmin =  c15         # minimum value of z-mesh points
     zmax =  c16      # maximum value of z-mesh points
       nz =   4            # number of z-mesh points
   e-type =   2            # e-mesh is log given by emin, emax and ne
     emin =   0.0      # minimum value of e-mesh points
     emax =   c10      # maximum value of e-mesh points
	 ne =   1            # number of e-mesh points
   a-type = -2
     amin = 0.
     amax = 180.
     na = 200
     iangform = 3           #The angle between the z dir and the directon of the particle trajectory
     unit =    1            # unit is [1/cm^2/source]
     axis = the            # axis of output
     file = theta_neutrons_BD.out   # file name of output for the above axis
   output = a-flux            # surface crossing flux
	y-txt = Flux [1/(cm^2 mA)]
     part = neutron
   epsout =    1            # (D=0) generate eps file by ANGEL	
#
EOF
detector_id=(302 303 304 305 306 307)
for (( i=1; i<=6; i++ ))
do
	if (( i < 3 )); then
		emin_val='c12'
		emax_val='c13'
	elif (( i > 2 )); then
		emin_val=0
		emax_val='c10'
	fi
cat >> $workdir/run.inp << EOF
	[ T - T r a c k ] 
	title = All particles dose for 1mA in Sv/s in det $i
	mesh = reg
	reg = ${detector_id[$i-1]}
  	e-type = 2
  	ne = 1
    	emin =   $emin_val      # minimum value of e-mesh points
    	emax =   $emax_val     # maximum value of e-mesh points
	unit = 1
	file = all_particles_dose_mSv_d$i.out
	axis = reg
	part = all
	multiplier = all
    	mat mset1
	\$  (pSv/sec) (Sv/sec)	
	all ( 0.624151e4	 -202 )            \$ Dose in Sv/s/mA, 1mA ma 1/(1.602)*10^16 elekttonów/s, (dose factors are in pSv*cm2)
	
EOF
	


done
cat >> $workdir/run.inp << EOF
	[ T - T r a c k ]
    	title = Energies of neutrons and gammas in the box
	 mesh =  reg            # mesh type is region-wise
	 reg = 302 303 304 305
   	 e-type =   3            # e-mesh is log given by emin, emax and ne
	 emin =   c12      # minimum value of e-mesh points
         emax =   c13      # maximum value of e-mesh points
          ne =   c14            # number of e-mesh points
          unit =    1            # unit is [1/cm^2/source]
          axis =   eng            # axis of output
          file = particles_in_box.out  # file name of output for the above axis
          part = neutron photon   
	  	multiplier = all \$ The following is subsection of multiplier.
            part  = neutron photon
            emax  = c11
             mat        mset1
             all (0.624151e16)          \$ Fux per 1mA
             gshow =    1            # 0: no 1:bnd, 2:bnd+mat, 3:bnd+reg 4:bnd+lat
   	     epsout =    1            # (D=0) generate eps file by ANGEL    
          y-txt = Flux [1/(cm^2 mA)]
#    
EOF

cat >>$workdir/run.inp << EOF
  [ T - T r a c k ] 
   title = All particles flux for 1mA in target
   mesh = reg
   reg = 302 303 304 305
   e-type = 2
   ne = 1
   emin =   0.     # minimum value of e-mesh points
   emax =   c10      # maximum value of e-mesh points
   unit = 1
   file = particle_flux_in_box.out
   axis = reg
   part = photon neutron electron
   multiplier = all
   mat mset1
      all (0.624151e16)          \$ Fux per 1mA	 	

EOF

cat >> $workdir/run.inp << EOF
[ T - T r a c k ]
    title = Particle map XZ- plane
     mesh =  xyz            
   x-type =    2            
     xmin = -30.0           
     xmax =  30.0           
       nx =  300            
   y-type =    2            
     ymin = -1.0            
     ymax =  1.0            
       ny =    1            
   z-type =    2            
     zmin =   0.0           
     zmax =  60.0          
       nz =  600            
   e-type =    2            
     emin =   0.0           
     emax =   c10           
       ne =    1            
     unit =    1            
     axis =   xz            
  2D-type =    3            
     file = track_particle_xz.out
     part = neutron photon electron
    gshow =    3            
   epsout =    1            
#

[ T - T r a c k ]
    title = Particle map XY
     mesh =  xyz            
   x-type =    2            
     xmin = -30.0           
     xmax =  30.0           
       nx =  300            
   y-type =    2            
     ymin = -30.0           
     ymax =  30.0           
       ny =  300            
   z-type =    2            
     zmin =  c16+5           
     zmax =  c16+6        
       nz =    1            
   e-type =    2            
     emin =   0.0           
     emax =   c10           
       ne =    1            
     unit =    1            
     axis =   xy            
  2D-type =    3            
     file = track_particle_xy.out
     part = neutron photon electron
    gshow =    3            
   epsout =    1            
#

[ T - T r a c k ]
    title = Particle map YZ
     mesh =  xyz            
   x-type =    2            
     xmin = 20.0           
     xmax =  21.0           
       nx =  1            
   y-type =    2            
     ymin = -30.0           
     ymax =  30.0           
       ny =  300            
   z-type =    2            
     zmin =  -10.0           
     zmax =  60        
       nz =    700            
   e-type =    2            
     emin =   0.0           
     emax =   c10           
       ne =    1            
     unit =    1            
     axis =   yz            
  2D-type =    3            
     file = track_particle_yz.out
     part = neutron photon electron
    gshow =    3            
   epsout =    1            
#



EOF

cat >> $workdir/run.inp << EOF
[ T - D c h a i n ]
    title = Aktywacja calego ukladu
     mesh = reg
      reg = 119 302 303 304 305 306 307
     file = ./dchain/whole_sys.out
      amp = 0.624151e16
   timeevo = 2
    1.0 h 1.0
    7.0 d 0.0
   outtime = 5
    -1.0 s
    -30 m
    -12 h
    -3 d
     -7 d

EOF


cat >> $workdir/run.inp << EOF
[ T - Y i e l d ]
    title = New isotopes
     mesh = reg
      reg = 119                 
     part = all
     axis = chart               
     file = ./dchain/mapa_izotopow.out   
   epsout = 1                   
[ End ]
EOF


cd $workdir

ulimit -s unlimited
export OMP_NUM_THREADS=12
export OMP_STACKSIZE=1G
ulimit -s unlimited

phits_LinGfort_OMP < run.inp > out.log

cd ../../


