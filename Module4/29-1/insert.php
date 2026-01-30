<?php

    include 'connect.php';

    $a = $_POST["name"];
    $b = $_POST["surname"];
   

    if($a=="" && $b=="")
    {
        echo "All fields are required.";
    }
    else
    {
        $sql = "INSERT INTO students(name,surname) VALUES ('$a', '$b')";
        mysqli_query($con, $sql);
        mysqli_close($con);

}




?>