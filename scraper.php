<?php
### Bega Valley Shire Council scraper

require 'scraperwiki.php';
require 'simple_html_dom.php';

date_default_timezone_set('Australia/Sydney');

// Default to 'thisweek', use MORPH_PERIOD to change to 'thismonth' or 'lastmonth' for data recovery
switch(getenv('MORPH_PERIOD')) {
    case 'thismonth' :
        $datefrom = date('01/m/Y');         // hard-coded '01' for first day
        $dateto   = date('t/m/Y');
        break;
    case 'lastmonth' :
        $datefrom = date('d/m/Y', strtotime('first day of previous month'));
        $dateto   = date('d/m/Y', strtotime('last day of previous month'));
        break;
    case 'thisweek' :
    default         :
        $datefrom = date('d/m/Y', strtotime('-1 week'));
        $dateto   = date('d/m/Y');
        break;
}
print "Getting data between " .$datefrom. " and " .$dateto. ", changable via MORPH_PERIOD environment\n";


// setup all the know kind of fixed stuff
$junktoServer = 'draw=1&columns%5B0%5D%5Bdata%5D=0&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=false&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=1&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=false&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B2%5D%5Bdata%5D=2&columns%5B2%5D%5Bname%5D=&columns%5B2%5D%5Bsearchable%5D=true&columns%5B2%5D%5Borderable%5D=false&columns%5B2%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B2%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B3%5D%5Bdata%5D=3&columns%5B3%5D%5Bname%5D=&columns%5B3%5D%5Bsearchable%5D=true&columns%5B3%5D%5Borderable%5D=false&columns%5B3%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B3%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B4%5D%5Bdata%5D=4&columns%5B4%5D%5Bname%5D=&columns%5B4%5D%5Bsearchable%5D=true&columns%5B4%5D%5Borderable%5D=false&columns%5B4%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B4%5D%5Bsearch%5D%5Bregex%5D=false&start=0&length=200&search%5Bvalue%5D=&search%5Bregex%5D=false&json=';
$jsontoServer = '{"ApplicationNumber":null,"ApplicationYear":null,"DateFrom":"1/06/2016","DateTo":"30/06/2016","DateType":"1","RemoveUndeterminedApplications":false,"ApplicationDescription":null,"ApplicationType":null,"UnitNumberFrom":null,"UnitNumberTo":null,"StreetNumberFrom":null,"StreetNumberTo":null,"StreetName":null,"SuburbName":null,"PostCode":null,"PropertyName":null,"LotNumber":null,"PlanNumber":null,"ShowOutstandingApplications":false,"ShowExhibitedApplications":false,"PropertyKeys":null,"PrecinctValue":null,"IncludeDocuments":false}';

$url_base = "http://datracker.begavalley.nsw.gov.au/Application/GetApplications";
$infourl_base = "http://datracker.begavalley.nsw.gov.au/Application/ApplicationDetails/";
$comment_base = "mailto:council@begavalley.nsw.gov.au";

// set the date from and date to field
$json = json_decode($jsontoServer);
$json->DateFrom = $datefrom;
$json->DateTo   = $dateto;
$json = json_encode($json, JSON_UNESCAPED_SLASHES);

// Create a stream
$opts = array(
  'http'=>array(
    'method'  => "POST",
    'header'  => "Accept: application/json\r\n" .
                 "Content-Type: application/x-www-form-urlencoded; charset=UTF-8\r\n" .
                 "Cookie: User=accessAllowed-MasterView=True\r\n",
    'content' => $junktoServer . urlencode($json),
    'timeout' => 300,
  )
);
$context = stream_context_create($opts);

// Open the file using the HTTP headers set above and deal with the stuff received
$file  = file_get_contents($url_base, false, $context);
$decodedStuff = json_decode($file);


    // The usual, look for the data set and if needed, save it
    foreach ($decodedStuff->data as $record) {
        // Slow way to transform the date but it works
        $date_received = explode('/', $record[3]);
        $date_received = "$date_received[2]-$date_received[1]-$date_received[0]";

        // Get the address and description
        $tokens = explode(" <br/>", $record[4]);
        $address = $tokens[0];
        $description = str_ireplace(['<b>', '</b>'], '', end($tokens));

        // Put all information in an array
        $application = array (
            'council_reference' => $record[1],
            'address'           => $address,
            'description'       => $description,
            'info_url'          => $infourl_base . $record[0] . '/',
            'comment_url'       => $comment_base,
            'date_scraped'      => date('Y-m-d'),
            'date_received'     => date('Y-m-d', strtotime($date_received))
        );

        // Check if record exist, if not, INSERT, else do nothing
        $existingRecords = scraperwiki::select("* from data where `council_reference`='" . $application['council_reference'] . "'");
        if (count($existingRecords) == 0) {
            print ("Saving record " . $application['council_reference'] . ' - ' . $address . "\n");
            # print_r ($application);
            scraperwiki::save(array('council_reference'), $application);
        } else {
            print ("Skipping already saved record " . $application['council_reference'] . "\n");
        }
    }

?>
