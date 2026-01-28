<?php

    include 'connect.php';

    $id = $_POST['f_id'];

    $sql = "DELETE FROM feedback WHERE f_id = '$id'";
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