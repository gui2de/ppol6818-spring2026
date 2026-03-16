Definitions:
student.dta:
stdnt_num = index of students
grade = student's year
attendance = days the student attended school this year
primary_teacher = either their teacher if in elementary school (where everyone basically has just one teacher) or a single teacher assigned per student to help guide them if above elementary school (the distinction does not matter for our purposes). This is an integer and it corresponds to the "teacher" index in teacher.dta

teacher.dta:
teacher = an index of all teachers in the district, corresponds to "primary_teacher" in student
subject = The subject a teacher teaches
experience = years of experience the teacher has
school = the school the teacher works at

school.dta:
school
gpa = the mean gpa of the school
level = school level (i.e. "Elementary", "Middle", "High")
loc = Generally where the school is in the district, either "North", "West", or "South"

subject.dta
subject
subj_gpa = the gpa for that subject (i.e. the mean of all students' grades in classes of that subject)
tested = 1 means the subject is tested, 0 means it is not tested.
