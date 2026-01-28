<?php
    include 'connect.php';
    $sql = "SELECT * FROM feedback";
    $req = mysqli_query($con, $sql);
    $response = array();
    while($row=mysqli_fetch_array($req))
    {
        $value["f_drname"] = $row["f_drname"];
        $value["f_drspeciality"] = $row["f_drspeciality"];
        $value["f_message"] = $row["f_message"];
        $value["f_username"] = $row["f_username"];

        array_push($response, $value);
    }
    
    echo json_encode($response);

?>