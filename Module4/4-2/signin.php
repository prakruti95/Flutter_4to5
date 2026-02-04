<?php

    include('connect.php');

    $email = $_REQUEST["e1"];
    $pass = $_REQUEST["p1"];


    $sql = "select * from student where email = '$email' and password='$pass'";
    $result=mysqli_query($con,$sql);


     $num=mysqli_num_rows($result);

    if($num>0)
    {
        $fetch=mysqli_fetch_object($result);
        echo json_encode(['code'=>200]);
    }
    else
    {
        echo "0";
    }


?>