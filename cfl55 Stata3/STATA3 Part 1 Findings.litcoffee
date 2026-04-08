##STATA3 Part 1 Findings

After creating a program to regress y on x and simulating that program for four different sample sizes 500 times each, I find that the variation in beta decreases as the sample size increases, that SEM shrinks as sample size increases, and the confidence interval shrinks as sample size increases.


![Table](Part1_table.png)
This table shows the decreasing SEM as sample size (N) increases and the diminishing distance between the low and high ends of the confidence interval as sample size increases.

![Graph](Part1_Boxplot.png)
This boxplot graph shows the shrinking variation in beta as sample size increases from 10 to 10000.

## Part 2 Findings

Like in part 1,  the variation in beta continues to decrease as sample size increases. The overall trends in shrinking SEM and confidence intervals is also the same. 

![Table](Part2_table.png)

![Graph](Part2_Boxplot.png)

I was able to draw a larger sample size in part 2 because I didn't set the observations to 10000. 

![Table](compare_part1&2.png)
The sample size values that overlap between the two simulations are very slightly different. I would attribute this to either not setting the seed in part 2 and/or variations within the 500 simulated results.