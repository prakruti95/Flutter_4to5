<?php

    include 'connect.php';

    $name = $_POST["f_drname"];
    $speciality = $_POST["f_drspeciality"];
    $msg = $_POST["f_message"];
    $uname = $_POST["f_username"];

    if($name=="" && $speciality=="" && $msg=="" && $uname=="")
    {
        echo "All fields are required.";
    }
    else
    {
        $sql = "INSERT INTO feedback (f_drname, f_drspeciality, f_message, f_username) VALUES ('$name', '$speciality', '$msg', '$uname')";
        mysqli_query($con, $sql);
        mysqli_close($con);

}




?>