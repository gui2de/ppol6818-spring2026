# Part 1: Fuzzy Matching

In this part, I attempted to merge multiple data sets with regions, districts, and wards in Tanzania. As geocraphic identifications change across years, I needed to fuzzy match wards, using ```reclink```. 

## Challenges
There are **3,333** unique wards in 2010 and **3944** unique wards in 2015 in Tanzania. This happened by dividing existing ward into 2 (or in some cases three or more) new wards. There are also 21 regions and 131 districts in 2010 and 25 regions and 178 districts in 2015, which means that wards can be divided or moved to newly created region or district. **This ward change pauses a big challenge to identify which wards in 2010 became which wards in 2015 in which regions and district**. 

To identify that, I used three files: ```Tz_elec_10.dta```, ```Tz_elec_15.dta```, and ```Tz_GIS_2015_2010_intersection.dta```. ```Tz_elec_10.dta``` and ```Tz_elec_15.dta``` have different number of unique geographic identifications. ```Tz_GIS_2015_2010_intersection.dta``` is obtained from shapefiles from 2012 and 2017 and created by using ArcGIS to see the percentage area of 2015 ward that overlaps a 2010 ward. But again, the wards in this file does not perfectly match with either 2010 wards or 2015 wards. 

<br>

**Geographic identification breakdown for each year**
| Category | 2010 | 2015 | 2012 | 2017 |
| :---- | :----: | :----: | :----: | ----: |
| Regions | 21 | 25 | - | - |
| District | 131 | 178 | - | - |
| Ward | 3333 | 3944 | 3276 | 3834 | 


## Questions

1. How many are “parentless” wards? (i.e. exist in 2015 but not in 2010)
2. How many are “childless” wards? (i.e. exist in 2010 but not in 2015)
3. How many wards were divided into two wards between 2010 and 2015?
4. How many wards were divided into three or more wards between 2010 and 2015?
5. List regions along with the rate of ward division

## Steps to take 
### 1. Merge ```Tz_elec_10.dta``` and ```Tz_elec_15.dta```
By merging those two files for 2010 and 2015, I can identify which wards in 2010 still exist in 2015 and which wards only exist in either year (**Question 1 and 2**). 


As a result,  I found that;
- 2379 wards are the same name in both 10 and 15,
- 1565 wards are newly created in 2015 (new wards),
- 954 wards existed in 2010 but no longer in 2015 (removed wards).

### 2. Fuzzy match 1565 new wards to 3834 gis wards
To compare the wards in 2010 and 2015 using shapefile wards, I need to first match wards between 2015 and 2017. Since the number of wards are differetn even between 2015 and 2017, I used ```reclink``` to see how well the wards in 2015 match with the wards in 2017 and decide how many wards I can surely say the wards in 2017 are the ones in 2015. Using 0.7 for matched enough threshold fuzzy score, I obtained 1344 out of 1565 wards that I can say are 2015 wards in 2017 wards. So I dropped 221 wards in 2015 as unidentifiable wards. 

### 3. Fuzzy match 954 removed wards to 1344 fuzzy matched wards 
Afte the first fuzzy match, I did the same process but with the 954 removed wards and 1344 fuzzy-matched-with_2015 wards in gis data. Using the same fuzzy score, 0.7, as matched enough threshold, I got 703 out 954 removed wards that I can say are 2010 wards in 2012 wards. I dropped 251 wards in 2010 as unidentifiable wards. 


So now I have 1344 wards in 2015 and 703 wards in 2010 that I can see the identifical reformation between 2010 and 2015 by using gis data. 

### 4. Calculate the division (**Question 4 and 5**) 
Using gis 2012 and 2017 data, I found that;
- 34 out 704 wards in 2010 were divided into 2 wards in 2015
- 5 out of 704 wards in 2010 were divided into 3 or more wards in 2015

\* These numbers are after ignoring unidentifiable wards in 2010 and 2015.

### 5. Calculate the rate of division
The regions that have divided wards are below with division rate. 

| Uregion_10  | divisi~e |
| :---  | :---: |
| mtwara |  .3478261 |
| arusha |  .3333333 |
| tabora |  .3333333 |
| mwanza |  .3333333 |
| kilimanjaro |  .3333333 |
| ruvuma |  .2666667 |
| mbeya |  .25 |
| mara |  .2 |
| morogoro |  .2 |
| tanga | .15 |
| dodoma | .0833333 |
| manyara |  .0588235 |
| shinyanga |  .0285714 |




