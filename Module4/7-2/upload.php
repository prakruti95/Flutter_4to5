<?php

//importing dbDetails file
include 'connect.php';

//this is our upload folder
$upload_path = 'images/';

//Getting the server ip
 $server_ip = gethostbyname(gethostname());

//creating the upload url
// $upload_url = $upload_path;
$upload_url = 'https://'.$_SERVER['SERVER_NAME'] . "/API/" . $upload_path;

//echo $upload_url;

//getting name from the request
$cname = $_REQUEST['category_name'];




//getting file info from the request
$fileinfo = pathinfo($_FILES["category_img"]["category_name"]);

//getting the file extension
$extension = $fileinfo["extension"];

$random = 'image_' . rand(1000,9999);

//file url to store in the database
$file_url = $upload_url . $random . '.' . $extension;

//file path to upload in the server
$file_path = $upload_path . $random . '.'. $extension;

//saving the file
move_uploaded_file($_FILES["category_img"]["tmp_name"],$file_path);




$sql = "INSERT INTO product_main_category(category_name,category_img) VALUES ('$cname','$file_url')";
//echo $sql;
//exit;
$ex=mysqli_query($con,$sql);

//closing the connection
mysqli_close($con);

?>