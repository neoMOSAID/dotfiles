<?php

error_reporting(E_ALL);
function connectDB(){
    // create databse connection
    $mysqli = new mysqli("localhost", "root", "1313");
    if ($mysqli->connect_errno) {
        printf("Connect failed: %s\n", $mysqli->connect_error);
        exit();
    }
    $mysqli->select_db("WALLHAVEN");
    return $mysqli;
}

function createDB() {
    $mysqli = connectDB();
    // select database or create it
    $query="CREATE DATABASE IF NOT EXISTS WALLHAVEN ";
    $result = $mysqli->query($query);
    $mysqli->select_db("WALLHAVEN");
    // create tables
    $query="CREATE TABLE IF NOT EXISTS `PASSWORDS`(
        `user` varchar(500)  NOT NULL UNIQUE default '',
        `password` varchar(500)  NOT NULL default ''
    );";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $query="CREATE TABLE IF NOT EXISTS `downloaded`(
        `id` int(5) NOT NULL UNIQUE AUTO_INCREMENT PRIMARY KEY,
        `name` varchar(50)  NOT NULL UNIQUE default '1',
        `dir` varchar(50) ,
        `path` varchar(1000)
    );";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $query="CREATE TABLE IF NOT EXISTS `categories`(
        `id` int(5) NOT NULL UNIQUE AUTO_INCREMENT PRIMARY KEY,
        `name` varchar(50)  NOT NULL UNIQUE default '1',
        `category` varchar(5) NOT NULL DEFAULT 's'
    );";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $query="CREATE TABLE IF NOT EXISTS `info`(
            `id` int(5) NOT NULL UNIQUE AUTO_INCREMENT PRIMARY KEY,
            `tag` varchar(100)  NOT NULL UNIQUE default '',
            `name` varchar(500) NOT NULL DEFAULT '',
            `alias` varchar(500) NOT NULL DEFAULT ''
            ) ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $query="CREATE TABLE IF NOT EXISTS `favs`(
        `id` int(5) NOT NULL UNIQUE AUTO_INCREMENT PRIMARY KEY,
        `fid` int(11) NOT NULL,
        `name` varchar(50)  NOT NULL,
        UNIQUE INDEX(fid,name)
    );";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $query="CREATE TABLE IF NOT EXISTS `favslist`(
        `id` int(5) NOT NULL UNIQUE AUTO_INCREMENT,
        `name` varchar(100)  NOT NULL UNIQUE default '',
        `category` varchar(5) NOT NULL DEFAULT 's'
    ) ";
    #$query="ALTER TABLE favslist ADD COLUMN category varchar(5) NOT NULL DEFAULT 's'; ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $query="CREATE TABLE IF NOT EXISTS `whistory`(
        `name` varchar(100)  NOT NULL UNIQUE default '',
        `value` varchar(500) NOT NULL default '0'
    ) ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
   // close connection
    $mysqli->close();
}

function where_c($c){
    switch ( $c ) {
    case "d":
    case "x":
    case "s":
    case "m":
        $where = "  where ( category='$c' ) " ;
        break;
    case "ms":
    case "sm":
        $where = " where  ( category='s' or category= 'm' ) ";
        break;
    case "md":
    case "dm":
        $where = " where ( category='d' or category= 'm' ) ";
        break;
    case "*" :
    default:
        $where = "" ;
    }
    return $where ;
}

function addpass($user, $password){
    $mysqli = connectDB();
    $query = "
        INSERT IGNORE INTO PASSWORDS (user,password)
        VALUES ('$user','$password')
    ";
    if(! $result = $mysqli->query($query)){

        printf("error: %s\n", $mysqli->error );
        exit();
    }
    $mysqli->close();
}

//$password = password_hash('insertpasshere', PASSWORD_DEFAULT);
//addpass("chwlpf",$password);

function getpass($user,$password) {
    $mysqli = connectDB();
    $query = "SELECT password FROM PASSWORDS WHERE user = '".$user."' ";
    if(! $result = $mysqli->query($query)){

        printf("error: %s\n", $mysqli->error );
        exit();
    }
    $row = $result->fetch_array(MYSQLI_NUM);
    if (password_verify($password, $row[0])) { return "1"; }
    else { return "0" ; }
    $mysqli->close();
}
function authenticate ($user,$password ){
    $user = trim(strip_tags($user));
    $user = addslashes($user);
    $password = trim(strip_tags($password));
    $password = addslashes($password);
    return getpass($user,$password);
}

