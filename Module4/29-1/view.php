<?php
    include 'connect.php';
    $sql = "SELECT * FROM students";
    $req = mysqli_query($con, $sql);
    $response = array();
    while($row=mysqli_fetch_array($req))
    {
        $value["id"] = $row["id"];
        $value["name"] = $row["name"];
        $value["surname"] = $row["surname"];
        array_push($response, $value);
    }
    
    echo json_encode($response);

?>