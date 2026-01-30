<?php

    include 'connect.php';

    $id = $_POST['id'];

    $sql = "DELETE FROM students WHERE id = '$id'";
    if(mysqli_query($con, $sql))
    {
        echo "Record deleted successfully";
    }
    else
    {
        echo "Error deleting record: " . mysqli_error($con);
    }
   
    mysqli_close($con);
?>