function wHistory_set($name,$value){
    $mysqli = connectDB();
    $query ="
            INSERT INTO whistory (name, value)
            VALUES('$name', '$value')
            ON DUPLICATE KEY UPDATE
            name='$name' , value='$value' ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $mysqli->close();
}
function getAllFavs(){
    $mysqli = connectDB();
    $query="select name from favs";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
        printf("%s\n", $row[0]);
    }
    $mysqli->close();
}
function test0(){
    $mysqli = connectDB();
    $query="update categories set category='d'
        where name in (
            select t2.name from downloaded t1
            left join categories t2  on t1.name = t2.name
            where category = 'x' and t1.path <> 'deleted'
        ); ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
        printf("%s\n", $row[0]);
    }
    $mysqli->close();
}
function test1(){
    $mysqli = connectDB();
    $query="
                    select t2.name from downloaded t1
                    left join categories t2  on t1.name = t2.name
                    where category = 'x' and t1.path <> 'deleted'
            ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
        printf("%s\n", $row[0]);
    }
    $mysqli->close();
}
function wHistory_get($name){
    $mysqli = connectDB();
    $query =" select value from whistory where name='$name' ; ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $row = $result->fetch_array(MYSQLI_NUM);
    printf("%s\n", $row[0]);
    $mysqli->close();
}

function resetDB(){
    $mysqli = connectDB();
    if ($mysqli->query("drop table downloaded")) {
        createDB();
    }else echo "error:";
    $mysqli->close();
}

function addFav($name,$fid){
    $mysqli = connectDB();
    $query ="
            INSERT INTO favs (name, fid)
            VALUES('$name', '$fid') ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $mysqli->close();
}
function rmFav($name,$fid){
    $mysqli = connectDB();
    $query =" DELETE FROM favs
              WHERE name = '$name'
              AND fid = '$fid' ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $mysqli->close();
}

function addFile($name,$dir,$path){
    $mysqli = connectDB();
    $query ="
            INSERT INTO downloaded (name,dir, path)
            VALUES('$name','$dir', '$path')
            ON DUPLICATE KEY UPDATE
            name='$name' , dir='$dir' , path='$path' ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $mysqli->close();
}

function adddescription($tag,$name,$alias){
    $mysqli = connectDB();
    $name = addslashes($name);
    $alias = addslashes($alias);
    $query =" insert ignore INTO info
        (`tag`, `name`,`alias`) VALUES
        ('$tag', '$name', '$alias') ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $mysqli->close();
}
function addFavList($name,$c){
    $mysqli = connectDB();
    $query =" insert INTO favslist
        (`name`,`category`) VALUES
        ('$name','$c') ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $mysqli->close();
}
function getFavName($id){
    $mysqli = connectDB();
    $query =" select name from favslist where id='$id' ; ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $row = $result->fetch_array(MYSQLI_NUM);
    printf("%s\n", $row[0]);
    $mysqli->close();
}

function getFavList($c){
    $mysqli = connectDB();
    $where = where_c($c);
    $query =" select * from favslist $where ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
        printf("%d:%s\n", $row[0],$row[1]);
    }
    $mysqli->close();
}

function fileExists($name){
    $mysqli = connectDB();
    $query =" select id from downloaded where name='$name' ; ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $n=$result->num_rows;
    $mysqli->close();
    if ( $n > 0) return 1;
    else return 0;
}


function getFileByID($id){
    $mysqli = connectDB();
    $query =" select path from downloaded where id=$id ; ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $row = $result->fetch_array(MYSQLI_NUM);
    printf("%s\n", $row[0]);
    $mysqli->close();
}

function getFileByName($name){
    $mysqli = connectDB();
    $query =" select path from downloaded where name='$name' ; ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $row = $result->fetch_array(MYSQLI_NUM);
    printf("%s\n", $row[0]);
    $mysqli->close();
}

