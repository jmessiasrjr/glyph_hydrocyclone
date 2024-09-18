##############################################################################
### Creates a database for hydrocyclones with (1, 2 or 4) circular or 
# rectangular inlet pipe ###
#
# Created first by Jose Messias on Jun. 09 2018
# Updated by Jose Messias on Aug. 23 2018 / Oct. 25 2018/ Oct. 31 2018/ 
# Nov. 02 2018/ Mar. 12 2019/ Mar. 25 2019 (GUI Tk)/ Mai. 15 2019 (VF2 size)
# Aug. 29 2019 (updated GUI)/ Sep. 12 2019 (underflow-overflow correction)/
# Apr. 16 2020 (add underflow vortex finder)
# Mar. 2 2022 (add O-H grid ratio for overflow pipe)
# CFD Laboratory at Federal University of Rio de Janeiro - Brazil
##############################################################################
##############################################################################
### Dimensions of the hydrocyclone (Pointwise is dimensionless, but in this 
# case it is considered milimeters [mm] units) ##

#    $DIAMC     -> Diameter of cylindrical part [mm]
#    $L1        -> length of cylindrical section [mm]

#    $DIAMU     -> Diameter of underflow pipe [mm]

#    $DIAMO     -> Diameter of overflow pipe [mm]
#    $DIAMOc    -> Diameter of internal overflow pipe [mm]
#    $VF        -> Vortex finder length [mm]
#    $VF2       -> Vortex finder length of the concentric overflow pipe [mm]

#    $DIAMI     -> Diameter of circular inlet pipe [mm]
#    $HC $BC    -> Dimensions of square inlet pipe [mm]

#    $DIAM(1,2,3,4) -> Diameter between 2 conic section [mm]
#    $VALUE(1,2,3,4) -> Angle/height between 2 conic section [degree/mm]

##############################################################################
package require PWI_Glyph 2.3
pw::Script loadTk

##############################################################################
############################### saved values #################################
##############################################################################
# Dimensions of the hydrocyclone 
# (mm - recommended dimension due to the tolerance error in trimmed surfaces)

# Number of overflow pipe(s) (concentric pipe?)
set NO 2

# Number of inlet pipe(s)
set NI 2

# Number of underflow pipe(s)
set NU 1

# Cylindrical section diameter and height
set DIAMC 70.
set L1 45.

# Diameter of OVERFLOW pipes D_{O}
set DIAMO 20.;  # (0)

set DIAMOc 10.; # (0)

# Diameter of UNDERFLOW pipes D_{U}
set DIAMU 25.;  # (0)

set DIAMUc 10.; # (0)

# Vortex Finder(s)
set VF 4
set VF2 $VF
set VFU 0

# Diameter of INLET pipes D_{I}
set DIAMI 25 ;# for cylindrical pipe
set HC 9.4 ;# for rectangular pipe
set BC 4.7 ;# for rectangular pipe
set HI 0. ;# space between cylindrical section ceiling and inlet pipe insertion

# Walls thickness
set WVF .5 ; # Vortex Finder wall thickness
set WVFOc .5 ; # Concentric overflow pipe wall thickness
set WVFU .5 ; # Underflow Vortex Finder wall thickness

# Type of inlet pipe
# ( 1 -> rectangular ; ANY -> cylindrical )
set SQUARE 1

# Shape format to butterfly topology in inlet pipe(s)
set TYPE "S"
set AUX 1

# Shape format to butterfly topology in overflow|underflow pipe(s)
set TYPE2 "S"

set OP 40. ; #overflow pipe length outside the hydrocyclone
set IP 60. ; #inlet pipe length
set UP 40. ; #underflow pipe length

# Maximum angle between two inlet pipe's butterfly topology section
# (for cylindrical only) [degree] [90,180)
set MAXANGLE 90
set MOVE 0. ; #move inlet pipe(s) from external wall towards to the hydrocyclone center point

# CONICAL SECTION number of parts (1-4)
set NCS 2

# Final Diameter of the conical section part
set DIAM1 40
set DIAM2 $DIAMU
set DIAM3 0
set DIAM4 0

# Use angle or height? 1: (type angle) ANY: (type height)
set A_H1 1
set A_H2 1
set A_H3 0
set A_H4 0

# Angle [degree] or height [length]    
set VALUE1 2.5
set VALUE2 1
set VALUE3 30
set VALUE4 20

# butterfly topology ratio of the central square diagonal 
# and the pipe diameter (diagonal_of_square / diameter_of_pipe)
set RVALUE 0.5

# Multiplier of D_{O} / D_{C} ratio 
# This is used on overflow-underflow connection 
# (dropped on GUI due to high aspect ratio of elements in conical section) 
set ROF 1.;# Outer pipe
set ROFc 1.;# Inner pipe

# Redo all databases and keep the previous databases? 
# (0 -> false, overwrite all) ; (ANY -> true, append new databases on layer 1)
set REEXECUTE 0

##############################################################################
##############################################################################
################################ PROCEDURES ##################################
##############################################################################
##############################################################################

########################################
# Rotation of the hydrocyclone on planes [degree] - initialization
set AXY 0
set AXZ 0
set AYZ 0

###################### balloon help ###############################
## downloaded at http://daniel.roche.free.fr/tkballoon/balloon.tcl ##
bind Bulle <Enter> {
    set Bulle(set) 0
    set Bulle(first) 1
    set Bulle(id) [after 500 {balloon %W $Bulle(%W) %X %Y}]
}

bind Bulle <Button> {
    set Bulle(first) 0
    kill_balloon
}

bind Bulle <Leave> {
    set Bulle(first) 0
    kill_balloon
}

bind Bulle <Motion> {
    if {$Bulle(set) == 0} {
        after cancel $Bulle(id)
        set Bulle(id) [after 500 {balloon %W $Bulle(%W) %X %Y}]
    }
}

proc set_balloon {target message} {
    global Bulle
    set Bulle($target) $message
    bindtags $target "[bindtags $target] Bulle"
}

proc kill_balloon {} {
    global Bulle
    after cancel $Bulle(id)
    if {[winfo exists .balloon] == 1} {
        destroy .balloon
    }
    set Bulle(set) 0
}

proc balloon {target message {cx 0} {cy 0} } {
    global Bulle
    if {$Bulle(first) == 1 } {
        set Bulle(first) 2
	if { $cx == 0 && $cy == 0 } {
	    set x [expr [winfo rootx $target] + ([winfo width $target]/2)]
	    set y [expr [winfo rooty $target] + [winfo height $target] + 4]
	} else {
	    set x [expr $cx + 4]
	    set y [expr $cy + 4]
	}
        toplevel .balloon -bg black
        wm overrideredirect .balloon 1
        label .balloon.l \
            -text $message -relief flat \
            -bg #ffffaa -fg black -padx 2 -pady 0 -anchor w
        pack .balloon.l -side left -padx 1 -pady 1
        wm geometry .balloon +${x}+${y}
        set Bulle(set) 1
    }
}

##################### procs ##################################
# Convert degree to radians
proc ConvDegree {angle} {
    set pi [expr {4 * atan(1.0)}]
    set deg2Rad [expr {$pi / 180.0}]
    set radian [expr {$angle * $deg2Rad}]
    return $radian
}

proc CentralizeInlet {d bc move extra} {
    set pi [expr {4 * atan(1.0)}]
    set theta1 [expr {acos( ($d/2-$move-$bc-$extra)/($d/2) )}]
    set theta2 [expr {acos( ($d/2-$move-$extra)/($d/2) )}]
    set theta [expr {45 - 90/$pi*($theta1+$theta2)}]
    return $theta
}

# Create connector with specified segment type and dimension
proc CreateDimCon { segmentType args } {
    # The types are Line and Circle
    set createCon [pw::Application begin Create]
    switch -exact $segmentType {
        Line {
            set seg [pw::SegmentSpline create]
            foreach pt $args {
                $seg addPoint $pt
            }
            $seg setSlope Linear     
            set con [pw::Curve create]
            $con addSegment $seg
        }
        Circle {
            set seg [pw::SegmentCircle create]
            $seg addPoint [lindex $args 0]
            $seg addPoint [lindex $args 1]
            $seg setCenterPoint [lindex $args 2]
            set con [pw::Curve create]
            $con addSegment $seg
        }
    }
    $createCon end
    return $con
}

# Create ruled surfaces using connectors
proc CreateRuledSurf { args } {
    set createRS [pw::Surface createFromCurves -tolerance 1e-2 \
[lindex $args]]
    return $createRS
}

# Assemble models from ruled surfaces
proc CreateModel {x} {
    set createMdl [pw::Model assemble -tolerance 1e-2 $x]
    return $createMdl
}

# Create 4 points and 1 center point to make a circle or square
proc CreatePoints {plane x y z h r rotate maxangle} {
    
    set rRad [ConvDegree $rotate]
    set mRad [ConvDegree [expr {$maxangle-90}]]
    
    set cr [expr {cos($rRad)}]
    set sr [expr {sin($rRad)}]
    set crm [expr {cos($rRad+$mRad)}]
    set srm [expr {sin($rRad+$mRad)}]

    # Create points
    if {$plane == "XY"} {
        set A "$x $y [expr {$z+$h}]"
        set B "[expr {$x+$crm*$r}] [expr {$y+$srm*$r}] [expr {$z+$h}]"
        set C "[expr {$x+$sr*$r}] [expr {$y-$cr*$r}] [expr {$z+$h}]"
        set D "[expr {$x-$crm*$r}] [expr {$y-$srm*$r}] [expr {$z+$h}]"
        set E "[expr {$x-$sr*$r}] [expr {$y+$cr*$r}] [expr {$z+$h}]"

    } elseif {$plane == "XZ"} {
        set A "$x [expr {$y+$h}] $z"
        set B "[expr {$x+$crm*$r}] [expr {$y+$h}] [expr {$z+$srm*$r}]"
        set C "[expr {$x+$sr*$r}] [expr {$y+$h}] [expr {$z-$cr*$r}]"
        set D "[expr {$x-$crm*$r}] [expr {$y+$h}] [expr {$z-$srm*$r}]"
        set E "[expr {$x-$sr*$r}] [expr {$y+$h}] [expr {$z+$cr*$r}]"

    } else {
        set A "[expr {$x+$h}] $y $z"
        set B "[expr {$x+$h}] [expr {$y+$crm*$r}] [expr {$z+$srm*$r}]"
        set C "[expr {$x+$h}] [expr {$y+$sr*$r}] [expr {$z-$cr*$r}]"
        set D "[expr {$x+$h}] [expr {$y-$crm*$r}] [expr {$z-$srm*$r}]"
        set E "[expr {$x+$h}] [expr {$y-$sr*$r}] [expr {$z+$cr*$r}]"
    }
    return [list $A $B $C $D $E]
}

