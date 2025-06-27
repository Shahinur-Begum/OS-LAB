#!/bin/bash

# Data files
STUDENTS="students.txt"
USERS="users.txt"
COURSES="courses.txt"
ENROLLMENTS="enrollments.txt"
ATTENDANCE="attendance.txt"
GRADES="grades.txt"

# Ensure data files exist
touch $STUDENTS $USERS $COURSES $ENROLLMENTS $ATTENDANCE $GRADES

pause() {
  read -p "Press Enter to continue..."
}

welcome_screen() {
  clear
  echo "==========================================="
  echo "   Welcome to Student Management System"
  echo "==========================================="
  echo
  echo "1) Admin Login"
  echo "2) Student Login"
  echo "3) Exit"
  echo
  read -p "Choose an option: " choice

  case $choice in
    1) login admin ;;
    2) login student ;;
    3) echo "Goodbye!"; exit 0 ;;
    *) echo "Invalid choice!"; sleep 1; welcome_screen ;;
  esac
}

login() {
  local role_expected=$1
  clear
  echo "=== $role_expected Login ==="
  read -p "Username: " username
  username=$(echo "$username" | xargs)

  read -p "Show password while typing? (y/n): " showpass
  if [[ "$showpass" =~ ^[Yy]$ ]]; then
    read -p "Password: " password
  else
    read -s -p "Password: " password
    echo
  fi
  password=$(echo "$password" | xargs)

  if [[ "$role_expected" == "admin" ]]; then
    if [[ "$username" == "admin" && "$password" == "admin123" ]]; then
      admin_menu
    else
      echo "Invalid admin credentials!"
      pause
      welcome_screen
    fi
  else
    user_record=$(grep "^$username:$password$" "$USERS")
    if [[ -z "$user_record" ]]; then
      echo "Invalid student credentials!"
      pause
      welcome_screen
    else
      student_menu "$username"
    fi
  fi
}

admin_menu() {
  clear
  echo "=== Admin Menu ==="
  echo "1) Manage Students"
  echo "2) Manage Courses"
  echo "3) Manage Enrollments"
  echo "4) Mark Attendance"
  echo "5) Enter/Update Grades"
  echo "6) Generate Reports"
  echo "7) Logout"
  read -p "Choose an option: " choice
  case $choice in
    1) manage_students ;;
    2) manage_courses ;;
    3) manage_enrollments ;;
    4) mark_attendance ;;
    5) enter_grades ;;
    6) generate_reports ;;
    7) welcome_screen ;;
    *) echo "Invalid choice!"; pause; admin_menu ;;
  esac
}

manage_students() {
  clear
  echo "=== Manage Students ==="
  echo "1) Add Student"
  echo "2) View Students"
  echo "3) Update Student Profile"
  echo "4) Delete Student"
  echo "5) Back"
  read -p "Choose an option: " choice
  case $choice in
    1)
      read -p "Enter Student ID: " sid
      sid=$(echo "$sid" | xargs)
      read -p "Enter Student Name: " sname
      sname=$(echo "$sname" | xargs)
      read -p "Enter Username: " uname
      uname=$(echo "$uname" | xargs)
      read -p "Enter Password: " pass
      pass=$(echo "$pass" | xargs)
      read -p "Enter Email: " email
      email=$(echo "$email" | xargs)
      read -p "Enter Phone: " phone
      phone=$(echo "$phone" | xargs)
      read -p "Enter Date of Birth (YYYY-MM-DD): " dob
      dob=$(echo "$dob" | xargs)
      read -p "Enter Address: " address
      address=$(echo "$address" | xargs)

      echo "$sid:$sname:$uname:$email:$phone:$dob:$address" >> $STUDENTS
      echo "$uname:$pass" >> $USERS

      echo "Student added successfully."
      pause
      manage_students
      ;;
    2)
      clear
      echo "=== Students List ==="
      printf "%-10s %-20s %-15s %-25s %-13s %-12s %-30s\n" "ID" "Name" "Username" "Email" "Phone" "DOB" "Address"
      echo "------------------------------------------------------------------------------------------------------------------------"
      while IFS=: read -r id name username email phone dob address; do
        printf "%-10s %-20s %-15s %-25s %-13s %-12s %-30s\n" "$id" "$name" "$username" "$email" "$phone" "$dob" "$address"
      done < "$STUDENTS"
      pause
      manage_students
      ;;
    3)
      update_student_profile_admin
      ;;
    4)
      read -p "Enter Student ID to delete: " sid_del
      sid_del=$(echo "$sid_del" | xargs)
      uname_del=$(grep "^$sid_del:" $STUDENTS | cut -d: -f3)

      if [[ -z "$uname_del" ]]; then
        echo "Student ID not found."
        pause
        manage_students
        return
      fi

      # Delete student record
      grep -v "^$sid_del:" $STUDENTS > tmp && mv tmp $STUDENTS
      # Delete user credentials
      grep -v "^$uname_del:" $USERS > tmp && mv tmp $USERS
      # Delete enrollments of student
      grep -v "^$sid_del:" $ENROLLMENTS > tmp && mv tmp $ENROLLMENTS
      # Delete attendance records of student
      grep -v "^$sid_del:" $ATTENDANCE > tmp && mv tmp $ATTENDANCE
      # Delete grades of student
      grep -v "^$sid_del:" $GRADES > tmp && mv tmp $GRADES

      echo "Student and related records deleted."
      pause
      manage_students
      ;;
    5)
      admin_menu
      ;;
    *)
      echo "Invalid choice!"
      pause
      manage_students
      ;;
  esac
}

