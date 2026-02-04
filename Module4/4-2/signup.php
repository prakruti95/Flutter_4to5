<?php
 
 include('connect.php');

 $n1 = $_POST['name'];
 $s1 = $_POST['surname'];
 $e1 = $_POST['email'];
 $p1 = $_POST['password'];

 if($n1=="" && $s1=="" && $e1=="" && $p1=="")
 {
    echo "Please Fill All The Fields";
 }
 else
 {
    $query = "insert into student(name,surname,email,password) values('$n1','$s1','$e1','$p1')";
    mysqli_query($con,$query);
   
 }


?>