# Create geometry on a plane -> XY, XZ or YZ #### *main procedure*
proc CreatePlaneCyl {type plane x y z h r1 r2 rotate maxangle} {
# type -> "C","R","O", any (Circle, Rounded-square, Octagonal, Square(default))
# plane -> 'XY', 'XZ' or 'YZ'
# x y z -> pipe center coordinate points
# h -> height
# r1 -> first base width
# r2 -> second base width
# rotate -> rotate geometry angle
# maxangle -> max angle between two points and center (makes an ellipse or retangular geometry)

    if {$type == "C" || $type == "R"} {set shape "Circle"} else {
        set shape "Line"}


    if {$type == "O"} {
        set Points [CreatePoints $plane $x $y $z 0 $r1 $rotate $maxangle]
        foreach {A B D F H} $Points break
        set Points2 [CreatePoints $plane $x $y $z 0 $r1 [expr {$rotate-(180.-$maxangle)/2}] 90]
        foreach {A C E G I} $Points2 break
    
        set PointsF [CreatePoints $plane $x $y $z $h $r2 $rotate $maxangle]
        foreach {AF BF DF FF HF} $PointsF break
        set PointsF2 [CreatePoints $plane $x $y $z $h $r2 [expr {$rotate-(180.-$maxangle)/2}] 90]
        foreach {AF CF EF GF IF} $PointsF2 break
    } else { 
        set Points [CreatePoints $plane $x $y $z 0 $r1 $rotate $maxangle]
        foreach {A B C D E} $Points break

        set PointsF [CreatePoints $plane $x $y $z $h $r2 $rotate $maxangle]
        foreach {AF BF CF DF EF} $PointsF break
    }
    if {$type == "R"} { ### extra shoulder points
        set PointsR [CreatePoints $plane $x $y $z 0 $r1 [expr {$rotate+135}] $maxangle]
        foreach {A AB AC AD AE} $PointsR break

        set PointsRF [CreatePoints $plane $x $y $z $h $r2 [expr {$rotate+135}] $maxangle]
        foreach {AF ABF ACF ADF AEF} $PointsRF break
    }

    # Create connectors to the first base
    if {$type == "C"} {set con_BC [CreateDimCon $shape $B $C $A]} elseif {
        $type == "R"} {set con_BC [CreateDimCon $shape $B $C $AB]} else {
            set con_BC [CreateDimCon $shape $B $C]}
    if {$type == "C"} {set con_CD [CreateDimCon $shape $C $D $A]} elseif {
        $type == "R"} {set con_CD [CreateDimCon $shape $C $D $AC]} else {
            set con_CD [CreateDimCon $shape $C $D]}
    if {$type == "C"} {set con_DE [CreateDimCon $shape $D $E $A]} elseif {
        $type == "R"} {set con_DE [CreateDimCon $shape $D $E $AD]} else {
            set con_DE [CreateDimCon $shape $D $E]}
    if {$type == "O"} {
        set con_EF [CreateDimCon $shape $E $F]
        set con_FG [CreateDimCon $shape $F $G]
        set con_GH [CreateDimCon $shape $G $H]
        set con_HI [CreateDimCon $shape $H $I]
        set con_IB [CreateDimCon $shape $I $B]
    } else {
    if {$type == "C"} {set con_EB [CreateDimCon $shape $E $B $A]} elseif {
        $type == "R"} {set con_EB [CreateDimCon $shape $E $B $AE]} else {
            set con_EB [CreateDimCon $shape $E $B]}
    }
    # Create connectors to the opposite base
    if {$type == "C"} {set con_BCF [CreateDimCon $shape $BF $CF $AF]} elseif {
        $type == "R"} {set con_BCF [CreateDimCon $shape $BF $CF $ABF]} else {
            set con_BCF [CreateDimCon $shape $BF $CF]}
    if {$type == "C"} {set con_CDF [CreateDimCon $shape $CF $DF $AF]} elseif {
        $type == "R"} {set con_CDF [CreateDimCon $shape $CF $DF $ACF]} else {
            set con_CDF [CreateDimCon $shape $CF $DF]}
    if {$type == "C"} {set con_DEF [CreateDimCon $shape $DF $EF $AF]} elseif {
        $type == "R"} {set con_DEF [CreateDimCon $shape $DF $EF $ADF]} else {
            set con_DEF [CreateDimCon $shape $DF $EF]}
    if {$type == "O"} {
        set con_EFF [CreateDimCon $shape $EF $FF]
        set con_FGF [CreateDimCon $shape $FF $GF]
        set con_GHF [CreateDimCon $shape $GF $HF]
        set con_HIF [CreateDimCon $shape $HF $IF]
        set con_IBF [CreateDimCon $shape $IF $BF]
    } else {
    if {$type == "C"} {set con_EBF [CreateDimCon $shape $EF $BF $AF]} elseif {
        $type == "R"} {set con_EBF [CreateDimCon $shape $EF $BF $AEF]} else {
            set con_EBF [CreateDimCon $shape $EF $BF]}
    }

    # Create the tie connectors
    set con_BBF [CreateDimCon Line $B $BF]
    set con_CCF [CreateDimCon Line $C $CF]
    set con_DDF [CreateDimCon Line $D $DF]
    set con_EEF [CreateDimCon Line $E $EF]
    if {$type == "O"} {
        set con_FFF [CreateDimCon Line $F $FF]
        set con_GGF [CreateDimCon Line $G $GF]
        set con_HHF [CreateDimCon Line $H $HF]
        set con_IIF [CreateDimCon Line $I $IF]
    }

    # Ruled surfaces
    set quil_BCBCF [CreateRuledSurf $con_BC $con_CCF $con_BCF $con_BBF]
    set quil_CDCDF [CreateRuledSurf $con_CD $con_DDF $con_CDF $con_CCF]
    set quil_DEDEF [CreateRuledSurf $con_DE $con_EEF $con_DEF $con_DDF]
    
    if {$type == "O"} {
        set quil_EFEFF [CreateRuledSurf $con_EF $con_FFF $con_EFF $con_EEF]
        set quil_FGFGF [CreateRuledSurf $con_FG $con_GGF $con_FGF $con_FFF]
        set quil_GHGHF [CreateRuledSurf $con_GH $con_HHF $con_GHF $con_GGF]
        set quil_HIHIF [CreateRuledSurf $con_HI $con_IIF $con_HIF $con_HHF]
        set quil_IBIBF [CreateRuledSurf $con_IB $con_BBF $con_IBF $con_IIF]
    } else {
        set quil_EBEBF [CreateRuledSurf $con_EB $con_BBF $con_EBF $con_EEF]
    }
    # Model (Transform Ruled surfaces in Quilts and assemble them)
    if {$type == "O"} {
        set model [CreateModel [list $quil_BCBCF $quil_CDCDF $quil_DEDEF \
$quil_EFEFF $quil_FGFGF $quil_GHGHF $quil_HIHIF $quil_IBIBF]]
    } else {
        set model [CreateModel [list $quil_BCBCF $quil_CDCDF $quil_DEDEF $quil_EBEBF]]
    }

    # Delete connectors
    $con_BC delete
    $con_CD delete
    $con_DE delete

    $con_BCF delete
    $con_CDF delete
    $con_DEF delete

    $con_CCF delete
    $con_BBF delete
    $con_DDF delete
    $con_EEF delete
    if {$type == "O"} {
        $con_EF delete
        $con_FG delete
        $con_GH delete
        $con_HI delete
        $con_IB delete

        $con_EFF delete
        $con_FGF delete
        $con_GHF delete
        $con_HIF delete
        $con_IBF delete

        $con_FFF delete
        $con_GGF delete
        $con_HHF delete
        $con_IIF delete
    } else {
        $con_EB delete
        $con_EBF delete
    }

    return $model
}

# Creates a shape that resembles a baffle inside a pipe geometry ##
proc Baffle {plane x y z h r R1 R2 angle} {
# plane -> 'XY' 'XZ' 'YZ'
# x y z -> pipe center coordinate points
# r -> normalized width of baffle [between 0-1]
# h -> length of baffle
# R1 -> pipe radius 1
# R2 -> pipe radius 2
# angle -> rotate angle

    set radian [ConvDegree $angle]
    set c [expr {cos($radian)}]
    set s [expr {sin($radian)}]

    # Create points    
        if {$plane == "XY"} {
        set B "[expr {$x+$c*$R1}] [expr {$y+$s*$R1}] [expr {$z}]"
        set D "[expr {$x+$c*($R1*$r)}] [expr {$y+$s*($R1*$r)}] [expr {$z}]"

        set BF "[expr {$x+$c*$R2}] [expr {$y+$s*$R2}] [expr {$z+$h}]"
        set DF "[expr {$x+$c*($R2*$r)}] [expr {$y+$s*($R2*$r)}] \
[expr {$z+$h}]"        
    } elseif {$plane == "XZ"} {
        set B "[expr {$x+$c*$R1}] [expr {$y}] [expr {$z+$s*$R1}]"
        set D "[expr {$x+$c*($R1*$r)}] [expr {$y}] [expr {$z+$s*($R1*$r)}]"

        set BF "[expr {$x+$c*$R2}] [expr {$y+$h}] [expr {$z+$s*$R2}]"
        set DF "[expr {$x+$c*($R2*$r)}] [expr {$y+$h}] \
[expr {$z+$s*($R2*$r)}]"
    } else {
        set B "[expr {$x}] [expr {$y+$c*$R1}] [expr {$z+$s*$R1}]"
        set D "[expr {$x}] [expr {$y+$c*($R1*$r)}] [expr {$z+$s*($R1*$r)}]"

        set BF "[expr {$x+$h}] [expr {$y+$c*$R2}] [expr {$z+$s*$R2}]"
        set DF "[expr {$x+$h}] [expr {$y+$c*($R2*$r)}] \
[expr {$z+$s*($R2*$r)}]"
    }
    
    # Create connectors
    set con_BD [CreateDimCon Line $B $D]
    set con_BBF [CreateDimCon Line $B $BF]
    set con_BFDF [CreateDimCon Line $BF $DF]
    set con_DDF [CreateDimCon Line $D $DF]
    
    # Ruled surfaces
    set quil_BDBFDF [CreateRuledSurf $con_BD $con_BBF $con_BFDF $con_DDF]

    # Model (Transform Ruled surfaces into Quilts)
    set model [CreateModel $quil_BDBFDF]

    # Delete connectors
    $con_BD delete
    $con_BBF delete
    $con_BFDF delete
    $con_DDF delete
    
    return $model
}