function getALL(){
    $mysqli = connectDB();
    $query =" select path from downloaded where path <> '' ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
        printf("%s\n", $row[0]);
    }
    $mysqli->close();
}
function getCategoryByName($name){
    $mysqli = connectDB();
    $query= "select t1.category from categories t1
             inner join downloaded t2
             on t1.name = t2.name
             where t2.name='$name' ; ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $row = $result->fetch_array(MYSQLI_NUM);
    printf("%s\n", $row[0]);
    $mysqli->close();
}
function resetCategories(){
    $mysqli = connectDB();
    $query= "select t1.category from categories t1
        inner join downloaded t2
        on t1.name = t2.name
        where t2.name='$name' ; ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $row = $result->fetch_array(MYSQLI_NUM);
    printf("%s\n", $row[0]);
    $mysqli->close();
}
function getFavs($fid){
    $mysqli = connectDB();
    $query=" select t1.path, t2.id from downloaded t1
             left join favs t2
             on t1.name = t2.name
             where t2.fid = '$fid'
             order by t2.id asc ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
        printf("%s:%s\n",$row[1], $row[0]);
    }
    $mysqli->close();
}
function getFav($index,$fid){
    $mysqli = connectDB();
    if ($index >=1 ) $index--;
    $query="
            select t1.path from downloaded t1
            inner join favs t2
            on t1.name = t2.name
            where t2.fid = '$fid'
            ORDER BY t2.id LIMIT $index ,1 " ;
            //ORDER BY rand() LIMIT 0,1 " ;
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $row = $result->fetch_array(MYSQLI_NUM) ;
    printf("%s\n", $row[0]);
    $mysqli->close();
}

function getFcount($fid){
    $mysqli = connectDB();
    $query=" select id from favs
             where fid = '$fid'
             order by id asc ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $n=$result->num_rows;
    printf("%d\n", $n);
    #while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
    #    printf("%s\n", $row[0]);
    #    #printf("%s:%s\n",$row[1], $row[0]);
    #}
    $mysqli->close();
}

function orphanedFavs(){
    $mysqli = connectDB();
    $query="select t1.name from favs t1
        left join favslist t2
        on t1.fid = t2.id
        WHERE t2.id IS NULL ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $n=$result->num_rows;
    if ($n==0){
        echo "no orphaned id found\n";
    }else {
        echo "these names exist in favs table and their fid no longer exists \n";
        while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
            printf("%s\n", $row[0]);
        }
    }
    $mysqli->close();

}

function resetRemoved(){
    $mysqli = connectDB();
    $query=" delete from categories
             where name in (
                select name from downloaded where path = ''
             ) ; " ;
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $query=" delete from favs
             where name in (
                select name from downloaded where path = ''
             ) ; " ;
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $mysqli->close();
}

//function getDuplicates(){
//    $query="SELECT name, COUNT(*) c FROM downloaded GROUP BY name HAVING c > 1;";
//}

function fixPath($id){
    $mysqli = connectDB();
    $query="update downloaded set path='', dir='' where name='$id' ";
    if(! $result = $mysqli->query($query)){
        printf("err@%s : %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $mysqli->close();
}

function getFCategory($fid){
    $mysqli = connectDB();
    $query =" select category from favslist where id='$fid' ; ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $row = $result->fetch_array(MYSQLI_NUM);
    printf("%s\n", $row[0]);
    $mysqli->close();
}

function getUncategorised(){
    $mysqli = connectDB();
    $query="select t1.path from downloaded t1
            left join categories t2
            on t1.name = t2.name
            WHERE t2.id IS NULL and t1.path <> '' ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
        printf("%s\n", $row[0]);
    }
    $mysqli->close();
}

function fixCategory($name,$c){
    $mysqli = connectDB();
    $query="
            INSERT INTO categories (name, category)
            VALUES('$name', '$c')
            ON DUPLICATE KEY UPDATE
            name='$name' , category='$c' ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $mysqli->close();
}

function getOrederedCount($c){
    $mysqli = connectDB();
    $where=where_c($c);
    $query=" select path from downloaded t1
        inner join categories t2
        on t2.name = t1.name
         $where
        ORDER BY t1.id " ;
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $n=$result->num_rows;
    printf("%d\n", $n);
    $mysqli->close();
}

function getDir($dir,$index,$n,$c){
    $index--;
    $mysqli = connectDB();
    $where=where_c($c);
    $query=" select path from downloaded t1
             inner join categories t2
             on t1.name = t2.name
             $where and ( t1.dir = '$dir' )
             ORDER BY t1.id
             LIMIT $index,$n " ;
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
        printf("%s\n", $row[0]);
    }
    $mysqli->close();
}