update_student_profile_admin() {
  clear
  echo "=== Update Student Profile (Admin) ==="
  read -p "Enter Student ID to update: " sid
  sid=$(echo "$sid" | xargs)

  local line=$(grep "^$sid:" "$STUDENTS")
  if [[ -z "$line" ]]; then
    echo "Student ID not found!"
    pause
    manage_students
    return
  fi

  IFS=":" read -r sid name uname email phone dob address <<< "$line"

  echo "Leave blank to keep current value."

  read -p "Name [$name]: " new_name
  read -p "Email [$email]: " new_email
  read -p "Phone [$phone]: " new_phone
  read -p "Date of Birth [$dob]: " new_dob
  read -p "Address [$address]: " new_address

  new_name=${new_name:-$name}
  new_email=${new_email:-$email}
  new_phone=${new_phone:-$phone}
  new_dob=${new_dob:-$dob}
  new_address=${new_address:-$address}

  sed -i "s/^$sid:.*:.*:.*:.*:.*:.*\$/$sid:$new_name:$uname:$new_email:$new_phone:$new_dob:$new_address/" "$STUDENTS"

  echo "Student profile updated successfully."
  pause
  manage_students
}

manage_courses() {
  clear
  echo "=== Manage Courses ==="
  echo "1) Add Course"
  echo "2) View Courses"
  echo "3) Delete Course"
  echo "4) Back"
  read -p "Choose an option: " choice
  case $choice in
    1)
      read -p "Enter Course ID: " cid
      cid=$(echo "$cid" | xargs)
      read -p "Enter Course Name: " cname
      cname=$(echo "$cname" | xargs)
      echo "$cid:$cname" >> $COURSES
      echo "Course added successfully."
      pause
      manage_courses
      ;;
    2)
      clear
      echo -e "Course ID\tCourse Name"
      echo "---------------------------"
      awk -F: '{ printf "%-10s\t%s\n", $1, $2 }' $COURSES
      pause
      manage_courses
      ;;
    3)
      read -p "Enter Course ID to delete: " cid_del
      cid_del=$(echo "$cid_del" | xargs)

      if ! grep -q "^$cid_del:" $COURSES; then
        echo "Course ID not found."
        pause
        manage_courses
        return
      fi

      grep -v "^$cid_del:" $COURSES > tmp && mv tmp $COURSES
      grep -v ":$cid_del$" $ENROLLMENTS > tmp && mv tmp $ENROLLMENTS
      grep -v ":$cid_del:" $ATTENDANCE > tmp && mv tmp $ATTENDANCE
      grep -v ":$cid_del:" $GRADES > tmp && mv tmp $GRADES

      echo "Course and related records deleted."
      pause
      manage_courses
      ;;
    4)
      admin_menu
      ;;
    *)
      echo "Invalid choice!"
      pause
      manage_courses
      ;;
  esac
}