# Create Cylindrical Inlet pipe(s)
proc CreateInletCyl {model type plane x y z h r R rotate proj maxangle} {
# model -> geometry model used to trim surfaces
# proj -> It's a projection onto a surface? 1 - YES, Any - NO

    set modelSIP [CreatePlaneCyl $type $plane $x $y $z $h [expr {$r/2.}] \
[expr {$r/2.}] $rotate $maxangle]
    if {$proj == 1} {
        set modelIP [CreatePlaneCyl "S" $plane $x $y $z $h $r $r $rotate $maxangle]
        $model trimBySurfaces -tolerance 1e-2 -mode First -keep Both \
$modelSIP
        $model trimBySurfaces -tolerance 1e-2 -mode First -keep Both \
$modelIP
        $modelSIP delete -dependents
        $modelIP delete -dependents
    } else {
        set modelIP [CreatePlaneCyl "C" $plane $x $y $z $h $r $r $rotate $maxangle]
        for {set i 0} {$i < 4} {incr i} {
            set modelBP [Baffle $plane $x $y $z $h "0.5" $r $r \
[expr {$rotate+90*$i+($maxangle-90)*(($i+1)%2)}]]
            $modelBP trimBySurfaces -tolerance 1e-2 -mode First -keep \
Inside $model
        }
        $modelSIP trimBySurfaces -tolerance 1e-2 -mode First -keep Inside \
$model
        $modelIP trimBySurfaces -tolerance 1e-2 -mode Both -keep Inside \
$model
        set model [CreateModel [list $model $modelIP]] 
    }
}

# Create Rectangular Inlet pipe(s)
proc CreateInletSqr {model type plane x y z h r R rotate proj maxangle} {
# model -> model used to trim surfaces
# proj -> It's a projection onto a surface? 1 - YES, Any - NO

    set modelIP [CreatePlaneCyl "S" $plane $x $y $z $h $r $r $rotate $maxangle]
    if {$proj == 1} {
        $modelIP trimBySurfaces -tolerance 1e-2 -mode Both -keep Both \
[list $model $modelIP] 
        $modelIP delete -dependents
    } else {
        $modelIP trimBySurfaces -tolerance 1e-2 -mode Both -keep Inside \
$model
        set model [CreateModel [list $model $modelIP]] 
    }
}

# Create the overflow pipe
proc CreateOF {plane type x y z h r R rotate concentric {ratio "0.5"}} {
# what to do? 1 - wall, 2 - baffles, Any - All
    if {$concentric ne 1} {
        set modelSOF [CreatePlaneCyl $type $plane $x $y $z $h \
[expr {$r*$ratio}] [expr {$R*$ratio}] $rotate 90]
        for {set i 0} {$i < 4} {incr i} {
            set modelBP [Baffle $plane $x $y $z $h $ratio $r $R \
[expr {$rotate+90*$i}]]
        }
    }
    if {$concentric ne 2} {
        set modelOF [CreatePlaneCyl "C" $plane $x $y $z $h $r $R $rotate 90]
    }
}

# cut models using plane
proc CutPlane {x y z model} {
    set planeCut [pw::Plane create] 
    $planeCut setPointNormal "$x $y $z" "0 0 1"
    foreach M $model {
        $M trimBySurfaces -tolerance 1e-2 -mode First -keep Both $planeCut
    }
    $planeCut delete
}

# creates underflow-overflow connection
proc CreateUndOver {no ncs l1 vf height diam diamo diamc type rotate k rvalue {n "1"}} {
    if {$vf<$l1} {
        lappend overund [CreateOF "XY" $type "0" "0" [expr {-$vf}] \
[expr {$vf-$l1}] [expr {$diamo/2.}] [expr {$n*$diamo/2.}] $rotate $k $rvalue]
    }
    set ratio [expr {$n*$diamo/$diamc}]
    set hi $l1
    for {set i 0} {$i < $ncs} {incr i 1} {
        set hf [expr {$hi+[lindex $height $i]}]
        if {$vf>$hi & $vf<$hf} {
            set h1 $vf} elseif {$vf>$hf} {
            set hi $hf; continue} else {
            set h1 $hi
        }
        set h2 $hf
        if {$i == 0 || $h1 == $vf} {
            set d1 [expr {$n*$diamo}]} else {
            set d1 [expr {[lindex $diam $i-1]*$ratio}]
        }
            set d2 [expr {[lindex $diam $i]*$ratio}]
        lappend overund [CreateOF "XY" $type "0" "0" [expr {-$h1}] \
[expr {$h1-$h2}] [expr {$d1/2.}] [expr {$d2/2.}] $rotate $k $rvalue]
        set hi $hf
    }
}

proc func {diamc x} {
    return [expr sqrt($diamc*$diamc-$x*$x)]
}

proc CreateSquareInletCut {plane a b diamc hi move xneg yneg} {
    set pi [expr {4. * atan(1.0)}]
    set diam [expr {$diamc - $move}]

# Boole's rule -> 5-point-closed
#    set AreaC [expr ($b/90)*(7*[func $diamc [expr ($diam-$b)]] + \
#32*[func $diamc [expr ($diam-3*$b/4)]] + 12*[func $diamc [expr ($diam-$b/2)]] \
#+ 32*[func $diamc [expr ($diam-$b/4)]] + 7*[func $diamc $diam]) ]

# 10-point-closed, almost exact
    set AreaC [expr ($b/89600)*(2857*([func $diamc [expr ($diam-$b)]]+[func $diamc $diam]) + \
15741*([func $diamc [expr ($diam-$b/9)]] + [func $diamc [expr ($diam-8*$b/9)]]) + \
1080*([func $diamc [expr ($diam-2*$b/9)]] + [func $diamc [expr ($diam-7*$b/9)]]) + \
19344*([func $diamc [expr ($diam-3*$b/9)]] + [func $diamc [expr ($diam-6*$b/9)]]) + \
5778*([func $diamc [expr ($diam-4*$b/9)]] + [func $diamc [expr ($diam-5*$b/9)]])) ]

    set xf [expr {$xneg*sqrt($diamc*$diamc - ($diam-$b)*($diam-$b))}]
    set AreaT [expr {abs($xf*$b)/2}]
    set xi [expr {2*$xneg*abs($AreaC-$AreaT)/$b}]
    set yf [expr {$yneg*$diam}]
    set yi [expr {$yneg*($diam-$b)}]
    set zf [expr {-$hi}]
    set zi [expr {-$hi-$a}]

    #set bn [expr sqrt(($xf-$xi)*($xf-$xi)+$b*$b)]
    #set r [expr {sqrt(($a*$a + $bn*$bn)/4.)}]
    #set maxang [expr {2*asin($a/(2.*$r))*180/$pi}]

    if {$plane=="YZ"} {
        set B "$xf $yi $zi"
        set C "$xi $yf $zi"
        set D "$xi $yf $zf"
        set E "$xf $yi $zf"
    } else {
        set B "$yf $xi $zi"
        set C "$yi $xf $zi"
        set D "$yi $xf $zf"
        set E "$yf $xi $zf"
    }

   set auxLine1 [CreateDimCon Line $B $C]
   set auxLine2 [CreateDimCon Line $C $D]
   set auxLine3 [CreateDimCon Line $D $E]
   set auxLine4 [CreateDimCon Line $E $B]

   set model [CreateRuledSurf $auxLine1 $auxLine2 $auxLine3 $auxLine4]
   return $model
}

########################################
### GEOMETRY OF THE HYDROCYCLONE ###
########################################
########################################
### MODELS and QUILTS ###
########################################