function getDirs($c){
    $mysqli = connectDB();
    $where=where_c($c);
    $query=" select DISTINCT dir from downloaded t1
             inner join categories t2
             on t1.name = t2.name
             $where
    " ;
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
        printf("%s\n", $row[0]);
    }
    $mysqli->close();
}

function getDirCount($dir,$c){
    $mysqli = connectDB();
    $where=where_c($c);
    $query=" select path from downloaded t1
             inner join categories t2
             on t1.name = t2.name
             $where and ( dir = '$dir' )
             ORDER BY t1.id ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $n=$result->num_rows;
    printf("%d\n", $n);
    $mysqli->close();
}

function getOredered($index,$c,$n){
    $index--;
    if ( $index <= 0 ) $index=1;
    $mysqli = connectDB();
    $where=where_c($c);
    $query=" select path from downloaded t1
        inner join categories t2
        on t2.name = t1.name
        $where
        ORDER BY t1.id
        LIMIT $index,$n " ;
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
        printf("%s\n", $row[0]);
    }
    $mysqli->close();
}

function getFavListByName($name){
    $mysqli = connectDB();
    $query=" select t1.id, t1.name from favslist t1
        inner join favs t2
        on t2.fid = t1.id
        where t2.name='$name' " ;
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
        printf("%s:%s\n", $row[0],$row[1]);
    }
    $mysqli->close();
}

function getWebIds(){
    $mysqli = connectDB();
    $query = "select * from info ";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    while ( $row = $result->fetch_array(MYSQLI_NUM) ) {
        printf("%s(%s)\n", $row[1],$row[2]);
    }
    $mysqli->close();
}

function getRandom($c){
    $mysqli = connectDB();
    $query=" select path from downloaded t1
             inner join categories t2
             on t2.name = t1.name
             where t2.category='$c'
             order by rand()
             limit 0,1 " ;
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $row = $result->fetch_array(MYSQLI_NUM);
    printf("%s\n", $row[0]);
    $mysqli->close();
}

function lastName(){
    $mysqli = connectDB();
    $query = "select name from downloaded
              order by name desc limit 1 ;" ;
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $row = $result->fetch_array(MYSQLI_NUM);
    printf("%s\n", $row[0]);
    $mysqli->close();
}

