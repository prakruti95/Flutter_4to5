<?php
    include 'connect.php';
    $sql = "SELECT * FROM doctors";
    $req = mysqli_query($con, $sql);
    $response = array();
    while($row=mysqli_fetch_array($req))
    {
        $value["id"] = $row["id"];
        $value["Speciality"] = $row["Speciality"];
        $value["Location"] = $row["Location"];
        array_push($response, $value);
    }
    
    echo json_encode($response);

?>