proc runScript {} {
    global NI
    global NO
    global NU
    global DIAMC
    global L1
    global DIAMO
    global DIAMOc
    global VF
    global VF2
    global VFU
    global DIAMU
    global DIAMUc
    global DIAMI
    global HC
    global BC
    global HI
    global AXY
    global AXZ
    global AYZ
    global TYPE
    global TYPE2
    global SQUARE
    global MAXANGLE
    global MOVE
    global IP
    global OP
    global UP
    global WVF
    global WVFU
    global WVFOc
    global NCS
    global DIAM1
    global DIAM2
    global DIAM3
    global DIAM4
    global A_H1
    global A_H2
    global A_H3
    global A_H4
    global VALUE1
    global VALUE2
    global VALUE3
    global VALUE4
    global AUX
    global RVALUE
    global ROF
    global ROFc
    global REEXECUTE

    set DIAM [list $DIAM1 $DIAM2 $DIAM3 $DIAM4]
    set A_H [list $A_H1 $A_H2 $A_H3 $A_H4]
    set VALUE [list $VALUE1 $VALUE2 $VALUE3 $VALUE4]

    if {$REEXECUTE == 0} {
        pw::Application reset Database
        pw::Application setCAESolver {OpenFOAM} 3
    }

    set tol 0.00001
    if {$MOVE<$tol} {set MOVE $tol}

    # Align Inlet pipe(s) to center in quarter cylindrical section
    if {$SQUARE == 1} {
        set AXY [CentralizeInlet $DIAMC $BC $MOVE "0"]} else {
        set d1 [expr {$DIAMI*cos([ConvDegree $MAXANGLE]/2.)}]
        set d2 [expr {($DIAMI-$d1)/2.}]
        set AXY [CentralizeInlet $DIAMC $d1 $MOVE $d2]
    }

    if {$REEXECUTE == 1} {set curLayer "1"} else {set curLayer "5"}
    pw::Display setCurrentLayer $curLayer
    pw::Layer setDescription $curLayer {Vortex finder database}

# Vortex Finder model
    set rvf [expr {$DIAMO/2.+$WVF}]
    set modelVF [CreatePlaneCyl "C" "XY" "0" "0" "0" -$VF $rvf $rvf $AXY 90]

    if {$REEXECUTE == 1} {set curLayer "1"} else {set curLayer "10"}
    pw::Display setCurrentLayer $curLayer
    pw::Layer setDescription $curLayer {Overflow pipe(s) database}

# Overflow pipe model
    if {$NO == 1 || $NO == 2} {
        set rop [expr {$DIAMO/2.}]
        set modelOP [CreateOF "XY" $TYPE2 "0" "0" $OP [expr {-$OP-$VF}] $rop $rop \
$AXY "1" $RVALUE]
        set modelOPw [CreatePlaneCyl "C" "XY" "0" "0" -$VF "0" $rvf $rop $AXY 90]
    }

    if {$NO == 2} {
        set ropi [expr {$DIAMOc/2.}]
        if {$VF2 > $VF} {
            set modelOPi [CreateOF "XY" $TYPE2 "0" "0" $OP [expr {-$OP-$VF}] \
$ropi $ropi $AXY "0" $RVALUE]
            set modelOPiw [CreateOF "XY" $TYPE2 "0" "0" $OP [expr {-$OP-$VF}] \
[expr {$ropi+$WVFOc}] [expr {$ropi+$WVFOc}] $AXY "1" $RVALUE]
            set modelOPi2 [CreateOF "XY" $TYPE2 "0" "0" -$VF [expr {$VF-$VF2}] \
$ropi $ropi $AXY "0" $RVALUE]
            set modelOPiw2 [CreateOF "XY" $TYPE2 "0" "0" -$VF [expr {$VF-$VF2}] \
[expr {$ropi+$WVFOc}] [expr {$ropi+$WVFOc}] $AXY "1" $RVALUE]
        } else { 
            set modelOPi [CreateOF "XY" $TYPE2 "0" "0" $OP [expr {-$OP-$VF2}] \
$ropi $ropi $AXY "0" $RVALUE]
            set modelOPiw [CreateOF "XY" $TYPE2 "0" "0" $OP [expr {-$OP-$VF2}] \
[expr {$ropi+$WVFOc}] [expr {$ropi+$WVFOc}] $AXY "1" $RVALUE]
        }
        set modelOPiw2 [CreatePlaneCyl "C" "XY" "0" "0" -$VF2 "0" $ropi \
[expr {$ropi+$WVFOc}] $AXY 90]
    } else {
        set modelOPpj [CreateOF "XY" $TYPE2 "0" "0" $OP [expr {-$OP-$VF}] $rop $rop \
$AXY "2" $RVALUE]
    }

    if {$REEXECUTE == 1} {set curLayer "1"} else {set curLayer "15"}
    pw::Display setCurrentLayer $curLayer
    pw::Layer setDescription $curLayer {Cylindrical sect database}

# Cylindrical section model
    set R [expr {$DIAMC/2.}]
    set modelCSW [CreatePlaneCyl "C" "XY" "0" "0" "0" "0" $R $rvf $AXY 90]
    set modelCS [CreatePlaneCyl "C" "XY" "0" "0" "0" -$L1 $R $R $AXY 90]

    if {$REEXECUTE == 1} {set curLayer "1"} else {set curLayer "20"}
    pw::Display setCurrentLayer $curLayer
    pw::Layer setDescription $curLayer {Conical sections database}

# Conical section model
    set H $L1
    for {set i 0} {$i < $NCS} {incr i 1} {
        if {$i == 0} {set d1 $DIAMC; set d2 [lindex $DIAM $i]} else {
            set d1 [lindex $DIAM $i-1]; set d2 [lindex $DIAM $i]}
        if {[lindex $A_H $i] == 1} {
            set ang [ConvDegree [lindex $VALUE $i]]
            set h [expr {($d1-$d2)/(2.*tan($ang))}]
        } else { 
            set h [lindex $VALUE $i]
        }
        set H [expr {$H+$h}]
        lappend height $h
        lappend modelS [CreatePlaneCyl "C" "XY" "0" "0" [expr {-$H+$h}] [expr {-$h}] \
[expr {$d1/2.}] [expr {$d2/2.}] $AXY 90]
    }

    set modelSC [CreateModel $modelS]

    if {$REEXECUTE == 1} {set curLayer "1"} else {set curLayer "23"}
    pw::Display setCurrentLayer $curLayer
    pw::Layer setDescription $curLayer {Underflow pipe database}

# Underflow pipe model
    if {$UP > 0} {
         set modelUP [CreatePlaneCyl "C" "XY" "0" "0" [expr {-$H}] [expr {-$UP}] \
[expr {$DIAMU/2.}] [expr {$DIAMU/2.}] $AXY 90]         
    }
    if {$NU == 2} {
        set rvfu [expr {$DIAMUc/2.+$WVFU}]

        if {$VFU > $tol} {
            set modelVFu [CreatePlaneCyl "C" "XY" "0" "0" [expr {-$H+$VFU}] [expr {-$VFU}] $rvfu $rvfu $AXY 90]
            lappend modelVFu [CreatePlaneCyl "C" "XY" "0" "0" -$H -$UP $rvfu $rvfu $AXY 90]
        } else {
            set modelVFu [CreatePlaneCyl "C" "XY" "0" "0" -$H -$UP $rvfu $rvfu $AXY 90]
        }

        set rup [expr {$DIAMUc/2.}]
        set modelVFu [CreateOF "XY" $TYPE2 "0" "0" [expr {-$H+$VFU}] [expr {-$UP-$VFU}] $rup $rup \
$AXY "1"]
        set modelVFuw [CreatePlaneCyl "C" "XY" "0" "0" [expr {-$H+$VFU}] "0" $rvfu $rup $AXY 90]
        set modelVFupj [CreateOF "XY" $TYPE2 "0" "0" [expr {-$H+$VFU}] [expr {-$UP-$VFU}] $rup $rup \
$AXY "2"]
    }

    if {$REEXECUTE == 1} {set curLayer "1"} else {set curLayer "25"}
    pw::Display setCurrentLayer $curLayer
    pw::Layer setDescription $curLayer {Overflow-Underflow database}

# Overflow-Underflow connection model
    set diamt $DIAM
    if {$NU == 2} {
        #set Dru [expr {$DIAMUc*($DIAMC/$DIAMO)}]
        set newh [expr {[lindex $height $i-1]-$VFU}]
        lset height end $newh
        #lset diamt $NCS-1 $Dru
    }
    if {$NO == 2} {
    # correct overflow
        if {$VF2 > $VF} {
            set VFg $VF2
            set modelVFVF2 [CreatePlaneCyl "C" "XY" "0" "0" [expr {-$VF}] \
[expr {$VF-$VF2}] [expr {$rop}] [expr {$rop}] $AXY 90]} elseif {$VF2 < $VF} {
            set VFg $VF
            set modelVFVF2 [CreateOF "XY" $TYPE2 "0" "0" -$VF2 [expr {$VF2-$VF}] \
$ropi $ropi $AXY "0" $RVALUE]
            eval [CutPlane "0" "0" -$VF2 $modelOP]} else {
            set VFg $VF
        }
        set undOver [CreateUndOver $NO $NCS $L1 $VFg $height $diamt $DIAMO $DIAMC \
$TYPE2 $AXY "1" $RVALUE $ROF]
        lappend undOver [CreateUndOver $NO $NCS $L1 $VFg $height $diamt $DIAMOc $DIAMC \
$TYPE2 $AXY "0" $RVALUE $ROFc]
        if {$UP > 0} {
            set modelDUDU [CreateOF "XY" $TYPE2 "0" "0" [expr -$H] -$UP \
[expr {$ROF*$DIAMU*$DIAMO/(2*$DIAMC)}] [expr {$ROF*$DIAMU*$DIAMO/(2*$DIAMC)}] $AXY "1" $RVALUE]
            lappend modelDUDU [CreateOF "XY" $TYPE2 "0" "0" [expr -$H] -$UP \
[expr {$ROFc*$DIAMU*$DIAMOc/(2*$DIAMC)}] [expr {$ROFc*$DIAMU*$DIAMOc/(2*$DIAMC)}] $AXY "0" $RVALUE]
        }
    } else { 
        set VFg $VF
        set undOver [CreateUndOver $NO $NCS $L1 $VFg $height $diamt $DIAMO $DIAMC \
$TYPE2 $AXY "0" $RVALUE $ROF]
        if {($UP > 0) && ($NU !=2)} {set modelDUDU [CreateOF "XY" $TYPE2 "0" "0" [expr -$H] \
-$UP [expr {$ROF*$DIAMU*$DIAMO/(2*$DIAMC)}] [expr {$ROF*$DIAMU*$DIAMO/(2*$DIAMC)}] $AXY "0"]}
    }

    if {$REEXECUTE == 1} {set curLayer "1"} else {set curLayer "30"}
    pw::Display setCurrentLayer $curLayer
    pw::Layer setDescription $curLayer {Inlet pipe(s) database}

# Inlet pipe model
    set pi [expr {4. * atan(1.0)}]
    set sd [expr {($DIAMO+2.*$WVF)/$DIAMC}]

    if {$SQUARE == 1} {
        set CreateI "CreateInletSqr"
        set r [expr {sqrt(($HC*$HC + $BC*$BC)/4.)}]
        set R $r
        set x1 [expr {-$DIAMC/2.+$BC/2.+$MOVE}]
        set x2 [expr {-$HC/2.-$HI-$tol}]
        set maxang [expr {2*asin($HC/(2.*$r))*180/$pi}]
        set AYZ [expr {(180.-$maxang)/2.}]
        # projection variables
        set rpj [expr {sqrt(($HC*$HC + $BC*$sd*$BC*$sd)/4.)}]
        set Rpj $rvf
        set x1pj [expr {-$rvf+$sd*$BC/2.+$MOVE*$sd}]
        set x2pj $x2
        set maxangpj [expr {2*asin($HC/(2*$rpj))*180/$pi}]
        set AYZpj [expr {(180.-$maxangpj)/2.}]
    } else {
        set CreateI "CreateInletCyl"
        set r [expr {$DIAMI/2.}]
        set x1 [expr {-$R+$r+$MOVE}]
        set x2 [expr {-$r-$HI}]
        set AYZ [expr {(180.-$MAXANGLE)/2.}]
        set maxang $MAXANGLE
        # projection variables
        set rpj [expr {$r*$sd}]
        set Rpj $rvf
        set x1pj [expr {-$rvf+$sd*$r+$MOVE*$sd}]
        set x2pj [expr {-$HI-$r*$sd}]
        set maxangpj $maxang
        set AYZpj $AYZ
    }

    if {($NI == 4) || ($NI == 2) || ($NI == 1)} { # one inlet pipe

        set modelIP [$CreateI $modelCS $TYPE "YZ" "0" $x1 $x2 -$IP \
$r $R $AYZ "0" $maxang]
    # Inlet pipe projection on Vortex finder
        set modelIPS [$CreateI $modelVF $TYPE "YZ" "0" $x1pj $x2pj \
[expr {-$IP*$sd}] $rpj $Rpj $AYZpj "1" $maxangpj]
        if {$AUX==1} {
            set auxCon1 [CreateSquareInletCut "YZ" $HC $BC [expr $DIAMC/2] $HI $MOVE "-1" "-1"]
        }
    }

    if {($NI == 4) || ($NI == 2)} { # two inlet pipes
    # Creates second Inlet pipe model
        set modelIP2 [$CreateI $modelCS $TYPE "YZ" $IP [expr {-$x1}] \
$x2 -$IP $r $R $AYZ "0" $maxang]
    # Inlet pipe projection on Vortex finder
        set modelIPS2 [$CreateI $modelVF $TYPE "YZ" [expr {$IP*$sd}] \
[expr {-$x1pj}] $x2pj [expr {-$IP*$sd}] $rpj $Rpj $AYZpj "1" $maxangpj]
        if {$AUX==1} {
            set auxCon2 [CreateSquareInletCut "YZ" $HC $BC [expr $DIAMC/2] $HI $MOVE "1" "1"]
        }
    }

    if {($NI == 4)} { # four inlet pipes
    set AXZ $AYZ; set AXZpj $AYZpj
    # Creates third Inlet pipe model
        set modelIP3 [$CreateI $modelCS $TYPE "XZ" [expr {-$x1}] -$IP \
$x2 $IP $r $R $AXZ "0" $maxang]
    # Inlet pipe projection on Vortex finder
        set modelIPS3 [$CreateI $modelVF $TYPE "XZ" [expr {-$x1pj}] \
[expr {-$IP*$sd}] $x2pj [expr {$IP*$sd}] $rpj $Rpj $AXZpj "1" $maxangpj]
    # Creates fourth Inlet pipe model
        set modelIP4 [$CreateI $modelCS $TYPE "XZ" $x1 "0" $x2 $IP \
$r $R $AXZ "0" $maxang]
    # Inlet pipe projection on Vortex finder
        set modelIPS4 [$CreateI $modelVF $TYPE "XZ" $x1pj "0" $x2pj \
[expr {$IP*$sd}] $rpj $Rpj $AXZpj "1" $maxangpj]
        if {$AUX==1} {
            set auxCon3 [CreateSquareInletCut "XZ" $HC $BC [expr $DIAMC/2] $HI $MOVE "1" "-1"]
            set auxCon3 [CreateSquareInletCut "XZ" $HC $BC [expr $DIAMC/2] $HI $MOVE "-1" "1"]
        }
    }

    if {$REEXECUTE == 1} {set curLayer "1"} else {set curLayer "35"}

# Assemble hydrocyclone main body
    set modelBody [CreateModel [list $modelCSW $modelCS $modelVF $modelOP \
$modelOPw $modelSC]]
    if {$UP > 0} {set modelBody [CreateModel [list $modelBody $modelUP]]}
    $modelBody setName "Hydrocyclone body"
    set Body [pw::Collection create]
    $Body set $modelBody
    $Body do setLayer $curLayer
    pw::Layer setDescription $curLayer {Body database}

    pw::Display isolateLayer $curLayer
    pw::Display showLayer $curLayer

    if {$REEXECUTE == 1} {set curLayer "1"} else {set curLayer "40"}
    pw::Display setCurrentLayer $curLayer

    pw::Display update

# Round variables to display in Tk GUI
set AYZ [expr {double(round($AYZ*1e4))/1e4}]
set AXZ [expr {double(round($AXZ*1e4))/1e4}]
set AXY [expr {double(round($AXY*1e4))/1e4}]
set MAXANGLE [expr {double(round($MAXANGLE*1e4))/1e4}]
}