function getTagName($tag){
    $mysqli = connectDB();
    $query = "select name from info where tag='$tag'";
    if(! $result = $mysqli->query($query)){
        printf("@%s: %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $row = $result->fetch_array(MYSQLI_NUM);
    printf("%s\n", $row[0]);
    $mysqli->close();
}

function changeList($id,$list,$c){
    $mysqli = connectDB();
    $query="update favslist set name='$list', category='$c' where id='$id' ";
    if(! $result = $mysqli->query($query)){
        printf("err@%s : %s\n",__FUNCTION__, $mysqli->error );
        exit();
    }
    $mysqli->close();
}

createDB();

if (defined('STDIN')){
    parse_str(implode('&', array_slice($argv, 1)), $_GET);
}

if ( isset($_GET["f"]) ) switch ( $_GET["f"] ){
    case "addfav" :
        if (defined('STDIN')) {
            $fid=$argv[2];
            $name=$argv[3];
        }
        addFav($name,$fid);
        break;
    case "rmfav" :
        if (defined('STDIN')) {
            $fid=$argv[2];
            $name=$argv[3];
        }
        rmFav($name,$fid);
        break;
    case "addfavlist" :
        if (defined('STDIN')) {
            $name=$argv[2];
            $c=$argv[3];
        }
        addFavList($name,$c);
        break;
    case "getfav" :
        if (defined('STDIN')) {
            $fid=$argv[2];
            $id=$argv[3];
        }
        getFav($id,$fid);
        break;
    case "getfavs" :
        if (defined('STDIN')) {
            $fid=$argv[2];
        }
        getFavs($fid);
        break;
    case "getfcount" :
        if (defined('STDIN')) {
            $fid=$argv[2];
        }
        getFcount($fid);
        break;
    case "add" :
        if (defined('STDIN')) {
            $id=$argv[2];
            $dir=$argv[3];
            $path=$argv[4];
        }
        addFile($id,$dir,$path);
        break;
    case "adddesc" :
        if (defined('STDIN')) {
            $tag=$argv[2];
            $name=$argv[3];
            $alias=$argv[4];
        }
        adddescription($tag,$name,$alias);
        break;
    case "downloaded" :
        if (defined('STDIN')) $id=$argv[2];
        echo fileExists($id);
        break;
    case "get" :
        if (defined('STDIN')) $name=$argv[2];
        echo getFileByName($name);
        break;
    case "geti" :
        if (defined('STDIN')) $id=$argv[2];
        echo getFileByID($id);
        break;
    case "fixcategory" :
        if (defined('STDIN')) {
            $name=$argv[2];
            $c=$argv[3];
        }
        fixCategory($name,$c);
        break;
    case "reset" :
        resetDB();
        break;
    case "last" :
        lastName();
        break;
    case "resetRemoved" :
        resetRemoved();
        break;
    case "getrandom" :
        if (defined('STDIN')) $c=$argv[2];
        getRandom($c);
        break;
    case "getfavname" :
        if (defined('STDIN')) $id=$argv[2];
        getFavName($id);
        break;
    case "getfavlist" :
        if (defined('STDIN')) $c=$argv[2];
        getFavList($c);
        break;
    case "getfavlistbyname":
        if (defined('STDIN')) $id=$argv[2];
        getFavListByName($id);
        break;
    case "wh_set" :
        if (defined('STDIN')) {
            $name=$argv[2];
            $value=$argv[3];
        }
        wHistory_set($name,$value);
        break;
    case "wh_get" :
        if (defined('STDIN')) {
            $name=$argv[2];
        }
        wHistory_get($name);
        break;
    case "getcategorybyname" :
        if (defined('STDIN')) {
            $name=$argv[2];
        }
        getCategoryByName($name);
        break;
    case "getorderedcount" :
        if (defined('STDIN')) {
            $c=$argv[2];
        }
        getOrederedCount($c);
        break;
    case "getordered" :
        if (defined('STDIN')) {
            $index=$argv[2];
            $c=$argv[3];
            $n=$argv[4];
        }
        getOredered($index,$c,$n);
        break;
    case "uncategorised" :
        getUncategorised();
        break;
    case "authenticate" :
        if (defined('STDIN')) {
            $user=$argv[2];
            $password=$argv[3];
        }
        echo authenticate($user,$password);
        break;
    case "getwebids":
        getWebIds();
        break;
    case "changelist" :
        if (defined('STDIN')) {
            $id=$argv[2];
            $name=$argv[3];
            $c=$argv[4];
        }
        changeList($id,$name,$c);
        break;
    case "getallfavs" :
        getAllFavs();
        break;
    case "getdir":
        if (defined('STDIN')) {
            $dir=$argv[2];
            $index=$argv[3];
            $n=$argv[4];
            $c=$argv[5];
        }
        getDir($dir,$index,$n,$c);
        break;
    case "getdircount":
        if (defined('STDIN')) {
            $dir=$argv[2];
            $c=$argv[3];
        }
        getDirCount($dir,$c);
        break;
    case "getdirs":
        if (defined('STDIN')) {
            $c=$argv[2];
        }
        getDirs($c);
        break;
    case "test1" :
        test1();
        break;
    case "getall" :
        getALL();
        break;
    case "orphanedfavs" :
        orphanedFavs();
        break;
    case "gettagname":
        if (defined('STDIN')) {
            $tag=$argv[2];
        }
        getTagName($tag);
        break;
    case "getfcategory":
        if (defined('STDIN')) {
            $fid=$argv[2];
        }
        getFCategory($fid);
        break;
    case "fixpath":
        if (defined('STDIN')) {
            $id=$argv[2];
        }
        fixPath($id);
        break;
}





?>
