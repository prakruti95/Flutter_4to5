<?php

    include 'connect.php';

    $id = $_POST['id'];
    $name = $_POST["name"];
    $surname = $_POST["surname"];
 

    $sql = "update students set name='$name', surname='$surname' where id = '$id'";
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