###########################################
############## Tk Windows #################
###########################################

proc pwLogo {} {
  set logoData "
R0lGODlheAAYAIcAAAAAAAICAgUFBQkJCQwMDBERERUVFRkZGRwcHCEhISYmJisrKy0tLTIyMjQ0
NDk5OT09PUFBQUVFRUpKSk1NTVFRUVRUVFpaWlxcXGBgYGVlZWlpaW1tbXFxcXR0dHp6en5+fgBi
qQNkqQVkqQdnrApmpgpnqgpprA5prBFrrRNtrhZvsBhwrxdxsBlxsSJ2syJ3tCR2siZ5tSh6tix8
ti5+uTF+ujCAuDODvjaDvDuGujiFvT6Fuj2HvTyIvkGKvkWJu0yUv2mQrEOKwEWNwkaPxEiNwUqR
xk6Sw06SxU6Uxk+RyVKTxlCUwFKVxVWUwlWWxlKXyFOVzFWWyFaYyFmYx16bwlmZyVicyF2ayFyb
zF2cyV2cz2GaxGSex2GdymGezGOgzGSgyGWgzmihzWmkz22iymyizGmj0Gqk0m2l0HWqz3asznqn
ynuszXKp0XKq1nWp0Xaq1Hes0Xat1Hmt1Xyt0Huw1Xux2IGBgYWFhYqKio6Ojo6Xn5CQkJWVlZiY
mJycnKCgoKCioqKioqSkpKampqmpqaurq62trbGxsbKysrW1tbi4uLq6ur29vYCu0YixzYOw14G0
1oaz14e114K124O03YWz2Ie12oW13Im10o621Ii22oi23Iy32oq52Y252Y+73ZS51Ze81JC625G7
3JG825K83Je72pW93Zq92Zi/35G+4aC90qG+15bA3ZnA3Z7A2pjA4Z/E4qLA2KDF3qTA2qTE3avF
36zG3rLM3aPF4qfJ5KzJ4LPL5LLM5LTO4rbN5bLR6LTR6LXQ6r3T5L3V6cLCwsTExMbGxsvLy8/P
z9HR0dXV1dbW1tjY2Nra2tzc3N7e3sDW5sHV6cTY6MnZ79De7dTg6dTh69Xi7dbj7tni793m7tXj
8Nbk9tjl9N3m9N/p9eHh4eTk5Obm5ujo6Orq6u3t7e7u7uDp8efs8uXs+Ozv8+3z9vDw8PLy8vL0
9/b29vb5+/f6+/j4+Pn6+/r6+vr6/Pn8/fr8/Pv9/vz8/P7+/gAAACH5BAMAAP8ALAAAAAB4ABgA
AAj/AP8JHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNqZCioo0dC0Q7Sy2btlitisrjpK4io4yF/
yjzKRIZPIDSZOAUVmubxGUF88Aj2K+TxnKKOhfoJdOSxXEF1OXHCi5fnTx5oBgFo3QogwAalAv1V
yyUqFCtVZ2DZceOOIAKtB/pp4Mo1waN/gOjSJXBugFYJBBflIYhsq4F5DLQSmCcwwVZlBZvppQtt
D6M8gUBknQxA879+kXixwtauXbhheFph6dSmnsC3AOLO5TygWV7OAAj8u6A1QEiBEg4PnA2gw7/E
uRn3M7C1WWTcWqHlScahkJ7NkwnE80dqFiVw/Pz5/xMn7MsZLzUsvXoNVy50C7c56y6s1YPNAAAC
CYxXoLdP5IsJtMBWjDwHHTSJ/AENIHsYJMCDD+K31SPymEFLKNeM880xxXxCxhxoUKFJDNv8A5ts
W0EowFYFBFLAizDGmMA//iAnXAdaLaCUIVtFIBCAjP2Do1YNBCnQMwgkqeSSCEjzzyJ/BFJTQfNU
WSU6/Wk1yChjlJKJLcfEgsoaY0ARigxjgKEFJPec6J5WzFQJDwS9xdPQH1sR4k8DWzXijwRbHfKj
YkFO45dWFoCVUTqMMgrNoQD08ckPsaixBRxPKFEDEbEMAYYTSGQRxzpuEueTQBlshc5A6pjj6pQD
wf9DgFYP+MPHVhKQs2Js9gya3EB7cMWBPwL1A8+xyCYLD7EKQSfEF1uMEcsXTiThQhmszBCGC7G0
QAUT1JS61an/pKrVqsBttYxBxDGjzqxd8abVBwMBOZA/xHUmUDQB9OvvvwGYsxBuCNRSxidOwFCH
J5dMgcYJUKjQCwlahDHEL+JqRa65AKD7D6BarVsQM1tpgK9eAjjpa4D3esBVgdFAB4DAzXImiDY5
vCFHESko4cMKSJwAxhgzFLFDHEUYkzEAG6s6EMgAiFzQA4rBIxldExBkr1AcJzBPzNDRnFCKBpTd
gCD/cKKKDFuYQoQVNhhBBSY9TBHCFVW4UMkuSzf/fe7T6h4kyFZ/+BMBXYpoTahB8yiwlSFgdzXA
5JQPIDZCW1FgkDVxgGKCFCywEUQaKNitRA5UXHGFHN30PRDHHkMtNUHzMAcAA/4gwhUCsB63uEF+
bMVB5BVMtFXWBfljBhhgbCFCEyI4EcIRL4ChRgh36LBJPq6j6nS6ISPkslY0wQbAYIr/ahCeWg2f
ufFaIV8QNpeMMAkVlSyRiRNb0DFCFlu4wSlWYaL2mOp13/tY4A7CL63cRQ9aEYBT0seyfsQjHedg
xAG24ofITaBRIGTW2OJ3EH7o4gtfCIETRBAFEYRgC06YAw3CkIqVdK9cCZRdQgCVAKWYwy/FK4i9
3TYQIboE4BmR6wrABBCUmgFAfgXZRxfs4ARPPCEOZJjCHVxABFAA4R3sic2bmIbAv4EvaglJBACu
IxAMAKARBrFXvrhiAX8kEWVNHOETE+IPbzyBCD8oQRZwwIVOyAAXrgkjijRWxo4BLnwIwUcCJvgP
ZShAUfVa3Bz/EpQ70oWJC2mAKDmwEHYAIxhikAQPeOCLdRTEAhGIQKL0IMoGTGMgIBClA9QxkA3U
0hkKgcy9HHEQDcRyAr0ChAWWucwNMIJZ5KilNGvpADtt5JrYzKY2t8nNbnrzm+B8SEAAADs="

    return [image create photo -format GIF -data $logoData]
}