manage_enrollments() {
  clear
  echo "=== Manage Enrollments ==="
  echo "1) Enroll Student"
  echo "2) View Enrollments"
  echo "3) Remove Enrollment"
  echo "4) Back"
  read -p "Choose an option: " choice
  case $choice in
    1)
      read -p "Enter Student ID: " sid
      sid=$(echo "$sid" | xargs)
      read -p "Enter Course ID: " cid
      cid=$(echo "$cid" | xargs)
      if grep -q "^$sid:$cid$" $ENROLLMENTS; then
        echo "Already enrolled."
      else
        echo "$sid:$cid" >> $ENROLLMENTS
        echo "Enrolled."
      fi
      pause
      manage_enrollments
      ;;
    2)
      clear
      echo "=== Enrollments ==="
      while IFS=: read -r sid cid; do
        sname=$(grep "^$sid:" $STUDENTS | cut -d: -f2)
        cname=$(grep "^$cid:" $COURSES | cut -d: -f2)
        if [[ -n "$sname" && -n "$cname" ]]; then
          echo "$sname (ID: $sid) -> $cname (ID: $cid)"
        fi
      done < $ENROLLMENTS
      pause
      manage_enrollments
      ;;
    3)
      read -p "Enter Student ID: " sid
      sid=$(echo "$sid" | xargs)
      read -p "Enter Course ID: " cid
      cid=$(echo "$cid" | xargs)

      if grep -q "^$sid:$cid$" $ENROLLMENTS; then
        grep -v "^$sid:$cid$" $ENROLLMENTS > tmp && mv tmp $ENROLLMENTS
        grep -v "^$sid:$cid:" $ATTENDANCE > tmp && mv tmp $ATTENDANCE
        grep -v "^$sid:$cid:" $GRADES > tmp && mv tmp $GRADES

        echo "Enrollment and related records removed."
      else
        echo "Enrollment not found."
      fi
      pause
      manage_enrollments
      ;;
    4)
      admin_menu
      ;;
    *)
      echo "Invalid choice!"
      pause
      manage_enrollments
      ;;
  esac
}

mark_attendance() {
  clear
  echo "=== Mark Attendance ==="
  read -p "Student ID: " sid
  sid=$(echo "$sid" | xargs)
  read -p "Course ID: " cid
  cid=$(echo "$cid" | xargs)
  read -p "Date (YYYY-MM-DD): " date
  date=$(echo "$date" | xargs)
  read -p "Present (1) / Absent (0): " present
  present=$(echo "$present" | xargs)
  echo "$sid:$cid:$date:$present" >> $ATTENDANCE
  echo "Attendance marked."
  pause
  admin_menu
}

enter_grades() {
  clear
  echo "=== Enter/Update Grade ==="
  read -p "Student ID: " sid
  sid=$(echo "$sid" | xargs)
  read -p "Course ID: " cid
  cid=$(echo "$cid" | xargs)
  read -p "Grade (A-F): " grade
  grade=$(echo "$grade" | xargs)
  grep -v "^$sid:$cid:" $GRADES > tmp && mv tmp $GRADES
  echo "$sid:$cid:$grade" >> $GRADES
  echo "Grade updated."
  pause
  admin_menu
}

generate_reports() {
  clear
  echo "=== Reports ==="
  echo "1) Attendance Report"
  echo "2) Grade Report"
  echo "3) Back"
  read -p "Choose: " c
  case $c in
    1) attendance_report ;;
    2) grade_report ;;
    3) admin_menu ;;
    *) echo "Invalid choice!"; pause; generate_reports ;;
  esac
}

attendance_report() {
  clear
  echo "=== Attendance Report ==="
  read -p "Student ID: " sid
  sid=$(echo "$sid" | xargs)
  read -p "Course ID: " cid
  cid=$(echo "$cid" | xargs)

  grep "^$sid:$cid:" $ATTENDANCE | column -t -s:

  total=$(grep "^$sid:$cid:" $ATTENDANCE | wc -l)
  present=$(grep "^$sid:$cid:.*:1$" $ATTENDANCE | wc -l)
  percent=$(awk "BEGIN {printf \"%.2f\", ($present / ($total ? $total : 1)) * 100}")

  echo "Total Days: $total, Present: $present, Absent: $((total - present))"
  echo "Attendance Percentage: $percent%"
  pause
  generate_reports
}

grade_report() {
  clear
  echo "=== Grade Report ==="
  read -p "Student ID: " sid
  sid=$(echo "$sid" | xargs)
  grep "^$sid:" $GRADES | while IFS=: read _ cid grade; do
    cname=$(grep "^$cid:" $COURSES | cut -d: -f2)
    echo "$cname (ID: $cid) - Grade: $grade"
  done
  pause
  generate_reports
}

