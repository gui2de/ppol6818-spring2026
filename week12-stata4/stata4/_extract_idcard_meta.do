clear all
set more off
cd "C:\Users\86186\Desktop\Experimental design\stata4"

capture mkdir "_idcard_tmp"

tempfile summary
postfile shandle str128 dataset str260 filepath long nobs int nvars using "`summary'", replace

local flist : dir "C:\Users\86186\Desktop\Experimental design\stata4\part1" files "*.dta"

foreach fn of local flist {
    local f = "C:\Users\86186\Desktop\Experimental design\stata4\part1\\`fn'"
    quietly use "`f'", clear
    local nobs = _N
    ds
    local allvars `r(varlist)'
    local nvars : word count `allvars'

    tempfile vard
    postfile vhandle str128 dataset str260 filepath str128 varname str24 vartype str244 varlabel long nmissing long nunique byte is_unique byte is_idname using "`vard'", replace

    foreach v of varlist _all {
        local typ : type `v'
        local lab : variable label `v'
        quietly count if missing(`v')
        local nmiss = r(N)
        tempvar t
        quietly egen `t' = tag(`v')
        quietly count if `t'
        local nuniq = r(N)
        local uniq = (`nuniq'==`nobs' & `nmiss'==0)
        local isid = regexm(lower("`v'"), "(^id$|_id$|id_|^code$|_code$|^gid$|^uid$|district|region|ward|poll|station|voter|constituency)")

        post vhandle ("`fn'") ("`f'") ("`v'") ("`typ'") (`"`lab'"') (`nmiss') (`nuniq') (`uniq') (`isid')
    }
    postclose vhandle

    use "`vard'", clear
    export delimited using "C:\Users\86186\Desktop\Experimental design\stata4\_idcard_tmp\vars_`fn'.csv", replace

    post shandle ("`fn'") ("`f'") (`nobs') (`nvars')
}

postclose shandle
use "`summary'", clear
export delimited using "C:\Users\86186\Desktop\Experimental design\stata4\_idcard_tmp\summary.csv", replace

exit