proc tk_GUI {} {
    global NI
    global NO
    global NU
    global DIAMC
    global L1
    global DIAMO
    global DIAMOc
    global VF
    global VF2
    global VFU
    global DIAMU
    global DIAMUc
    global DIAMI
    global HC
    global BC
    global HI
    global AXY
    global AXZ
    global AYZ
    global TYPE
    global TYPE2
    global SQUARE
    global MAXANGLE
    global MOVE
    global IP
    global OP
    global UP
    global WVF
    global WVFU
    global WVFOc
    global NCS
    global DIAM1
    global DIAM2
    global DIAM3
    global DIAM4
    global A_H1
    global A_H2
    global A_H3
    global A_H4
    global VALUE1
    global VALUE2
    global VALUE3
    global VALUE4
    global AUX
    global RVALUE
    global REEXECUTE

    wm title . "Hydrocyclone Database"
    pack [frame .logo] -padx 20 -fill x

    pack [label .logo.img -image [pwLogo] -bd 0 -relief sunken] -padx 40 -fill x

    pack [frame .cylsection -relief sunken -bd 1] -padx 20 -fill x

    grid [label .cylsection.lt -text "Cylindrical section"] -in .cylsection -row 1 -column 1 -columnspan 4
    grid [label .cylsection.l1 -text "D_C"] -in .cylsection -row 2 -column 1
    grid [entry .cylsection.e1 -width 12 -textvariable DIAMC]  -in .cylsection -row 2 -column 2
    set_balloon .cylsection.e1 "Cylindrical section diameter"

    grid [label .cylsection.l2 -text "  L_1"] -in .cylsection -row 2 -column 3
    grid [entry .cylsection.e2 -width 12 -textvariable L1] -in .cylsection -row 2 -column 4
    set_balloon .cylsection.e2 "Cylindrical section height"

    focus .cylsection.e1

    pack [frame .under -relief sunken -bd 1] -padx 20 -fill x

    grid [label .under.lt -width 18 -text "Underflow:"] -in .under -row 1 -column 1 -columnspan 2
    grid [label .under.l1 -text "D_U"] -in .under -row 1 -column 3
    grid [entry .under.e1 -width 12 -textvariable DIAMU] -in .under -row 1 -column 4
    set_balloon .under.e1 "Underflow diameter\n\
(must be lower than D)"

    pack [frame .conicsect -relief sunken -bd 1] -padx 20 -fill x

    grid [label .conicsect.lt -text "Conical section"] -in .conicsect -row 1 -column 1 -columnspan 5

    grid [label .conicsect.lt1 -text "No."] -in .conicsect -row 2 -column 1
    grid [label .conicsect.lt2 -text "Angle"] -in .conicsect -row 2 -column 2
    grid [label .conicsect.lt3 -text "Height"] -in .conicsect -row 2 -column 3
    grid [label .conicsect.lt4 -text "Value"] -in .conicsect -row 2 -column 4
    grid [label .conicsect.lt5 -text "Diameter"] -in .conicsect -row 2 -column 5

    grid [radiobutton .conicsect.rb21 -width 2 -variable A_H1 -value "1" ] \
-in .conicsect -row 3 -column 2
    grid [radiobutton .conicsect.rb22 -width 2 -variable A_H1 -value "0" ] \
-in .conicsect -row 3 -column 3
    if {$A_H1 == "" || $A_H1 == 1} {.conicsect.rb21 select} else {.conicsect.rb22 select}

    grid [radiobutton .conicsect.rb31 -width 2 -variable A_H2 -value "1" ] \
-in .conicsect -row 4 -column 2
    grid [radiobutton .conicsect.rb32 -width 2 -variable A_H2 -value "0" ] \
-in .conicsect -row 4 -column 3
    if {$A_H2 == "" || $A_H2 == 1} {.conicsect.rb31 select} else {.conicsect.rb32 select}

    grid [radiobutton .conicsect.rb41 -width 2 -variable A_H3 -value "1" ] \
-in .conicsect -row 5 -column 2
    grid [radiobutton .conicsect.rb42 -width 2 -variable A_H3 -value "0" ] \
-in .conicsect -row 5 -column 3
    if {$A_H3 == "" || $A_H3 == 1} {.conicsect.rb41 select} else {.conicsect.rb42 select}

    grid [radiobutton .conicsect.rb51 -width 2 -variable A_H4 -value "1" ] \
-in .conicsect -row 6 -column 2
    grid [radiobutton .conicsect.rb52 -width 2 -variable A_H4 -value "0" ] \
-in .conicsect -row 6 -column 3
    if {$A_H4 == "" || $A_H4 == 1} {.conicsect.rb51 select} else {.conicsect.rb52 select}

    grid [entry .conicsect.e1 -width 8 -textvariable VALUE1] \
-in .conicsect -row 3 -column 4
    set_balloon .conicsect.e1 "Value of angle (degree) or height\n\
 in this part at the conical section"
    grid [entry .conicsect.e2 -width 8 -textvariable VALUE2] \
-in .conicsect -row 4 -column 4
    set_balloon .conicsect.e2 "Value of angle (degree) or height\n\
 in this part at the conical section"
    grid [entry .conicsect.e3 -width 8 -textvariable VALUE3] \
-in .conicsect -row 5 -column 4
    set_balloon .conicsect.e3 "Value of angle (degree) or height\n\
 in this part at the conical section"
    grid [entry .conicsect.e4 -width 8 -textvariable VALUE4] \
-in .conicsect -row 6 -column 4
    set_balloon .conicsect.e4 "Value of angle (degree) or height\n\
 in this part at the conical section"

    grid [entry .conicsect.ed1 -width 8 -textvariable DIAM1] \
-in .conicsect -row 3 -column 5
    set_balloon .conicsect.ed1 "Value of the diameter at\n\ the end of this part"
    grid [entry .conicsect.ed2 -width 8 -textvariable DIAM2] \
-in .conicsect -row 4 -column 5
    set_balloon .conicsect.ed2 "Value of the diameter at\n\ the end of this part"
    grid [entry .conicsect.ed3 -width 8 -textvariable DIAM3] \
-in .conicsect -row 5 -column 5
    set_balloon .conicsect.ed3 "Value of the diameter at\n\ the end of this part"
    grid [entry .conicsect.ed4 -width 8 -textvariable DIAM4] \
-in .conicsect -row 6 -column 5
    set_balloon .conicsect.ed4 "Value of the diameter at\n\ the end of this part"

    grid [radiobutton .conicsect.rb1 -width 2 -text "1" -variable NCS -value "1" \
-command {.conicsect.e1 configure -state normal;.conicsect.ed1 configure -state normal
.conicsect.e2 configure -state disabled;.conicsect.ed2 configure -state disabled
.conicsect.e3 configure -state disabled;.conicsect.ed3 configure -state disabled
.conicsect.e4 configure -state disabled;.conicsect.ed4 configure -state disabled} \
] -in .conicsect -row 3 -column 1
    grid [radiobutton .conicsect.rb2 -width 2 -text "2" -variable NCS -value "2" \
-command {.conicsect.e1 configure -state normal;.conicsect.ed1 configure -state normal
.conicsect.e2 configure -state normal;.conicsect.ed2 configure -state normal
.conicsect.e3 configure -state disabled;.conicsect.ed3 configure -state disabled
.conicsect.e4 configure -state disabled;.conicsect.ed4 configure -state disabled} \
] -in .conicsect -row 4 -column 1
    grid [radiobutton .conicsect.rb3 -width 2 -text "3" -variable NCS -value "3" \
-command {.conicsect.e1 configure -state normal;.conicsect.ed1 configure -state normal
.conicsect.e2 configure -state normal;.conicsect.ed2 configure -state normal
.conicsect.e3 configure -state normal;.conicsect.ed3 configure -state normal
.conicsect.e4 configure -state disabled;.conicsect.ed4 configure -state disabled} \
] -in .conicsect -row 5 -column 1
    grid [radiobutton .conicsect.rb4 -width 2 -text "4" -variable NCS -value "4" \
-command {.conicsect.e1 configure -state normal;.conicsect.ed1 configure -state normal
.conicsect.e2 configure -state normal;.conicsect.ed2 configure -state normal
.conicsect.e3 configure -state normal;.conicsect.ed3 configure -state normal
.conicsect.e4 configure -state normal;.conicsect.ed4 configure -state normal} \
] -in .conicsect -row 6 -column 1
    if {$NCS == "" || $NCS == 1} {.conicsect.rb1 select
.conicsect.e1 configure -state normal;.conicsect.ed1 configure -state normal
.conicsect.e2 configure -state disabled;.conicsect.ed2 configure -state disabled
.conicsect.e3 configure -state disabled;.conicsect.ed3 configure -state disabled
.conicsect.e4 configure -state disabled;.conicsect.ed4 configure -state disabled} elseif {
$NCS == 2} {.conicsect.rb2 select
.conicsect.e1 configure -state normal;.conicsect.ed1 configure -state normal
.conicsect.e2 configure -state normal;.conicsect.ed2 configure -state normal
.conicsect.e3 configure -state disabled;.conicsect.ed3 configure -state disabled
.conicsect.e4 configure -state disabled;.conicsect.ed4 configure -state disabled} elseif {
$NCS == 3} {.conicsect.rb3 select
.conicsect.e1 configure -state normal;.conicsect.ed1 configure -state normal
.conicsect.e2 configure -state normal;.conicsect.ed2 configure -state normal
.conicsect.e3 configure -state normal;.conicsect.ed3 configure -state normal
.conicsect.e4 configure -state disabled;.conicsect.ed4 configure -state disabled} else {
.conicsect.rb4 select
.conicsect.e1 configure -state normal;.conicsect.ed1 configure -state normal
.conicsect.e2 configure -state normal;.conicsect.ed2 configure -state normal
.conicsect.e3 configure -state normal;.conicsect.ed3 configure -state normal
.conicsect.e4 configure -state normal;.conicsect.ed4 configure -state normal}

    pack [frame .overflow -relief sunken -bd 1] -padx 20

    grid [label .overflow.lt -text "Overflow pipe(s) dimension"] \
-in .overflow -row 1 -column 1 -columnspan 4
    grid [label .overflow.l2 -text "D_O "] -in .overflow -row 2 -column 1
    grid [entry .overflow.e2 -width 12 -textvariable DIAMO] -in .overflow -row 2 -column 2
    set_balloon .overflow.e2 "Overflow pipe diameter\n\
    (must be lower than D_C)"

    grid [label .overflow.li2 -text "D_Oc"] -in .overflow -row 3 -column 1
    grid [entry .overflow.ei2 -width 12 -textvariable DIAMOc] -in .overflow -row 3 -column 2
    set_balloon .overflow.ei2 "Concentric overflow pipe diameter\n\
(must be lower than D_O)"

    grid [label .overflow.l4 -text "V_F "] -in .overflow -row 2 -column 3
    grid [entry .overflow.e4 -width 12 -textvariable VF] -in .overflow -row 2 -column 4
    set_balloon .overflow.e4 "Vortex finder height"

    grid [label .overflow.li4 -text "V_F2"] -in .overflow -row 3 -column 3
    grid [entry .overflow.ei4 -width 12 -textvariable VF2] -in .overflow -row 3 -column 4
    set_balloon .overflow.ei4 "Vortex finder height of the concentric pipe"

    pack [frame .underflow -relief sunken -bd 1] -padx 20

    grid [label .underflow.lt -text "Concentric underflow pipe dimension"] \
-in .underflow -row 1 -column 1 -columnspan 4
    grid [label .underflow.l1 -text "D_Uc"] -in .underflow -row 2 -column 1
    grid [entry .underflow.e1 -width 12 -textvariable DIAMUc] -in .underflow -row 2 -column 2
    set_balloon .underflow.e1 "Underflow concentric pipe diameter\n\
    (must be lower than D_U)"

    grid [label .underflow.l2 -text "V_FU"] -in .underflow -row 2 -column 3
    grid [entry .underflow.e2 -width 12 -textvariable VFU] -in .underflow -row 2 -column 4
    set_balloon .underflow.e2 "Underflow vortex finder height"

    pack [frame .wall -relief sunken -bd 1] -padx 20

    grid [label .wall.lt -text "Wall thickness"] -in .wall -row 1 -column 1 -columnspan 4
    grid [label .wall.l1 -text "W_VF"] -in .wall -row 2 -column 1
    grid [entry .wall.e1 -width 10 -textvariable WVF] -in .wall -row 2 -column 2
    set_balloon .wall.e1 "Thickness of the Vortex Finder wall"

    grid [label .wall.l2 -text "W_Oc"] -in .wall -row 2 -column 3
    grid [entry .wall.e2 -width 10 -textvariable WVFOc]  -in .wall -row 2 -column 4
    set_balloon .wall.e2 "Thickness of the concentric overflow pipe"

    grid [label .wall.l3 -text "WVFU"] -in .wall -row 3 -column 1
    grid [entry .wall.e3 -width 10 -textvariable WVFU]  -in .wall -row 3 -column 2
    set_balloon .wall.e3 "Thickness of the concentric underflow pipe"

    pack [frame .ropbuttons -relief sunken -bd 1] -padx 20 -fill x

    grid [label .ropbuttons.lrb -text "Concentric overflow pipe?"] -in \
.ropbuttons -row 1 -column 1 -columnspan 2
    grid [radiobutton .ropbuttons.rb1 -width 14 -text "no" -variable NO -value "1" \
-command {.overflow.ei2 configure -state disabled
.wall.e2 configure -state disabled; .overflow.ei4 configure -state disabled}] \
-in .ropbuttons -row 2 -column 1
    grid [radiobutton .ropbuttons.rb2 -width 14 -text "yes" -variable NO -value "2" \
-command {.overflow.ei2 configure -state normal; .wall.e2 configure -state normal
.overflow.ei4 configure -state normal}] -in .ropbuttons -row 2 -column 2
    if {$NO == "" || $NO == 1} {.ropbuttons.rb1 select; .wall.e2 configure -state disabled
    .overflow.ei2 configure -state disabled; .overflow.ei4 configure -state disabled} else {
    .wall.e2 configure -state normal; .overflow.ei2 configure -state normal 
    .overflow.ei4 configure -state normal}

    pack [frame .rupbuttons -relief sunken -bd 1] -padx 20 -fill x

    grid [label .rupbuttons.lrb -text "Concentric underflow pipe?"] -in \
.rupbuttons -row 1 -column 1 -columnspan 2
    grid [radiobutton .rupbuttons.rb1 -width 14 -text "no" -variable NU -value "1" \
-command {.underflow.e1 configure -state disabled
.wall.e3 configure -state disabled; .underflow.e2 configure -state disabled}] \
-in .rupbuttons -row 2 -column 1
    grid [radiobutton .rupbuttons.rb2 -width 14 -text "yes" -variable NU -value "2" \
-command {.underflow.e1 configure -state normal; .wall.e3 configure -state normal
.underflow.e2 configure -state normal}] -in .rupbuttons -row 2 -column 2
    if {$NU == "" || $NU == 1} {.rupbuttons.rb1 select; .wall.e3 configure -state disabled
    .underflow.e1 configure -state disabled; .underflow.e2 configure -state disabled} else {
    .wall.e3 configure -state normal; .underflow.e1 configure -state normal 
    .underflow.e2 configure -state normal}

    pack [frame .rbuttons -relief sunken -bd 1] -padx 20 -fill x

    grid [label .rbuttons.lrb -text "Number of inlet pipe(s)?"] -in .rbuttons \
-row 1 -column 1 -columnspan 3
    grid [radiobutton .rbuttons.rb1 -width 7 -text "1" -variable NI -value "1"] \
-in .rbuttons -row 2 -column 1
    grid [radiobutton .rbuttons.rb2 -width 7 -text "2" -variable NI -value "2"] \
-in .rbuttons -row 2 -column 2
    grid [radiobutton .rbuttons.rb4 -width 7 -text "4" -variable NI -value "4"] \
-in .rbuttons -row 2 -column 3
    if {$NI == ""} {.rbuttons.rb1 select}

    pack [frame .length -relief sunken -bd 1] -padx 20

    grid [label .length.lt -text "Length of the pipes"] \
-in .length -row 1 -column 1 -columnspan 4
    grid [label .length.l1 -text "L_I"] -in .length -row 2 -column 1
    grid [entry .length.e1 -width 11 -textvariable IP] -in .length -row 2 -column 2
    set_balloon .length.e1 "Lenght of the inlet pipe(s)"

    grid [label .length.l2 -text "L_O"] -in .length -row 2 -column 3
    grid [entry .length.e2 -width 11 -textvariable OP] -in .length -row 2 -column 4
    set_balloon .length.e2 "Lenght of the overflow pipe(s) \n\
(outside the hydrocyclone)"

    grid [label .length.l3 -text "L_U"] -in .length -row 3 -column 1
    grid [entry .length.e3 -width 11 -textvariable UP] -in .length -row 3 -column 2
    set_balloon .length.e3 "Lenght of the underflow pipe(s)"

    pack [frame .inlet -relief sunken -bd 1] -padx 20

    grid  [label .inlet.lt -text "Inlet pipe(s) dimension"] \
-in .inlet -row 1 -column 1 -columnspan 4
    grid [label .inlet.l1 -text "D_I"] -in .inlet -row 2 -column 1
    grid [entry .inlet.e1 -width 11 -textvariable DIAMI] -in .inlet -row 2 -column 2
    set_balloon .inlet.e1 "Inlet pipe diameter"

    grid [label .inlet.l4 -text "H_I"] -in .inlet -row 2 -column 3
    grid [entry .inlet.e4 -width 11 -textvariable HI] -in .inlet -row 2 -column 4
    set_balloon .inlet.e4 "height between inlet pipe\n\
 and cylindrical section top wall"

    grid [label .inlet.l2 -text "A_I"] -in .inlet -row 3 -column 1
    grid [entry .inlet.e2 -width 11 -textvariable BC] -in .inlet -row 3 -column 2
    set_balloon .inlet.e2 "Rectangle inlet pipe width"

    grid [label .inlet.l3 -text "B_I"] -in .inlet -row 3 -column 3
    grid [entry .inlet.e3 -width 11 -textvariable HC] -in .inlet -row 3 -column 4
    set_balloon .inlet.e3 "Rectangle inlet pipe height"

    pack [frame .rotaxis -relief sunken -bd 1] -padx 20

    pack [label .rotaxis.l1 -text "Rotation of the axis"] -fill x -expand true

    pack [frame .rotations -relief sunken -bd 1] -padx 20

    grid [label .rotations.l1 -text "X"] -in .rotations -row 1 -column 1
    grid [label .rotations.lb1 -width 8 -textvariable AYZ -state disabled] \
 -in .rotations -row 1 -column 2
    set_balloon .rotations.lb1 "Database quilts rotation angle on X axis (degree)"

    grid [label .rotations.l2 -text "Y"] -in .rotations -row 1 -column 3
    grid [label .rotations.lb2 -width 8 -textvariable AXZ -state disabled] \
 -in .rotations -row 1 -column 4
    set_balloon .rotations.lb2 "Database quilts rotation angle on Y axis (degree)"

    grid [label .rotations.l3 -text "Z"] -in .rotations -row 1 -column 5
    grid [label .rotations.lb3 -width 8 -textvariable AXY -state disabled] \
 -in .rotations -row 1 -column 6
    set_balloon .rotations.lb3 "Database quilts rotation angle on Z axis (degree)"

    pack [frame .ohgridi -relief sunken -bd 1] -padx 20 -fill x

    grid [label .ohgridi.lrb -text "O-H grid mesh in inlet pipe(s)" ] -in .ohgridi \
-row 1 -column 1 -columnspan 2
    grid [radiobutton .ohgridi.rb1 -width 8 -text "square" -variable TYPE -value "S"] \
-in .ohgridi -row 2 -column 1 
    grid [radiobutton .ohgridi.rb2 -width 8 -text "r-square" -variable TYPE -value "R"] \
-in .ohgridi -row 2 -column 2 
    grid [radiobutton .ohgridi.rb3 -width 8 -text "circle" -variable TYPE -value "C"] \
-in .ohgridi -row 3 -column 1 
    grid [radiobutton .ohgridi.rb4 -width 8 -text "octagonal" -variable TYPE -value "O"] \
-in .ohgridi -row 3 -column 2
    if {$TYPE == ""} {.ohgridi.rb1 select}

    pack [frame .maxangle -relief sunken -bd 1] -padx 20

    grid [label .maxangle.l1 -text "Max angle"] -in .maxangle -row 1 -column 1
    grid [entry .maxangle.e1 -width 10 -textvariable MAXANGLE] -in .maxangle -row 1 -column 2
    set_balloon .maxangle.e1 "Maximum angle in O-H grid mesh type (degree)"
    grid [checkbutton .maxangle.lt -text "Aux lines" -variable AUX] -in .maxangle -row 1 -column 3
    set_balloon .maxangle.lt "Auxiliar lines in rectangular inlet pipes"

    pack [frame .ripbuttons -relief sunken -bd 1] -padx 20 -fill x

    grid [label .ripbuttons.lrb -text "Type of inlet pipe(s)?"] -in .ripbuttons \
-row 1 -column 1 -columnspan 2
    grid [radiobutton .ripbuttons.rb1 -width 12 -text "rectangle" -variable SQUARE \
-value "1" -command {.inlet.e1 configure -state disabled; .maxangle.e1 configure -state disabled
.inlet.e2 configure -state normal; .inlet.e3 configure -state normal
.ohgridi.rb1 configure -state disabled; .ohgridi.rb2 configure -state disabled
.ohgridi.rb3 configure -state disabled; .ohgridi.rb4 configure -state disabled
.maxangle.lt configure -state normal}] -in .ripbuttons -row 2 -column 1
    grid [radiobutton .ripbuttons.rb2 -width 12 -text "cylinder" -variable SQUARE \
-value "2" -command {.inlet.e1 configure -state normal; .maxangle.e1 configure -state normal
.inlet.e2 configure -state disabled; .inlet.e3 configure -state disabled
.ohgridi.rb1 configure -state normal; .ohgridi.rb2 configure -state normal
.ohgridi.rb3 configure -state normal; .ohgridi.rb4 configure -state normal
.maxangle.lt configure -state disabled; set AUX 0}] -in .ripbuttons -row 2 -column 2
    if {$SQUARE == "" || $SQUARE == 1} {.ripbuttons.rb1 select
        .inlet.e1 configure -state disabled; .inlet.e2 configure -state normal
        .inlet.e3 configure -state normal;  .maxangle.e1 configure -state disabled
        .ohgridi.rb1 configure -state disabled; .ohgridi.rb2 configure -state disabled
        .ohgridi.rb3 configure -state disabled; .ohgridi.rb4 configure -state disabled; 
        .maxangle.lt configure -state normal} else {
        .inlet.e1 configure -state normal; .maxangle.e1 configure -state normal
        .inlet.e2 configure -state disabled; .inlet.e3 configure -state disabled
        .maxangle.lt configure -state disabled; set AUX 0}

    pack [frame .ohgrido -relief sunken -bd 1] -padx 20 -fill x

    grid [label .ohgrido.lrb -text "O-H grid mesh in overflow pipe(s)"] -in .ohgrido \
-row 1 -column 1 -columnspan 2
    grid [radiobutton .ohgrido.rb1 -width 8 -text "square" -variable TYPE2 -value "S"] \
-in .ohgrido -row 2 -column 1 
    grid [radiobutton .ohgrido.rb2 -width 8 -text "r-square" -variable TYPE2 -value "R"] \
-in .ohgrido -row 2 -column 2 
    grid [radiobutton .ohgrido.rb3 -width 8 -text "circle" -variable TYPE2 -value "C"] \
-in .ohgrido -row 3 -column 1 
    grid [radiobutton .ohgrido.rb4 -width 8 -text "octagonal" -variable TYPE2 -value "O"] \
-in .ohgrido -row 3 -column 2
    if {$TYPE2 == ""} {.ohgrido.rb1 select}

    pack [frame .opratio -relief sunken -bd 1] -padx 20

    pack [label .opratio.l1 -text "Ratio of O-H grid"] -side left
    pack [entry .opratio.e1 -width 10 -textvariable RVALUE] \
-side left -fill x -expand true
    set_balloon .opratio.e1 "Ratio of O-H grid inner domain"

    pack [frame .move -relief sunken -bd 1] -padx 20

    pack [label .move.l1 -text "Move inlet pipe(s)"] -side left
    pack [entry .move.e1 -width 10 -textvariable MOVE] \
-side left -fill x -expand true
    set_balloon .move.e1 "Move inlet pipe(s) tangent to center"

    pack [frame .reexecution -relief sunken -bd 1] -padx 20 -fill x

    grid [label .reexecution.lrb -text "Send all databases to layer 1?"] -in .reexecution \
-row 1 -column 1 -columnspan 2
    grid [radiobutton .reexecution.rb1 -width 8 -text "YES" -variable REEXECUTE -value 1] \
-in .reexecution -row 1 -column 3 
    grid [radiobutton .reexecution.rb2 -width 8 -text "NO" -variable REEXECUTE -value 0] \
-in .reexecution -row 1 -column 4 
    if {$REEXECUTE == ""} {.reexecution.rb2 select}

    pack [frame .buttons -relief sunken -bd 1] -padx 20 -fill x

    pack [button .buttons.b1 -activebackground green -text EXECUTE -command {
    set err 0
    if {[regexp {^[+]?\d*[\.,]?\d*$} $DIAMO] && $DIAMO != ""} {set DIAMO $DIAMO} \
else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $DIAMC] && $DIAMC != ""} {set DIAMC $DIAMC} \
else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $L1] && $L1 != ""} {set L1 $L1} else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $VF] && $VF != ""} {set VF $VF} else {set err 9}
    if {[regexp {^[+]?[-]?\d*[\.,]?\d*$} $VFU] && $VFU != ""} {set VFU $VFU} else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $DIAM1] && $DIAM1 != ""} {set DIAM1 $DIAM1} \
