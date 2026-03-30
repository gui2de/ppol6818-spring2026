# Question 2.3


---------------------------------------------------------------------------------
                                                   N                             
                            10             100           1000           10000    
---------------------------------------------------------------------------------
r(base_beta)           2.009 (0.126)  2.004 (0.031)  2.002 (0.009)  2.000 (0.003)
r(confounder_nc_beta) 1.119 (70.217) 2.716 (21.093)  2.102 (7.080)  2.296 (2.078)
r(confounder_c_beta)   2.012 (0.125)  2.005 (0.031)  2.002 (0.009)  2.000 (0.003)
r(mediator_nc_beta)    2.524 (4.073)  1.914 (0.935)  1.995 (0.310)  2.011 (0.089)
r(mediator_c_beta)     2.005 (0.043)  2.000 (0.010)  2.000 (0.003)  2.000 (0.001)
r(collider_c_beta)    -0.499 (0.002) -0.499 (0.000) -0.499 (0.000) -0.499 (0.000)
---------------------------------------------------------------------------------




Original regression (only X is associated with Y):
The baseline is centered around 2 since we coded that as our y
![alt text](image.png)


Confounder not controlled:
Lots of variation since the confounder is impacting both the treatment effect and the outcome. The effect of the confounder decreases as N increases.
![alt text](image-1.png)


Confounder controlled:
Controlling for the confounder gets rid of the confounding effect and the coefficient gets closer to the true model value.
![alt text](image-2.png)


Mediator not controlled:
Lots of variation (less variation than the confounder). The mediator is caused by the treatment effect and thus impacts the outcome. The effect of the mediator decreases as N increases.
![alt text](image-3.png)


Mediator controlled:
Controlling for the mediator gets rid of the confounding effect and the coefficient gets closer to the true model value. (Note that this is not always advisable)
![alt text](image-4.png)


Collider controlled:
Controlling for the collider leads to a false correlation between the outcome and treatment variables.
![alt text](image-5.png)