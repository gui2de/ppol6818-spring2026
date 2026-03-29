/*==========================================================

	Author: Kenshi Kawade
	Title: stata3 assignement 
	Part: Master

============================================================*/

if c(username) == "kkawade" {
    global boxd "/Users/kkawade/Library/CloudStorage/Box-Box/ppol6818"
}

// Replace username and BOXFILE path below 
if c(username) == "username" { 
    global boxd  "C:/Users/username/Documents/username"  
}

* local directory
if c(username) == "kkawade" {
    global wd "/Users/kkawade/gu_class/ppol6818ex/week_8/01_script"
}

// Replace username and LOCAL path below
if c(username) == "username" { 
    global wd  "C:/Users/username/Documents/username"  
}

cd "$boxd"

do "$wd/ppol6818_stata3_q1.do" 

do "$wd/ppol6818_stata3_q2.do"

do "$wd/ppol6818_stata3_q3.do"

do "$wd/ppol6818_stata3_q4.do"