else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $VALUE1] && $VALUE1 != ""} {set VALUE1 $VALUE1} \
else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $DIAMU] && $DIAMU != ""} {set DIAMU $DIAMU} \
else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $HI] && $HI != ""} {set HI $HI} else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $NI] && $NI != ""} {set NI $NI} else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $NCS] && $NCS != ""} {set NCS $NCS} else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $NO] && $NO != ""} {set NO $NO} else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $NU] && $NU != ""} {set NU $NU} else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $IP] && $IP != ""} {set IP $IP} else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $OP] && $OP != ""} {set OP $OP} else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $WVF] && $WVF != ""} {set WVF $WVF} else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $WVFU] && $WVFU != ""} {set WVFU $WVFU} else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $WVFOc] && $WVFOc != ""} {set WVFOc $WVFOc} else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $MAXANGLE] && $MAXANGLE != ""} {set MAXANGLE $MAXANGLE} \
else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $RVALUE] && $RVALUE != ""} {set RVALUE $RVALUE} \
else {set RVALUE "0.5"}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $MOVE] && $MOVE != ""} {set MOVE $MOVE} \
else {set err 9}
    if {[regexp {^[+]?\d*[\.,]?\d*$} $REEXECUTE] && $REEXECUTE != ""} {set REEXECUTE $REEXECUTE} \
