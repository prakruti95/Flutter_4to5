<?php

    include 'connect.php';

    $id = $_POST['f_id'];
    $name = $_POST["f_drname"];
    $speciality = $_POST["f_drspeciality"];
    $msg = $_POST["f_message"];
    $uname = $_POST["f_username"];

    $sql = "update feedback set f_drname='$name', f_drspeciality='$speciality', f_message='$msg', f_username='$uname' where f_id = '$id'";
    if(mysqli_query($con, $sql))
    {
        echo "Record updated successfully";
    }
    else
    {
        echo "Error deleting record: " . mysqli_error($con);
    }
   
    mysqli_close($con);
?>