student_menu() {
  local username=$1
  clear
  echo "=== Student Menu ==="
  echo "1) View Profile"
  echo "2) Update Profile"
  echo "3) View Enrolled Courses"
  echo "4) View All Courses"
  echo "5) View Attendance"
  echo "6) View Grades"
  echo "7) Logout"
  read -p "Choose: " choice
  case $choice in
    1) view_profile "$username" ;;
    2) update_profile "$username" ;;
    3) view_enrolled_courses "$username" ;;
    4) view_all_courses ;;
    5) view_attendance "$username" ;;
    6) view_grades "$username" ;;
    7) welcome_screen ;;
    *) echo "Invalid choice!"; pause; student_menu "$username" ;;
  esac
}

view_all_courses() {
  clear
  echo "=== All Available Courses ==="
  if [[ ! -s "$COURSES" ]]; then
    echo "No courses available."
  else
    echo -e "Course ID\tCourse Name"
    echo "-------------------------------"
    awk -F: '{ printf "%-10s\t%s\n", $1, $2 }' "$COURSES"
  fi
  pause
  student_menu "$username"
}


view_profile() {
  local username=$1
  clear
  echo "=== Your Profile ==="
  line=$(grep ":$username:" $STUDENTS)
  IFS=":" read -r sid name uname email phone dob address <<< "$line"
  echo "Student ID     : $sid"
  echo "Name           : $name"
  echo "Username       : $uname"
  echo "Email          : $email"
  echo "Phone Number   : $phone"
  echo "Date of Birth  : $dob"
  echo "Address        : $address"
  pause
  student_menu "$username"
}

update_profile() {
  local username=$1
  clear
  echo "=== Update Your Profile ==="

  local line=$(grep ":$username:" $STUDENTS)
  if [[ -z "$line" ]]; then
    echo "Profile not found!"
    pause
    student_menu "$username"
    return
  fi

  IFS=":" read -r sid name uname email phone dob address <<< "$line"

  echo "Leave blank to keep current value."

  read -p "Name[$name]: " new_name
  read -p "Email[$email]: " new_email
  read -p "Phone[$phone]: " new_phone
  read -p "Date of Birth[$dob]: " new_dob
  read -p "Address[$address]: " new_address

  new_name=${new_name:-$name}
  new_email=${new_email:-$email}
  new_phone=${new_phone:-$phone}
  new_dob=${new_dob:-$dob}
  new_address=${new_address:-$address}

  sed -i "s/^$sid:.*:$username:.*:.*/$sid:$new_name:$username:$new_email:$new_phone:$new_dob:$new_address/" $STUDENTS

  echo "Profile updated successfully."
  pause
  student_menu "$username"
}

view_enrolled_courses() {
  local username=$1
  sid=$(grep ":$username:" $STUDENTS | cut -d: -f1)
  clear
  echo "=== Your Enrolled Courses ==="
  grep "^$sid:" $ENROLLMENTS | while IFS=: read _ cid; do
    cname=$(grep "^$cid:" $COURSES | cut -d: -f2)
    echo "$cid - $cname"
  done
  pause
  student_menu "$username"
}

view_attendance() {
  local username=$1
  sid=$(grep "^[^:]*:[^:]*:$username:" "$STUDENTS" | cut -d: -f1)
  clear
  echo "=== Your Attendance ==="

  total_attendance=0
  total_present=0

  while IFS=: read -r sid_line cid; do
    if [[ "$sid_line" == "$sid" ]]; then
      course_name=$(grep "^$cid:" "$COURSES" | cut -d: -f2)
      course_attendance=$(grep "^$sid:$cid:" "$ATTENDANCE" | wc -l)
      present_count=$(grep "^$sid:$cid:.*:1$" "$ATTENDANCE" | wc -l)

      total_attendance=$((total_attendance + course_attendance))
      total_present=$((total_present + present_count))

      if (( course_attendance > 0 )); then
        attendance_percent=$(awk "BEGIN {printf \"%.2f\", ($present_count / $course_attendance) * 100}")
      else
        attendance_percent="N/A"
      fi

      echo "Course: $course_name (ID: $cid)"
      echo "Total Classes: $course_attendance, Present: $present_count, Absent: $((course_attendance - present_count))"
      echo "Attendance %: $attendance_percent%"
      echo "----------------------------------"
    fi
  done < "$ENROLLMENTS"
  pause
  student_menu "$username"
}

view_grades() {
  local username=$1
  sid=$(grep ":$username:" $STUDENTS | cut -d: -f1)
  clear
  echo "=== Grades ==="
  grep "^$sid:" $GRADES | while IFS=: read _ cid grade; do
    cname=$(grep "^$cid:" $COURSES | cut -d: -f2)
    echo "$cname ($cid): $grade"
  done
  pause
  student_menu "$username"
}

# Start the program
welcome_screen