else {set REEXECUTE 0}
    if {$NO == 2} {
        if {[regexp {^[+]?\d*[\.,]?\d*$} $DIAMOc] && $DIAMOc != ""} {set DIAMOc $DIAMOc} \
else {set err 9}
        if {[regexp {^[+]?\d*[\.,]?\d*$} $VF2] && $VF2 != ""} {set VF2 $VF2} else {set err 9}}
    if {$NU == 2} {
        if {[regexp {^[+]?\d*[\.,]?\d*$} $DIAMUc] && $DIAMUc != ""} {set DIAMUc $DIAMUc} \
else {set err 9}}
    if {$SQUARE == 2} {
        if {[regexp {^[+]?\d*[\.,]?\d*$} $DIAMI] && $DIAMI != ""} {set DIAMI $DIAMI
set hi [expr {sqrt($DIAMI*($DIAMC-$DIAMI))}]} else {set err 9}
        if {[regexp {^\d*[\.,]?\d*$} $DIAMOc] && $DIAMOc != ""} \
{set DIAMOc $DIAMOc} else {set err 9}} else {
        if {[regexp {^[+]?\d*[\.,]?\d*$} $HC] && $HC != ""} {set HC $HC} else {set err 9}
        if {[regexp {^[+]?\d*[\.,]?\d*$} $BC] && $BC != ""} {set BC $BC
set hi [expr {sqrt($BC*($DIAMC-$BC))}]} else {set err 9}}
    if {$err == 9} {tk_messageBox -message "Invalid format number" \
-type ok -icon warning -title "Error message"} elseif {
        ($NO == 2) && ($WVFOc >= [expr {($DIAMO-$DIAMOc)/2.}])} {tk_messageBox -message \
"W_Oc greater or equal than (D_O - D_Oc)/2" -type ok -icon error -title "Error message"} elseif {
        $WVF >= [expr {($DIAMC-$DIAMO)/2.}]} {tk_messageBox -message \
"W_VF greater or equal than D_C" -type ok -icon error -title "Error message"} elseif {
        $VFU <= [expr {-$UP}]} {tk_messageBox -message \
"Underflow Vortex Finder was positioned below underflow pipe exit" -type ok -icon error -title "Error message"} elseif {
        $DIAMO >= $DIAMC} {tk_messageBox -message "D_O greater or equal than D_C" \
-type ok -icon error -title "Error message"} elseif {
        $DIAMOc >= $DIAMO} {tk_messageBox -message "D_Oc greater or equal than D_O" \
-type ok -icon error -title "Error message"} elseif {
        ($NU == 2) && ($DIAMUc >= $DIAMU)} {tk_messageBox -message "D_Uc greater or equal than D_U" \
-type ok -icon error -title "Error message"} elseif {
        $DIAMOc <= 0 && $NO == 2} {tk_messageBox -message "D_Oc has an invalid value number" \
-type ok -icon error -title "Error message"} elseif {
        $DIAMUc <= 0 && $NU == 2} {tk_messageBox -message "D_Uc has an invalid value number" \
-type ok -icon error -title "Error message"} elseif {
        $DIAM1 >= $DIAMC} {tk_messageBox -message " D  greater or equal than D_C" \
-type ok -icon error -title "Error message"} elseif {
        $DIAMU >= $DIAMC} {tk_messageBox -message "D_U greater or equal than D_C " \
-type ok -icon error -title "Error message"} elseif {       
        $DIAMI >= $L1} {tk_messageBox -message "D_I greater or equal than L1" \
-type ok -icon error -title "Error message"} elseif {       
        $DIAMI >= [expr {$DIAMC/2.}]} {tk_messageBox -message "D_I greater or equal than half D_C" \
-type ok -icon error -title "Error message"} elseif {
        $HC >= $L1} {tk_messageBox -message "H_C greater or equal than L1" \
-type ok -icon error -title "Error message"} elseif {
        $BC >= [expr {$DIAMC/2.}]} {tk_messageBox -message "B_C greater or equal than half D_C" \
-type ok -icon error -title "Error message"} elseif {
        $NCS == 1 && $DIAM1 != $DIAMU} {tk_messageBox -message "The last conical section diameter\n\
 must be equal than D_U" -type ok -icon error -title "Error message"} elseif {
        $NCS == 2 && $DIAM2 != $DIAMU} {tk_messageBox -message "The last conical section diameter\n\
 must be equal than D_U" -type ok -icon error -title "Error message"} elseif {
        $NCS == 3 && $DIAM3 != $DIAMU} {tk_messageBox -message "The last conical section diameter\n\
 must be equal than D_U" -type ok -icon error -title "Error message"} elseif {
        $NCS == 4 && $DIAM4 != $DIAMU} {tk_messageBox -message "The last conical section diameter\n\
 must be equal than D_U" -type ok -icon error -title "Error message"} elseif {
        $IP <= $hi } {tk_messageBox -message " L_I must be greater or equal than $hi" \
-type ok -icon error -title "Error message"} else {runScript
tk_messageBox -message "Finished" -type ok}
}] -fill x

    pack [frame .buttons2 -relief sunken -bd 1] -padx 40 -fill x

    pack [button .buttons2.b2 -activebackground red -text QUIT -command {exit}] -fill x

    grid config .logo -column 0 -row 0 -columnspan 3 -rowspan 1 -sticky "snew"

    grid config .cylsection -column 0 -row 1 -columnspan 1 -rowspan 2 -sticky "snew"
    grid config .under -column 0 -row 3 -columnspan 1 -rowspan 1 -sticky "snew"
    grid config .conicsect -column 0 -row 4 -columnspan 1 -rowspan 6 -sticky "snew"
    grid config .ropbuttons -column 0 -row 9 -columnspan 1 -rowspan 2 -sticky "snew"
    grid config .overflow -column 0 -row 11 -columnspan 1 -rowspan 3 -sticky "snew"
    grid config .ohgrido -column 0 -row 14 -columnspan 1 -rowspan 3 -sticky "snew"
    grid config .opratio -column 0 -row 17 -columnspan 1 -rowspan 1 -sticky "snew"
    grid config .rupbuttons -column 0 -row 18 -columnspan 1 -rowspan 2 -sticky "snew"
    grid config .reexecution -column 0 -row 20 -columnspan 4 -rowspan 1 -sticky "snew"
    grid config .buttons -column 0 -row 21 -columnspan 3 -rowspan 1 -sticky "snew"
    grid config .rotaxis -column 0 -row 22 -columnspan 1 -rowspan 1 -sticky "snew"

    grid config .length -column 1 -row 1 -columnspan 1 -rowspan 3 -sticky "snew"
    grid config .wall -column 1 -row 4 -columnspan 1 -rowspan 2 -sticky "snew"
    grid config .rbuttons -column 1 -row 6 -columnspan 1 -rowspan 2 -sticky "snew"
    grid config .ripbuttons -column 1 -row 8 -columnspan 1 -rowspan 2 -sticky "snew"
    grid config .inlet -column 1 -row 10 -columnspan 1 -rowspan 3 -sticky "snew"
    grid config .ohgridi -column 1 -row 13 -columnspan 1 -rowspan 3 -sticky "snew"
    grid config .move -column 1 -row 16 -columnspan 1 -rowspan 1 -sticky "snew"
    grid config .maxangle -column 1 -row 17 -columnspan 1 -rowspan 1 -sticky "snew"
    grid config .underflow -column 1 -row 18 -columnspan 1 -rowspan 2 -sticky "snew"
    grid config .buttons2 -column 1 -row 21 -columnspan 1 -rowspan 1 -sticky "e"
    grid config .rotations -column 1 -row 22 -columnspan 1 -rowspan 1 -sticky "snew"

}

################# Execute script ####################
tk_GUI
tkwait window .
