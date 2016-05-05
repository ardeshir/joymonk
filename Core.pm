package Library::Core;

use Exporter 'import';
@EXPORT = qw(my_dispatch my_search_box my_box t_box my_dbValue my_dbh my_cl my_html my_header my_init var_pars my_sessionID my_content my_getCookie my_content my_css er_notice set_click);
@EXPORT_OK = qw(my_dispatch my_search_box my_box t_box my_dbValue my_dbh my_cl my_struc
                my_html my_header my_init var_pars my_sessionID my_content my_dbValuesHash
                my_getCookie my_content my_css my_updateSession er_notice set_click);
$VERSION = '0.2';
use Apache::compat;
use Apache::RequestRec ();
use Apache::RequestIO ();
use APR::Table ();
use Apache::Const -compile => qw(:common REDIRECT);
use CGI qw(:all :cgi-lib :standard);
use CGI::Cookie ();

use DBI;


sub handler {

#>>>  A configuration hash reference
     my  $cf = {
     title        => "Library $VERSION a blissful place!",
     #site_image    => 'http://www.mplib.org/images/flower.jpg',
     logo         => '',  # place logo here
     default_image  => '', # defualt image here
     url_perl       => '/admin',
     url_login      => '/perl/Login.pl',
     url_logout     => '/logout',
     url_google        => 'http://www.google.com/search?hl=en&q=',
     admin_email    => 'admin@hclib.org',
     DEBUG          => 0,
     host           => '',  # host name
     database       => 'staff',  # databse name
     user           => 'postgres',
     pwd            => '',
     click          => { Blogs   => '',
                         CareBox => '',
                         Suggestion  => '',
                         Memes   => '',
                         Pics    => '',
                         Profiles=> '',},
 
     cryp        => 'YhkijhIFBVCyjjudkwiurudjo',
     sql            => 'SELECT * FROM profile',
     msg            => 'You are not currently signed in',
     err            => '<font color=red>There was an error signing in, please try again!</font>',
      
     tbl  => {},

    };

my $dbh = my_dbh($cf);
my $r = shift;
#my $hs = { tbl => {}, }; # helper hash ref
my $q_get = $r->args;
my $q_post = $r->content;
my $q = var_pars($q_get) if $q_get;
my $qp = var_pars($q_post) if $q_post;

my $time = scalar localtime;

my @sid = cookie('sessionID');
set_click($q, $cf) if $q;
my_init($cf, $r);



    if($qp->{login}) {
 
              my $ret = my_dbValue( qq(SELECT * FROM PROFILE WHERE email='$qp->{email}' AND password='$qp->{password}'), $dbh, $r);
  
              if( ref($ret) ) {
   
                      if( $qp->{password} eq $ret->{password} ) {
                          $cf = my_struc(
                             my_dbValuesHash( "select login, counter, note, comment from session where user_id=$ret->{user_id}", $dbh, $r), $cf,  $r ) ;   
          
                            $r->err_headers_out->add('Set-Cookie' =>
                                                                           my_sessionID( 'sessionID',
                                                                           $cf->{cryp}, $ret->{email}, $ret->{user_id}, $ret->{extra_id}, 'in') );
                           my_updateSession($ret, $dbh, $r, 2);
                           $r->print( &my_linksBox($qp, $cf, $ret, $r) );
                           my_dispatch($qp, $cf, $ret, $r);
     
                      } else {
                           $r->print( my_login($cf, $cf->{err} ) );
                      }        
              
                        } else {
                      $r->print( my_login($cf, $cf->{err}) );
               }


    } elsif (@sid)  {
                
           my $ret = my_dbValue("SELECT * FROM profile WHERE user_id=$sid[2]", $dbh, $r);
           $cf = my_struc( my_dbValuesHash( "select login, counter, note, comment from session where user_id=$sid[2]", $dbh, $r), $cf, $r);
           $r->print( &my_linksBox($q, $cf, $ret, $r) );    
           $r->print( t_box("In elsif sid, after linksBox not in the if q-> auth yet"), %{$q} ) if $cf->{DEBUG};   
   
            if( $qp->{action} ) {
                  my $ret = my_dbValue("SELECT * FROM profile WHERE user_id=$sid[2]", $dbh, $r);
                      $r->print( t_box("inside the if qp-> auth of the sid, befor my_dispatch"), %{$qp} ) if $cf->{DEBUG};
                  my_dispatch($qp, $cf, $ret, $r, $dbh);
             }
               
              
            if ($q->{auth}) {
                   $r->print( t_box("inside the if q-> auth of the sid"), %{$q} ) if $cf->{DEBUG};
                   my $profile = my_dbValue("SELECT * FROM profile WHERE user_id=$q->{auth}", $dbh, $r) ;
                   my_updateSession($profile, $dbh, $r, 1) if $q->{auth} ne $sid[2];
                   my $hr = { tbl =>{} , } ;  # this creates a table needed for viewing other's info
                   $hr = my_struc( my_dbValuesHash( "select login, counter from session where user_id=$q->{auth}", $dbh, $r), $hr, $r);
                   $r->print( &t_box( &my_search_box($profile, $hr) ) );
      
                $r->print( t_box("inside the if q auth of the sid, before v_dispatch"), %{$q} ) if $cf->{DEBUG};
            v_dispatch($q, $cf, $profile, $r);
                $r->print( t_box("inside the if q auth of the sid, after v_dispatch"), %{$q} ) if $cf->{DEBUG};
                $r->print( t_box("inside the if q auth of the sid, after v_dispatch, before my_dispath"), %{$q} ) if $cf->{DEBUG};
                my_dispatch($q, $cf, $ret, $r) unless $q->{action} eq 'ck_requests';
                $r->print( t_box("We're inside the if q auth of the sid, after my_dispatch"), %{$q} ) if $cf->{DEBUG};
             } else {
                $r->print( t_box("inside the else of the sid, before v_dispatch") , %{$q} ) if $cf->{DEBUG};
                my $profiles = my_struc( my_dbValuesHash("SELECT * FROM profile", $dbh, $r), $cf, $r) ;
                v_dispatch($q, $cf, $profiles, $r);
                $r->print( t_box("inside the else of the sid, after v_dispath") , %{$q} ) if $cf->{DEBUG};
             }
                $r->print( t_box("We're outside of sid, before my_dispatch"), %{$q} ) if $cf->{DEBUG};
                 my_dispatch($q, $cf, $ret, $r) unless $q->{auth};
                $r->print( t_box("We're outside of sid, past my_dispatch"), %{$q} ) if $cf->{DEBUG};


    
    } elsif ($q) {

           $r->print( my_login( $cf, $cf->{msg} ) );

           if ($q->{action} && $q->{auth} ) {
                  my $profile = my_dbValue("SELECT * FROM profile WHERE user_id=$q->{auth}", $dbh, $r) ;
                  $cf = my_struc( my_dbValuesHash( "select login, counter from session where user_id=$q->{auth}", $dbh, $r), $cf, $r); 
                  $r->print( &t_box( &my_search_box($profile, $cf) ) );
                  v_dispatch($q, $cf, $profile, $r);
                  my_updateSession($profile, $dbh, $r, 1);
           } else {
                 my $ret = my_dbValue("SELECT * FROM profile", $dbh, $r) ;
                        v_dispatch($q, $cf, $ret, $r, $qp);

           }
     

          
    } else {
           $r->print( my_login( $cf, $cf->{msg} ) );
           $r->print( my_content($dbh, $cf->{sql}, \&my_box) );
    }



$r->print( my_html($cf) );
$r->status(200);
return Apache::Const::OK;
}


##############################
##### SUB DEFS ##################
##############################

sub my_init {
my ($cf, $r) = @_ ;

#$values = [ 'YhkijhIFBVCyjjudkwiurudjo', $cf->{admin_email} ];
#$cookie = CGI::Cookie->new(-name  => 'sessionID', -value => $values, -expires =>'+15m' );
$r->no_cache(1);
#$r->err_headers_out->add('Set-Cookie' => $cookie);
$r->send_http_header('text/html');
$r->print(   my_header($cf)  );
}

sub my_header {
#print "Content-type: text/html; charset=iso-8859-1\n\n";
my $cf = shift;
print &my_css($cf);

return<<"END";
<META name="verify-v1" content="J3rayvzoSz/MiXXeiFG2MfyO/tvTfLmAtEQe3cFRzUQ=" />
<link rel="shortcut icon" href="http://www.google.com/a/mplib.org/images/logo.gif" type="image/x-icon" />

    <link href="http://www.google.com/uds/css/gsearch.css" type="text/css" rel="stylesheet"/>
    <script src="http://www.google.com/uds/api?file=uds.js&amp;v=0.1&amp;key=ABQIAAAABQROoHdBgd_mIktspgfUjxRqaaclY0l4BUyRHUOsby_HoWa_IRQSDy7HsST7JAFHe49STPWayg-xMQ" type="text/javascript"></script>
    <script language="Javascript" type="text/javascript">
    //<![CDATA[

    function OnLoad() {
      // Create a search control
      var searchControl = new GSearchControl();

      // Add in a full set of searchers
      var localSearch = new GlocalSearch();
      searchControl.addSearcher(localSearch);
      searchControl.addSearcher(new GwebSearch());
      searchControl.addSearcher(new GvideoSearch());
      searchControl.addSearcher(new GblogSearch());

      // Set the Local Search center point
      localSearch.setCenterPoint("New York, NY");

      // Tell the searcher to draw itself and tell it where to attach
      searchControl.draw(document.getElementById("searchcontrol"));

      // Execute an inital search
      searchControl.execute("United Nations");
    }

    //]]>
    </script>
    <script language="Javascript" type="text/javascript" src="/myjs.js"></script>
</head>
<body background="$cf->{site_image}" onload="OnLoad()">
<table width=100% align="center">
<tbody>
  <tr><td>
    <table width=90% align="center" cellpadding=2>
        <tbody>
    <tr><td colspan=2 class="blue" align=center>&nbsp;</td></tr>
    <tr align=top>
        <td align=left><a href=/><img src="$cf->{logo}" width="150" height="60" border="0"></a></td>
        <td align=center><a href="$cf->{url_perl}">Main</a> | <a href="http://mail.google.com/a/mplib.org/">Joymail</a> | <a href="$cf->{url_perl}?action=v_blogs_list"> Blogs </a> | <a href="http://criticaltolerance.org"> CT</a> | <a href="http://www.aljazeera.com">Aljazeera</a> | <a href="http://www.dailykos.com">Kos</a> | <a href="http://www.bbc.com">BBC</a> | <a href="http://www.democracynow.org">DemcNow!</a>| <a href=/perl/form.pl><font color=green> Create Account</font></a></td>
    </tr>
    <tr class="menu"><td colspan=2 align=center class="menu2"><span class="$cf->{click}{Profiles}"><a href="$cf->{url_perl}?action=Profiles">Member Profiles</a></span><span class="$cf->{click}{Pics}"><a href="$cf->{url_perl}?action=v_pics_list"> Shared Pics</a></span><span class="$cf->{click}{Blogs}"><a href="$cf->{url_perl}?action=v_top_blogs">New Blogs</a></span><span class="$cf->{click}{CareBox}"><a href="$cf->{url_perl}?action=v_care_list">Care Box</a></span><span class="$cf->{click}{Suggestion}"><a href="$cf->{url_perl}?action=Suggestion">Suggestions</a></span><span class="$cf->{click}{Memes}"><a href="$cf->{url_perl}?action=v_monks_list">Memes: Cookbook for Life</a></span></td></tr>
    </tbody>
        </table>
   </td>
  </tr>
</tbody>
</table>
<!--   START OF INNER BODY TABLE -->
END
}

#  This sub gets session values by user_id, then updates the count, and sets status to in/out

sub my_updateSession { 
my ($ret, $dbh, $r, $view) = @_;

 if($ret) {
     my  $ses = my_dbValue(qq(select * from session where user_id=$ret->{user_id}), $dbh, $r);
      if ( ref($ses) ) {
          if($view == 1) {
               $ses->{counter}++ ;
              my_dbValue(qq(update session set counter=$ses->{counter} where user_id=$ret->{user_id}), $dbh, $r);
          } elsif ($view == 2) {
              
               my_dbValue(qq(update session set stat=1, login=NOW() where user_id=$ret->{user_id}), $dbh, $r );
          } elsif ($view == 3) {
             
               my_dbValue(qq(update session set stat=0  where user_id=$ret->{user_id}), $dbh, $r);
          } else {
            &er_notice("Not value was set for my_updateSession", $r);
          } #> end of checks for counter update or stat update


      } else {
       &er_notice("No ses reference from select * from my_dbValue!", $r);
      }#> end of if ses is a ref check
     
 } else {    
   &er_notice("No ret reference given to my_updateSession call!", $r);
 } #> end of if ret is sent


}#> end of my_updateSession

sub er_notice {
my ($msg, $r)  = @_ ;
system qq{ echo '$msg' | mail -s "Error Notice" ardeshir\@mplib.org } ;
 
 if($? == -1) {
 $r->print( t_box("[ $msg ] please notify the system admin [ bliss at mplib.org ] of this error!") ) ;
 }
}

sub my_email {
my ($ag, $cf, $ret, $r) = @_;
my $msg   = "\n" . "From: $ret->{first} $ret->{last}" . "\n"; 
$msg     .= "\n" . $ag->{body};

system qq( echo '$msg' | mail -s "$ag->{title}" $ag->{to} -c $ret->{email}  );

  if($? == -1) {
    $r->print( t_box("Sorry there was an error please notify the sys admin bliss [at] mplib.org, thanks!") );
  } else {
  $r->print( t_box("<h3 class=dot>Title: $ag->{title}.. was sent to $ag->{to} and CCed to $ret->{email}!<h3>") );
  $r->print( t_box("<div class=dash>link: $ag->{link}<br/></div>") );
  $r->print( t_box("<div class=dash>Image:<p>$ag->{image}</div>") );
  }
}

sub my_request {
my ($ag, $cf, $ret, $r, $dbh) = @_;

$ag->{n_body}  = my_cl($ag->{n_body});
$ag->{n_title} = my_cl($ag->{n_title});
$ag->{n_to}    = my_cl($ag->{n_to});

my $msg   = "\n"   . "Friendship Request from www.mplib.org" . "\n"; 
$msg      = "\n"   . "This is an automated response PLEASE don't *REPLY* to me, I'm just a friendly robot :-)" . "\n";    
$msg     .= "\n\n" . "To view your request click on this link:" . "\n";
$msg     .= "\n"   . "http://www.mplib.org$cf->{url_perl}?action=ck_requests" . "\n";
$msg     .= "\n"   . "or you can login to your joymonk account and click on Check Requests." . "\n";
$msg     .= "\n"   . "From: $ret->{first} $ret->{last}" . "\n";
$msg     .= "\n"   . $ag->{n_body};

system qq( echo '$msg' | mail -s "$ag->{n_title}" $ag->{n_to} );

  if($? == -1) {
  $r->print( t_box("Sorry there was an error please notify the sys admin bliss [at] mplib.org, thanks!") );

  } elsif ($ret->{user_id} == $ag->{uid}) {
  
   $r->print( t_box("You're trying to send a Friendship request to yourself silly!! :-) lets...not") );

  } else {

  $r->print( t_box("Your request was sent to $ag->{fuid} $ag->{luid}! It's pending approval...") );

  my_dbValue( qq( INSERT INTO friends values (DEFAULT, $ret->{user_id}, $ag->{uid}, 1, 1) ) , $dbh, $r );
  my_dbValue( qq( UPDATE session SET note=note + 1 where user_id=$ag->{uid} ), $dbh, $r ) ;

  }


}


sub my_suggestion {
my($ag, $cf, $ret, $r) = @_;

$ag->{body}  = my_cl( $ag->{body} );
$ag->{title} = my_cl($ag->{title} );

my $msg   = "\n" . "The Suggestion Box:" . "\n"; 
$msg     .= "\n" . $ag->{body};

system qq( echo '$msg' | mail -s "$ag->{title}" $cf->{admin_email} );

$r->print( t_box( "Thanks you! Your suggestion: $ag->{title}  has been sent to bliss.") );

  if($? == -1) {
    $r->print( t_box("Sorry there was an error please notify the sys admin bliss [at] mplib.org, thanks!") );
  }
}

sub my_req_box {
my ($ret, $cf) = @_;

return <<"EMAIL";
                         <blockquote>
                         <table width=40% align="center"><tr class="silver">
                         <form action="$cf->{url_perl}" method="post">
                             <td align="left" class="dash"><b>Request frienship:</b>
                             <input type="text" name="n_title" id="n_title" size="34"></td>
                         </tr>
                         <tr>
                             <td  align=left class="dash">
                             <textarea name="n_body" id="n_body" rows="4" cols="48"></textarea></td>
                             <input type="hidden" name="fuid" value="$ret->{first}"> 
                             <input type="hidden" name="luid" value="$ret->{last}">
                             <input type="hidden" name="n_to" value="$ret->{email}">
                             <input type="hidden" name="uid"  value="$ret->{user_id}">
                        </tr>
                         <tr>
                             <td align="left" class="silver"><input type="submit" name="action" value="Request"></td>  
                         </tr></form></table>
                         </blockquote>
            
         
EMAIL
}

sub my_comment_box {
my ($ret, $cf, $im) = @_;

return <<"COMMENT";
                         <blockquote>
                         <table width="40%" align="center"><tr class="silver">
                         <form action="$cf->{url_perl}" method="post">
                             <td align="left" class="dash"><b>Add Comment:</b>
                             <input type="text" name="title" id="title" size="34"></td>
                         </tr>
                         <tr>
                             <td  align="left" class="dash">
                             <textarea name="body" id="body" rows="4" cols="48"></textarea></td>
                             <input type="hidden" name="fuid"  value="$ret->{first}"> 
                             <input type="hidden" name="luid"  value="$ret->{last}">
                             <input type="hidden" name="flag"  value="1">
                             <input type="hidden" name="pid"  value="$im->{pid}">
                             <input type="hidden" name="uid"  value="$ret->{user_id}">
                        </tr>
                         <tr>
                             <td align="left" class="silver"><input type="submit" name="action" value="comment"></td>  
                         </tr></form></table>
                         </blockquote>
            
         
COMMENT
}#> end of comment my_comment_box

sub my_email_box {
my ($ret, $cf, $im) = @_;
my $from = $ret->{email} ? $ret->{email} : $cf->{admin_email};

if( $im ) {
my $image = qq{ <img src=http://www.mplib.org$im->{url}> };
my $link  = qq{ http://www.mplib.org$im->{url} };

return <<"EMAILIMG";
          <div id="my_email_box">
             <form action="$cf->{url_perl}" method="post">
                     <table width="80%" valign="top" align="left" class="dash">
                         <tr align="left">
                            <td align="left"><h3 class="blue">Email This Picture: $im->{descr}</h3></td></tr>
                         <tr align="left">
                             <td align="left">Subject:
                             <input type="text" name="title" id="title" size="22">
                             </td>
                         </tr>
                         <tr align="left">
                            <td align="left">To email:
                            <input type="text" name="to" id="to" size="20">
                           </td>
                         </tr>
                         <tr align="left">
                             <td align="left">From:  $from
                             </td>
                         </tr>
                         <tr align="left">
                               <td align="left">
                                <textarea name="body" id="body" rows="4" cols="65">So...
                                ---
                               $link
                                ---
                               $image
                                </textarea>
                               </td>
                         </tr>
                          <tr> <td>
                               <input type="hidden" name="from"   id="from" value="$from">
                               <input type="hidden" name="link"   id="link" value="$link">
                                <input type="hidden" name="image" id="link" value="$image">
                               </td>
                         </tr>
                         <tr align="left">
                             <td align="left">
                             <input type="submit" name="action" value="Email">
                             </td>
                         </tr>
                     </table>
             </form>
          </div>
EMAILIMG
} else {
return <<"EMAIL";
          <div id="my_email_box">
             <form action="$cf->{url_perl}" method="post">
                     <table width="80%" valign="top" align="left" class="dash">
                         <tr align="left">
                            <td align="left"><h3 class="blue">Email</h3></td></tr>
                         <tr align="left">
                             <td align="left">Subject:
                             <input type="text" name="title" id="title" size="22">
                             </td>
                         </tr>
                         <tr align="left">
                            <td align="left">To email:
                            <input type="text" name="to" id="to" size="20">
                           </td>
                         </tr>
                         <tr align="left">
                             <td align="left">From:  $from
                             </td>
                         </tr>
                         <tr align="left">
                               <td align="left">
                                <textarea name="body" id="body" rows="4" cols="65">So...

                                </textarea>
                               </td>
                         </tr>
                          <tr> <td>
                               <input type="hidden" name="from"   id="from" value="$from">
                               <!-- input type="hidden" name="link"   id="link" value="$link" -->
                                <!-- input type="hidden" name="image" id="link" value="$image" -->
                               </td>
                         </tr>
                         <tr align="left">
                             <td align="left">
                             <input type="submit" name="action" value="Email">
                             </td>
                         </tr>
                     </table>
             </form>
          </div>
EMAIL
}

}#>>>> end of my_email_box

sub v_suggestion_box {
my ($ag, $cf, $ret, $r) = @_;
return <<"EMAIL";
          <div id="my_suggestion_box">
             <form action="$cf->{url_perl}" method="get">
                     <table width="60%" align="left" class="dash">
                         <tr align="left">
                             <td align="left"><h2 class="blue">Suggestion Box</h2></td>
                         </tr>
                         <tr>
                             <td align="left">Subject: <input type="text" name="title" id="title" size="22"></td>
                         </tr>
                         <tr align="left">
                             <td align="left"><textarea name="body" id="body" rows="4" cols="65"> </textarea></td>
                         </tr>
                         <tr>
                             <td align="left"><input type="submit" name="action" value="Joythinks"></td>
                         </tr>
                     </table>
             </form>
          </div>
EMAIL
}
####################################################################
#
#                   MAIN ADMIN PAGE BOXES AND SMALL PROFILE
#
#
####################################################################

sub my_box {
my ($ret, $cf) = @_;

my $width = $_[2] ? $_[2] : 120;

foreach (sort keys %$ret){

if($_ eq 'image') {
   if( $ret->{image} eq "0") {   
    $ret->{image} = qq(<img src="http://www.mplib.org/images/joymonk.jpg" alt=Smile width="$width"> );
   } else {
    $ret->{image}   = '<img src="' . $ret->{$_} . '" align=center alt=Nice Smile! width="'. $width .'" border="0">';
   }
}
        $ret->{alias}  =  $ret->{$_}  if $_ =~ /alias/;
    $ret->{gender}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /gender/;
      $ret->{sexual}  = uc($_) . ' ' . '</b> &hearts;' . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sexual/;
    $ret->{city}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /city/;
        $ret->{sign}  =  ' &hearts;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sign/;
    $ret->{zip}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /zip/;         
    $ret->{email} = '<a href=mailto:'. $ret->{$_} . '>'  . $ret->{$_} . '</a>' if $_ eq 'email';
   
}
   
my $box = <<"BOX";
<table width=90% align=center valign=top>
<tr align=center><td><a href=/admin?action=$ret->{extra_id}&auth=$ret->{user_id}>$ret->{image}</a></td></tr>
<tr align=center><td>$ret->{alias}</td></tr>
</table>
BOX

}

sub my_friends_box {
my ($ret, $cf, $friends) = @_;

my $width = $_[3] ? $_[3] : 80;

foreach (sort keys %$ret){

if($_ eq 'image') {
   if( $ret->{image} eq "0") {   
    $ret->{image} = qq(<img src="http://www.mplib.org/images/joymonk.jpg" alt=Smile width="$width"> );
   } else {
    $ret->{image}   = '<img src="' . $ret->{$_} . '" align=center alt=Nice Smile! width="'. $width .'" border="0">';
   }
}
        $ret->{alias}  =  $ret->{$_}  if $_ =~ /alias/;
    $ret->{gender}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /gender/;
      $ret->{sexual}  = uc($_) . ' ' . '</b> &hearts;' . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sexual/;
    $ret->{city}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /city/;
        $ret->{sign}  =  ' &hearts;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sign/;
    $ret->{zip}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /zip/;         
    $ret->{email} = '<a href=mailto:'. $ret->{$_} . '>'  . $ret->{$_} . '</a>' if $_ eq 'email';
   
}
   
my $box = <<"BOX";
<table width=90% align=center valign=top>
<tr align=center><td><a href=/admin?action=$ret->{extra_id}&auth=$ret->{user_id}>$ret->{image}</a></td></tr>
<tr align=center><td>$ret->{alias}</td></tr>
</table>
BOX

my $frn_box = <<"FRNBOX";
<td class="double" align="center"><a href=/admin?action=$ret->{extra_id}&auth=$ret->{user_id}>$ret->{image}</a></br>
<b>$ret->{alias}</b></td>
FRNBOX

 if ($friends){  return $frn_box;}
 else         {  return $box; }

}

sub check_request_box {
my ($ret, $cf) = @_;

my $width = $_[1] ? $_[1] : 80;

foreach (sort keys %$ret){

if($_ eq 'image') {
   if( $ret->{image} eq "0") {   
    $ret->{image} = qq(<img src="http://www.mplib.org/images/joymonk.jpg" alt=Smile width="$width"> );
   } else {
    $ret->{image}   = '<img src="' . $ret->{$_} . '" align=center alt=Nice Smile! width="'. $width .'" border="0">';
   }
}
        $ret->{alias}  =  $ret->{$_}  if $_ =~ /alias/;
    $ret->{gender}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /gender/;
      $ret->{sexual}  = uc($_) . ' ' . '</b> &hearts;' . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sexual/;
    $ret->{city}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /city/;
        $ret->{sign}  =  ' &hearts;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sign/;
    $ret->{zip}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /zip/;         
    $ret->{email} = '<a href=mailto:'. $ret->{$_} . '>'  . $ret->{$_} . '</a>' if $_ eq 'email';
   
}
   
my $box = <<"BOX";
<table>
<tr align="center">
<td class="rightdot"><a href=/admin?action=$ret->{extra_id}&auth=$ret->{user_id}>$ret->{image}</a></td>
<td>
<form action="/admin" method="post">
<input type="radio" name="verdict" value="Accept"> Accept
<input type="radio" name="verdict" value="Decline">Decline
<input type="radio" name="verdict" value="Block"> Block

<input type="hidden"  name="uid"   value="$ret->{user_id}">
<input type="hidden"  name="alias" value="$ret->{alias}">

<input type="submit"  name="action" value="Verdict">   
</form>
</td>
</tr>
<tr><td align="left">$ret->{alias}  $ret->{sign}</td></tr>
</table>
BOX

}


sub check_all_requests_box {
my ($ret, $cf) = @_;

my $width = $_[1] ? $_[1] : 80;

foreach (sort keys %$ret){

if($_ eq 'image') {
   if( $ret->{image} eq "0") {   
    $ret->{image} = qq(<img src="http://www.mplib.org/images/joymonk.jpg" alt=Smile width="$width"> );
   } else {
    $ret->{image}   = '<img src="' . $ret->{$_} . '" align=center alt=Nice Smile! width="'. $width .'" border="0">';
   }
}
        $ret->{alias}  =  $ret->{$_}  if $_ =~ /alias/;
    $ret->{gender}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /gender/;
      $ret->{sexual}  = uc($_) . ' ' . '</b> &hearts;' . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sexual/;
    $ret->{city}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /city/;
        $ret->{sign}  =  ' &hearts;'  . ' ' . $ret->{$_}  if $_ =~ /sign/;
    $ret->{zip}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /zip/;         
    $ret->{email} = '<a href=mailto:'. $ret->{$_} . '>'  . $ret->{$_} . '</a>' if $_ eq 'email';
   
}
   
my $box = <<"BOX";
<table class="dot">
<tr align="center">
<td class="rightdot"><a href=/admin?action=$ret->{extra_id}&auth=$ret->{user_id}&alias=$ret->{alias}>$ret->{image}</a></td>
<td>
<blockquote>
<div><a href="$cf->{url_perl}/admin?action=new_request_ck&uid=$ret->{user_id}"> $ret->{alias}<br/><br/>
$ret->{gender}
$ret->{sexual}
$ret->{city}</a>
</div>
</blockquote>
</td>
</tr>
<tr><td align="left">$ret->{sign}</td></tr>
</table>
BOX

}

sub check_all_comments_box {
my ($ret, $cf, $com) = @_;

my $width = $_[3] ? $_[3] : 80;

foreach (sort keys %$ret){

if($_ eq 'image') {
   if( $ret->{image} eq "0") {   
    $ret->{image} = qq(<img src="http://www.mplib.org/images/joymonk.jpg" alt=Smile width="$width"> );
   } else {
    $ret->{image}   = '<img src="' . $ret->{$_} . '" align=center alt=Nice Smile! width="'. $width .'" border="0">';
   }
}
        $ret->{alias}  =  $ret->{$_}  if $_ =~ /alias/;
    $ret->{gender}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /gender/;
      $ret->{sexual}  = uc($_) . ' ' . '</b> &hearts;' . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sexual/;
    $ret->{city}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /city/;
        $ret->{sign}  =  ' &hearts;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sign/;
    $ret->{zip}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /zip/;         
    $ret->{email} = '<a href=mailto:'. $ret->{$_} . '>'  . $ret->{$_} . '</a>' if $_ eq 'email';
   
}


$com->{time} =~ s/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\.\d{5,6}$/$1 /g;
   
my $box = <<"BOX";
<table>
<tr align="center" class="dot">
<td class="rightdot"><a href=/admin?action=$ret->{extra_id}&auth=$ret->{user_id}>$ret->{image}</a></td>
<td><b>
Time: $com->{time} | Title: $com->{title}<br/>
<blockquote>
<div><a href="$cf->{url_perl}/admin?action=comment_ck&com_id=$com->{com_id}">$com->{body}</a></div>
</blockquote></b><br/>
</td>
</tr>
<tr><td align="left">$ret->{alias}  $ret->{sign}</td></tr>
</table>

BOX

}

sub check_comment_box {
my ($ret, $cf, $com) = @_;

my $width = $_[3] ? $_[3] : 80;

foreach (sort keys %$ret){

if($_ eq 'image') {
   if( $ret->{image} eq "0") {   
    $ret->{image} = qq(<img src="http://www.mplib.org/images/joymonk.jpg" alt=Smile width="$width"> );
   } else {
    $ret->{image}   = '<img src="' . $ret->{$_} . '" align=center alt=Nice Smile! width="'. $width .'" border="0">';
   }
}
        $ret->{alias}  =  $ret->{$_}  if $_ =~ /alias/;
    $ret->{gender}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /gender/;
      $ret->{sexual}  = uc($_) . ' ' . '</b> &hearts;' . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sexual/;
    $ret->{city}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /city/;
        $ret->{sign}  =  ' &hearts;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sign/;
    $ret->{zip}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /zip/;         
    $ret->{email} = '<a href=mailto:'. $ret->{$_} . '>'  . $ret->{$_} . '</a>' if $_ eq 'email';
   
}


$com->{time} =~ s/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\.\d{5,6}$/$1 /g;
   
my $box = <<"BOX";
<table>
<tr align="center" class="dot">
<td class="rightdot"><a href=/admin?action=$ret->{extra_id}&auth=$ret->{user_id}>$ret->{image}</a></td>
<td><b>
Time: $com->{time} | Title: $com->{title}<br/>

<div>$com->{body}<br/></div></b>
<form action="/admin" method="post">
<input type="radio" name="verdict" value="Accept"> Accept
<input type="radio" name="verdict" value="Decline">Decline
<input type="hidden"  name="uid"    value="$ret->{user_id}">
<input type="hidden"  name="alias"  value="$ret->{alias}">
<input type="hidden"  name="com_id" value="$com->{com_id}">
<input type="submit"  name="action" value="Commit">   
</form>
</td>
</tr>
<tr><td align="left">$ret->{alias}  $ret->{sign}</td></tr>
</table>
BOX

}

sub cl_time { # takes the PostgreSQL time and shaves the ending seconds off.
my $time = shift;
 $time =~ s/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\.\d{5,6}$/$1 /g;
return $time;
}

sub my_linksBox {
my ($ag, $cf, $ret, $r) = @_;
foreach (sort keys %$ret){

if($_ eq 'image') {
   if( $ret->{image} eq "0") {   
    $ret->{image} = '<img src="http://www.mplib.org/images/joymonk.jpg" valign=top align=left alt=Smile width=80>';
   } else {
    $ret->{image}   = '<img src="' . $ret->{$_} . '" valign=top align=center alt="Nice Smile!" width=80 border=0>';
   }
}

        next unless $ret->{$_};

        $ret->{alias}  =  $ret->{$_}  if $_ =~ /alias/;
    $ret->{gender}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /gender/;
      $ret->{sexual}  = uc($_) . ' ' . '</b> &hearts;' . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sexual/;
    $ret->{city}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /city/;
        $ret->{sign}  =  ' &hearts;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sign/;
    $ret->{zip}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /zip/;         
    $ret->{email} = '<a href=mailto:'. $ret->{$_} . '>'  . $ret->{$_} . '</a>' if $_ eq 'email';
   
}

my $count = $cf->{tbl}{counter}[0];
my ($new_joyfriend, $new_comment) = undef;

my $ck = my_dbValue("SELECT note, comment from session where user_id=$ret->{user_id}", my_dbh($cf), $r);
if ($ck->{note} >= 1 ) {
$new_joyfriend = qq|<a href="$cf->{url_perl}?action=ck_requests" class="menu"><img src="$cf->{logo}" width="30" border="0">You have a new friend request to approve! ( $ck->{note} )</a>|;
}
if ($ck->{comment} >= 1) {
$new_comment = qq|<a href="$cf->{url_perl}?action=ck_comments"><img src="/images/star.gif" border="0"> Sweet, you have new comments to approve! ( $ck->{comment} )</a>|;
}
   
$ret->{date} =~ s/^(\d{4}-\d{2}-\d{2}) .*$/$1 /g;

my $time = scalar localtime;
my $acts1 = &my_linksOne($cf, $ag);   
my $acts2 = &my_linksTwo($cf, $ag);   
my $welcome = qq(<h3>Welcome $ret->{first} $ret->{last} | It's $time | <a href=/logout>  Sign out </a></h3>);

my $box = <<"BOX";
<table width=90% align=center class="double">
<tr valign="top" align=left>
<td colspan="3"  valign="top" align="left"> $welcome </td></tr>
<tr valign="top" align="left">
<td valign="top" align="left" class="rightdot"> $ret->{image} <P><b>Member  Since: $ret->{date} <br/>
                                                                  Profile Views: $count      <P>
                                                      
                                                                    $new_comment</b><br/>$new_joyfriend
                                                                                    </td>
<td valign="top" align="left" class="rightdot">$acts1</td>
<td valign="top" align="left">$acts2</td>
</td>
<!-- td valign="top" align="left" class="rightdot" -->
 </td>
</tr>
</table>
BOX

}


sub my_blog_box {
my ($ret , $dbh ) = @_;
foreach (sort keys %$ret){

    if ($_ =~ /time/ ) { $ret->{time} =~ s/^(\d{4}-\d{2}-\d{2}) .*$/Date: $1 /g; }
     
    $ret->{title}  = ' ' . '&clubs;'  . ' ' . $ret->{$_}  if $_ =~ /title/;
      $ret->{flag}   = 'Permission to view: <font color=green> ' . $ret->{$_} . ' ' . '</font>' if $_ =~ /flag/;
    $ret->{category}  = ' ' . $ret->{$_} . ' '  if $_ =~ /category/;
        $ret->{stat}  =     ' ' . $ret->{$_} . ' '  if $_ =~ /stat/;
    $ret->{body}  =   CGI::escapeHTML( $ret->{$_} )  if $_ =~ /body/;         
   
   
}
$ret->{body} =~ s#\012|\015|\012\015|\n#<p>#g;

   
my $box = <<"BOX";
<tr><td valign=top class="silver">$ret->{time} | Title  $ret->{title} | Category: $ret->{category} | $ret->{stat} | $ret->{flag}</td></tr>
<tr><td colspan=4><div class="blog"><BOCKQUOTE>$ret->{body}</BLOCKQUOTE></div></td></tr>
<tr><td colspan=2><div class="dot"><a href="/admin?action=edit_blog&bid=$ret->{blog_id}"> Edit </a> |
<a href="/admin?action=delete_blog&bid=$ret->{blog_id}">  Delete </a></div></td>
</tr>
BOX

}

sub v_pics_list_box {
my $cf = shift;
foreach (sort keys %$cf){

    #if ($_ =~ /time/ ) { $cf->{time} =~ s/^(\d{4}-\d{2}-\d{2}) .*$/Date: $1 /g; }
     
    $cf->{descr}  = ' ' . '&clubs;'  . ' ' . $cf->{$_}  if $_ =~ /descr/;
      $cf->{flag}   = 'View by: <font color=green> ' . $cf->{$_} . ' ' . '</font>' if $_ =~ /flag/;
    #$cf->{category}  = ' ' . $cf->{$_} . ' '  if $_ =~ /category/;
        $cf->{url}  =     ' ' . $cf->{$_} . ' '  if $_ =~ /url/;
    #$cf->{body}  =   CGI::escapeHTML( $cf->{$_} )  if $_ =~ /body/;         
   
   
}

#$cf->{body} =~ s#\012|\015|\012\015|\n#<p>#g;
   
my $box = <<"BOX";
<table width=90% align=center class="double">
<tr><td valign=top class="silver">$cf->{descr} </td></tr>
<tr><td align=center><a href="/admin?action=1&auth=$cf->{user_id}"><img src="$cf->{url}" alt="$cf->{user_id}" width="90" border="0"></a></td></tr>
<tr><td colspan=2 align=center>
<div class="dot"><a href="/admin?action=v_email_pic&pid=$cf->{im_id}"> email </a> | 
<a href="/admin?action=v_comment_pic&pid=$cf->{im_id}">  comment </a> | <a href="/admin?action=v_quips_pic&pid=$cf->{im_id}"> quips</a></div></td>
</tr>
</table>
BOX
}


sub v_pics_box {
my $cf = shift;
foreach (sort keys %$cf){

    #if ($_ =~ /time/ ) { $cf->{time} =~ s/^(\d{4}-\d{2}-\d{2}) .*$/Date: $1 /g; }
     
    $cf->{descr}  = ' ' . '&clubs;'  . ' ' . $cf->{$_}  if $_ =~ /descr/;
      $cf->{flag}   = 'View by: <font color=green> ' . $cf->{$_} . ' ' . '</font>' if $_ =~ /flag/;
    #$cf->{category}  = ' ' . $cf->{$_} . ' '  if $_ =~ /category/;
        $cf->{url}  =     ' ' . $cf->{$_} . ' '  if $_ =~ /url/;
    #$cf->{body}  =   CGI::escapeHTML( $cf->{$_} )  if $_ =~ /body/;         
   
   
}

#$cf->{body} =~ s#\012|\015|\012\015|\n#<p>#g;
   
my $box = <<"BOX";
<table width=90% align=center class="double">
<tr><td align=center valign=top class="silver">$cf->{descr} </td></tr>
<tr><td align=center><a href="/admin?action=v_pic&pid=$cf->{im_id}"><img src="$cf->{url}" alt="$cf->{user_id}" width="150" border="0"></a></td></tr>
<tr><td align=center colspan=2>
<div class="dot"><a href="/admin?action=v_email_pic&pid=$cf->{im_id}">  email </a> |
<a href="/admin?action=v_comment_pic&pid=$cf->{im_id}">  comment </a>| <a href="/admin?action=v_quips_pic&pid=$cf->{im_id}"> quips</a></div></td>
</tr>
</table>
BOX
}

sub my_pics_box {
my $cf = shift;

foreach (sort keys %$cf){

    #if ($_ =~ /time/ ) { $cf->{time} =~ s/^(\d{4}-\d{2}-\d{2}) .*$/Date: $1 /g; }
     
    $cf->{descr}  = ' ' . '&clubs;'  . ' ' . $cf->{$_}  if $_ =~ /descr/;
      #$cf->{flag}   = 'View by: <font color=green> ' . $cf->{$_} . ' ' . '</font>' if $_ =~ /flag/;
    #$cf->{category}  = ' ' . $cf->{$_} . ' '  if $_ =~ /category/;
        $cf->{url}  =     ' ' . $cf->{$_} . ' '  if $_ =~ /url/;
    #$cf->{body}  =   CGI::escapeHTML( $cf->{$_} )  if $_ =~ /body/;         
    #$cf->{body} =~ s#\012|\015|\012\015|\n#<p>#g;
   if ( $_  =~ /flag/ ) {
       if ($cf->{$_} eq 'All' ) {
        $cf->{flag} = 'Private';
       } else {   
        $cf->{flag} = 'All';
      }
   }   
}


my $box = <<"BOX";
<table width=90% align=center class="double">
<tr><td align=center valign=top class="silver">$cf->{descr} </td></tr>
<tr><td align=center>
<a href="/admin?action=v_pic&pid=$cf->{im_id}"><img src="$cf->{url}" alt="$cf->{user_id}" width="150" border="0"></a></td>
</tr><tr><td align=center colspan=2>
<div class="dot">Make <a href="/admin?action=my_icon&pid=$cf->{im_id}">  Icon </a>|
<a href="/admin?action=$cf->{flag}&pid=$cf->{im_id}"> $cf->{flag} </a>|<a href="/admin?action=my_email_pic&pid=$cf->{im_id}">  email  </a></div></td>
</tr>
</table>
BOX
}

sub v_pic_box {
my ($ret, $cf, $w, $comment, $quips ) = @_;
foreach (sort keys %$ret){

    #if ($_ =~ /time/ ) { $ret->{time} =~ s/^(\d{4}-\d{2}-\d{2}) .*$/Date: $1 /g; }
     
    $ret->{descr}  = ' ' . '&clubs;'  . ' ' . $ret->{$_}  if $_ =~ /descr/;
      $ret->{flag}   = 'View by: <font color=green> ' . $ret->{$_} . ' ' . '</font>' if $_ =~ /flag/;
    #$ret->{category}  = ' ' . $ret->{$_} . ' '  if $_ =~ /category/;
        $ret->{url}  =     ' ' . $ret->{$_} . ' '  if $_ =~ /url/;
    #$ret->{body}  =   CGI::escapeHTML( $ret->{$_} )  if $_ =~ /body/;         
   
   
}

#$cf->{body} =~ s#\012|\015|\012\015|\n#<p>#g;

my $width = $w ? $w : 600;

   
my $box = <<"BOX";
<table  width="90%" align="center" class="double">
<tr><td valign="top" class="silver">$ret->{descr} </td></tr>
<tr><td><a href="/admin?action=1&auth=$ret->{user_id}"><img src="$ret->{url}" alt="$ret->{flag}" width="$width" border="0"></a>
</td></tr>
<tr><td colspan="2">
<div class="dot"><a href="$cf->{url_perl}?action=v_email_pic&pid=$ret->{im_id}">  email </a> |
 <a href="$cf->{url_perl}?action=v_comment_pic&pid=$ret->{im_id}"> comment </a>| <a href="/admin?action=v_quips_pic&pid=$ret->{im_id}"> quips</a></div></td>
</tr>
</table>
BOX

my $boxcom = <<"BOXCOM";
<table  width="90%" align="center" class="double">
<tr><td valign="top" class="silver">$ret->{descr}</td></tr>
<tr><td><a href="/admin?action=1&auth=$ret->{user_id}"><img src="$ret->{url}" alt="$ret->{flag}" width="$width" border="0"></a></td><td>$comment</td>
</tr>
</table>
BOXCOM

my $boxquips = <<"BOXQUIPS";
<table  width="90%" align="center" class="double">
<tr><td valign="top" class="silver">$ret->{descr}</td></tr>
<tr><td><a href="/admin?action=1&auth=$ret->{user_id}"><img src="$ret->{url}" alt="$ret->{flag}" width="$width" border="0"></a></td></tr>
<tr><td>$quips</td>
</tr>
</table>
BOXQUIPS


if ($comment) { return $boxcom; }
elsif ($quips ) { return $boxquips;}
else          { return $box;  }

}


sub v_blogs_box {
my ($ret, $dbh) = @_;

foreach (sort keys %$ret){

    if ($_ =~ /time/ ) { $ret->{time} =~ s/^(\d{4}-\d{2}-\d{2}) .*$/Date: $1 /g; }
     
    $ret->{title}  = ' ' . '&clubs;'  . ' ' . $ret->{$_}  if $_ =~ /title/;
      $ret->{flag}   = 'View by: <font color=green> ' . $ret->{$_} . ' ' . '</font>' if $_ =~ /flag/;
    $ret->{category}  = ' ' . $ret->{$_} . ' '  if $_ =~ /category/;
        $ret->{stat}  =     ' ' . $ret->{$_} . ' '  if $_ =~ /stat/;
    $ret->{body}  =   CGI::escapeHTML( $ret->{$_} )  if $_ =~ /body/;         
   
   
}

$ret->{body} =~ s#\012|\015|\012\015|\n#<p>#g;
my $author = my_dbValue("select *  from profile where user_id=$ret->{user_id}", $dbh);   
my $img    = my_dbValue("select url from images where user_id=$ret->{user_id} and flag='All'", $dbh);

my $box = <<"BOX";
<tr><td valign=top class="silver">$ret->{time} | Title  $ret->{title} | Author: <a href="/admin?action=v_blogs&auth=$ret->{user_id}">$author->{alias}</a> | Category: $ret->{category} | $ret->{flag}</td></tr>
<tr><td colspan=4><div class="blog"><BLOCKQUOTE><a href="/admin?action=v_pics&auth=$ret->{user_id}">
<img src="$img->{url}" width="60" border="0"></a><p>$ret->{body}</BLOCKQUOTE></div></td></tr>
<tr><td colspan=2><div class="dot"><a href="/admin?action=v_email_blog&bid=$ret->{blog_id}"> email </a> |
<a href="/admin?action=v_comment_blog&bid=$ret->{blog_id}"> comment </a></div></td>
</tr>
BOX

}

sub v_blog_box {
my ($ret, $dbh) = @_;

foreach (sort keys %$ret){

    if ($_ =~ /time/ ) { $ret->{time} =~ s/^(\d{4}-\d{2}-\d{2}) .*$/Date: $1 /g; }
     
    $ret->{title}  = ' ' . '&clubs;'  . ' ' . $ret->{$_}  if $_ =~ /title/;
      $ret->{flag}   = 'View by: <font color=green> ' . $ret->{$_} . ' ' . '</font>' if $_ =~ /flag/;
    $ret->{category}  = ' ' . $ret->{$_} . ' '  if $_ =~ /category/;
        $ret->{stat}  =     ' ' . $ret->{$_} . ' '  if $_ =~ /stat/;
    $ret->{body}  =   CGI::escapeHTML( $ret->{$_} )  if $_ =~ /body/;         
   
   
}

$ret->{body} =~ s#\012|\015|\012\015|\n#<p>#g;

my $author = my_dbValue("select * from profile where user_id=$ret->{user_id}", $dbh);
my $img    = my_dbValue("select url from images where user_id=$ret->{user_id} and flag='All'", $dbh);
   
my $box = <<"BOX";
<table width=90% align=center>
<tr><td valign=top class="silver">$ret->{time} | Title  $ret->{title} | Author: <a href="/admin?action=v_blogs&auth=$ret->{user_id}">$author->{alias}</a> | Category: $ret->{category} | $ret->{flag}</td></tr>
<tr><td colspan=4><div class="blog"><BLOCKQUOTE>
<a href="/admin?action=v_pics&auth=$ret->{user_id}"><img src="$img->{url}" border="0" width="60"></a><P>$ret->{body}</BLOCKQUOTE></div></td></tr>
<tr><td colspan=2><div class="dot"><a href="/admin?action=v_email_blog&bid=$ret->{blog_id}">  email  </a> |
<a href="/admin?action=v_comment_blog&bid=$ret->{blog_id}">  comment </a></div></td>
</tr></table>
BOX

}

sub v_blogs_list_box {
my ($ret, $dbh ) = @_;

foreach (sort keys %$ret){

    if ($_ =~ /time/ ) { $ret->{time} =~ s/^(\d{4}-\d{2}-\d{2}) .*$/Date: $1 /g; }
     
    #$ret->{user_id}  = ' ' . '&clubs;'  . ' ' . $ret->{$_}  if $_ =~ /user_id/;
      #$ret->{flag}   = 'View by: <font color=green> ' . $ret->{$_} . ' ' . '</font>' if $_ =~ /flag/;
    $ret->{category}  = ' ' . $ret->{$_} . ' '  if $_ =~ /category/;
        $ret->{title}  =     ' ' . $ret->{$_} . ' '  if $_ =~ /title/;
    #$ret->{body}  =   CGI::escapeHTML( $ret->{$_} )  if $_ =~ /body/;         
   
   
}

my $author = my_dbValue("select alias from profile where user_id=$ret->{user_id}", $dbh );

$ret->{body} =~ s#\012|\015|\012\015|\n#<p>#g;
my $box = <<"BOX";
<tr><td valign=top class="blog">
$ret->{time} | Category: <font color=green>$ret->{category}</font> | <a href="/admin?action=v_blog&bid=$ret->{blog_id}"> $ret->{title}</a> | Author: <a href="/admin?action=v_blogs&auth=$ret->{user_id}">$author->{alias}</a></td></tr>
BOX

}

sub my_search_box {
my ($ret, $hs, $arg) = @_;
foreach (sort keys %$ret){

if($_ eq 'image') {
  if ($ret->{image} eq "0" ) {
   $ret->{image} = '<img src="http://www.mplib.org/images/joymonk.jpg" align=left alt=Smile width=150>';
  } else {
   $ret->{image}   = '<img src="' . $ret->{$_} . '" align=left alt="Nice Smile!" width="150" border="0">';
 }
}

        next unless $ret->{$_};

        $ret->{first}  =  uc($_) . '' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /first/;
    $ret->{last}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /last/;
    $ret->{height}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /height/;
    $ret->{body}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /body/;
    $ret->{aim}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /aim/;
    $ret->{religion}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /religion/;
    $ret->{education}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /education/;
        $ret->{income}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /income/;
      $ret->{sexual}  = uc($_) . ' ' . '</b> &hearts;' . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sexual/;
    $ret->{city}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /city/;
        $ret->{sign}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sign/;
    $ret->{zip}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /zip/;         
    $ret->{email} = '<a href=mailto:'. $ret->{$_} . '>'  . $ret->{$_} . '</a>' if $_ eq 'email';
   
}


$ret->{date} =~ s/^(\d{4}-\d{2}-\d{2}) .*$/$1 /g;
$hs->{tbl}{login}[0] =~ s/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\.\d{5,6}$/$1 /g;
 
my $acts1 = &my_actsOne($ret, $hs);   
my $acts2 = &my_actsTwo($ret, $hs);
my $box = <<"BOX";
<table width=90% align="center">
<tr valign="top" align="center">
<td valign="top" align="left">     $ret->{image}
                                   <P>Member Since: $ret->{date} <br/>
                                   Last Sign in:  $hs->{tbl}{login}[0]  <br/>
                                   $ret->{email}</b><p>
                                   Profile Views: $hs->{tbl}{counter}[0]
                                                     </td>
<td valign="top" align="left" class="rightdot"> $acts1 $acts2 </td>
<td valign="top" align="left">$ret->{first} $ret->{last} $ret->{height} $ret->{body}$ret->{aim} $ret->{religion}</td>
<td valign="top" align="left">$ret->{education} $ret->{income} $ret->{sexual} $ret->{city} $ret->{sign} $ret->{zip}</td>
</tr>
</table>
BOX

}

sub my_dispatch {

my ($ag, $cf, $ret, $r, $dbh) = @_;

if    ($ag->{action} eq 'edit'      ) {   &edit($ag, $cf, $ret, $r);        }
elsif ($ag->{action} eq 'my_v_blogs') {   &my_v_blogs($ag,$cf, $ret, $r);      }
elsif ($ag->{action} eq 'edit_blog')  {    &edit_blog($ag,$cf, $ret, $r);      }
elsif ($ag->{action} eq 'images'    ) {   &my_images($ag, $cf, $ret, $r);      }
elsif ($ag->{action} eq 'my_v_pics' ) {   &my_v_pics($ag, $cf, $ret, $r);      }
elsif ($ag->{action} eq 'media')  {       &my_media($ag, $cf, $ret, $r);       }
elsif ($ag->{action} eq 'cancel') {       &my_cancel($ag, $cf, $ret, $r);      }
elsif ($ag->{action} eq 'blog')   {       &my_blog($ag, $cf, $ret, $r);        }
elsif ($ag->{action} eq 'style')  {       &my_style($ag, $cf, $ret, $r);       }
elsif ($ag->{action} eq 'my_icon'){       &my_icon($ag, $cf, $ret, $r);        }
elsif ($ag->{action} eq 'Private'){       &my_im_private($ag, $cf, $ret, $r);  }
elsif ($ag->{action} eq 'All')    {       &my_im_all($ag, $cf, $ret, $r);      }
elsif ($ag->{action} eq 'Email') {        &my_email($ag, $cf, $ret, $r);      }
elsif ($ag->{action} eq 'mk_req') {       &my_req_req($ag, $cf, $ret, $r);     }
elsif ($ag->{action} eq 'Request'){       &my_request($ag, $cf, $ret, $r, $dbh);  }
elsif ($ag->{action} eq 'ck_requests') {  &ck_requests($ag, $cf, $ret, $r, $dbh); }
elsif ($ag->{action} eq 'my_requests'){   &my_requests($ag, $cf, $ret, $r, $dbh); }
elsif ($ag->{action} eq 'Verdict'){       &my_request_verdict($ag, $cf, $ret, $r, $dbh);}
elsif ($ag->{action} eq 'new_request_ck'){&new_request_ck($ag, $cf, $ret, $r, $dbh);}
elsif ($ag->{action} eq 'edit_blog'){     &my_edit_blog($ag, $cf, $ret, $r, $dbh); }
elsif ($ag->{action} eq 'delete_blog'){   &my_delete_blog($ag,$cf, $ret, $r ); }
elsif ($ag->{action} eq 'joyfriends') {   &my_friends($ag, $cf, $ret, $r);     }
elsif ($ag->{action} eq 'comment')     {  &my_add_comment($ag, $cf, $ret, $r);}
elsif ($ag->{action} eq 'ck_comments') {  &ck_comments($ag, $cf, $ret, $r, $dbh); }
elsif ($ag->{action} eq 'comment_ck') {  &comment_ck($ag, $cf, $ret, $r, $dbh); }
elsif ($ag->{action} eq 'Commit'){        &my_comment_verdict($ag, $cf, $ret, $r, $dbh);}
elsif ($ag->{action} eq 'v_comment_pic') { &v_comment_pic($ag, $cf, $ret, $r); }
elsif ($ag->{action} eq 'v_email_pic')  { &v_email_pic($ag, $cf, $ret, $r); }
elsif ($ag->{action} eq 'my_email_pic') { &v_email_pic($ag, $cf, $ret, $r); }
elsif ($ag->{action} eq 'v_quips_pic') { &v_quips_pic($ag, $cf, $ret, $r); }
elsif ($ag->{action} eq 'my_quips')    { &my_quips($ag, $cf, $ret, $r); }
elsif ($ag->{action} eq 'save_pwd')       { &save_pwd($ag, $cf, $ret, $r); }
else {  }
}

sub v_dispatch {

my ($ag, $cf, $ret, $r, $qp) = @_;

if    ($ag->{action} eq 'v_pics') {  &v_pics($ag, $cf, $ret, $r);            }
elsif ($ag->{action} eq 'v_pic')  {  &v_pic($ag, $cf, $ret, $r);             }
elsif ($ag->{action} eq 'v_pics_list')  {  &v_pics_list($ag, $cf, $ret, $r); }
elsif ($ag->{action} eq 'v_prof') {  &v_prof($ag, $cf, $ret, $r);            }
elsif ($ag->{action} eq 'v_blogs'){  &v_blogs($ag, $cf, $ret, $r);           }
elsif ($ag->{action} eq 'v_blogs_list'){  &v_blogs_list($ag, $cf, $ret, $r); }
elsif ($ag->{action} eq 'v_blog'){   &v_blog($ag, $cf, $ret, $r);            }
elsif ($ag->{action} eq 'v_media'){  &v_media($ag, $cf, $ret, $r);           }
elsif ($ag->{action} eq 'Profiles'){ &v_profiles($ag, $cf, $ret, $r);        }
elsif ($ag->{action} eq 'v_top_blogs'){ &v_top_blogs($ag, $cf, $ret, $r);    }
elsif ($ag->{action} eq 'v_friends') {  &v_friends($ag, $cf, $ret, $r);   }
elsif ($ag->{action} eq 'Suggestion')    { &v_mk_suggestion($ag, $cf, $ret, $r); }
elsif ($ag->{action} eq 'Joythinks')    { &my_suggestion($ag, $cf, $ret, $r); }
else {  }
}

sub my_add_comment {
my ($ag, $cf, $ret, $r, $dbh) = @_;
my $img_uid;
my $com;

   if($ag){

       $img_uid = my_dbValue("SELECT user_id from images where im_id=$ag->{pid}", my_dbh($cf), $r);

     if( ref($img_uid) ) {
     
       $com = my_dbValue("SELECT * from profile where user_id=$img_uid->{user_id}", my_dbh($cf), $r);
       $ag->{title} = my_cl($ag->{title});
       $ag->{body} =  my_cl($ag->{body});

       my $msg   = "\n"   . "Picture Comment Approval: mplib.org" . "\n"; 
       $msg      = "\n"   . "This is an automated response PLEASE don't *REPLY* to me, I'm just a friendly robot :-)" . "\n";  
       $msg     .= "\n\n" . "To view your picture comment click on this link:" . "\n";
       $msg     .= "\n"   . "http://www.mplib.org$cf->{url_perl}?action=ck_comments" . "\n";
       $msg     .= "\n"   . "or you can login to your joymonk account and click on Check Comments." . "\n";
       $msg     .= "\n"   . "From: $ret->{first} $ret->{last}" . "\n";
       $msg     .= "\n"   . $ag->{body};

       system qq( echo '$msg' | mail -s "$ag->{title}" $com->{email} );

         if($? == -1) {
          $r->print( t_box("Sorry there was an error please notify the sys admin bliss [at] mplib.org, thanks!") );


          } else {  #> system call did not fail

          $r->print( t_box("<h2>Your Comment was sent to $com->{first} $com->{last}! It's pending approval...</h2>") );
        my $SPACE = q{ };
        $ag->{title} =~ s/'/$SPACE/g;
        $ag->{body}  =~ s/'/$SPACE/g;
         my_dbValue( "INSERT INTO comments VALUES (DEFAULT, NOW(), '$ag->{title}', '$ag->{body}', $com->{user_id}, $ag->{pid}, 0, 0, $ag->{uid}, 1 )", my_dbh($cf), $r );
         my_dbValue( "UPDATE session SET comment=comment+1 where user_id=$com->{user_id}", my_dbh($cf), $r ) ;
        }  #>  end of system call to mail

     } else { #> if img_id failed
    
     $r->print( t_box("Testin: No args...there was an error with my_dbValue ref return") );
    
     } #>  end of  if ref drom img_id

 } else { #> if ag failed
    $r->print( t_box("Testin: No args...for add_comment") );
 } #>  end of if ag


} #>  end of  my_add_comment!

sub v_comment_pic {
my($ag, $cf, $ret, $r) = @_;  
my $comment_code = &my_comment_box($ret, $cf, $ag);
   $r->print( v_pic_box( my_dbValue( "SELECT * FROM images WHERE im_id=$ag->{pid}", my_dbh($cf), $r ), $cf, 200, $comment_code ) );
}

sub v_email_pic {
my($ag, $cf, $ret, $r) = @_;
my $img = my_dbValue( "SELECT * FROM images WHERE im_id=$ag->{pid}", my_dbh($cf), $r ); 
my $email_box = &my_email_box($ret, $cf, $img);
$r->print( v_pic_box( $img, $cf, 200, $email_box ) );
}

sub my_img_quips_box {
my ($ret, $cf, $com) = @_;

my $width = $_[3] ? $_[3] : 80;
foreach (sort keys %$ret){
if($_ eq 'image') {
   if( $ret->{image} eq "0") {   
    $ret->{image} = qq(<img src="http://www.mplib.org/images/joymonk.jpg" alt=Smile width="$width"> );
   } else {
    $ret->{image}   = '<img src="' . $ret->{$_} . '" align=center alt=Nice Smile! width="'. $width .'" border="0">';
   }
}
        $ret->{alias}  =  $ret->{$_}  if $_ =~ /alias/;
    $ret->{gender}  = uc($_) . ' ' . ' &clubs;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /gender/;
      $ret->{sexual}  = uc($_) . ' ' . '</b> &hearts;' . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sexual/;
    $ret->{city}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /city/;
        $ret->{sign}  =  ' &hearts;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /sign/;
    $ret->{zip}  = uc($_) . ' ' . ' &diams;'  . ' ' . $ret->{$_} . ' ' . '<br/>' if $_ =~ /zip/;         
    $ret->{email} = '<a href=mailto:'. $ret->{$_} . '>'  . $ret->{$_} . '</a>' if $_ eq 'email';
   
}


$com->{time} =~ s/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\.\d{5,6}$/$1 /g;

my $delete_quips;

if ( $cf->{tbl}{user_id}[0] eq $com->{profile_id} ) {
$delete_quips = qq| <a href="$cf->{url_perl}?action=delete_quips&cid=$com->{com_id}">delete</a> |;
}

my $img = my_dbValue("select url from images where im_id=$com->{im_id}", my_dbh($cf) );
   
my $box = <<"BOX";
<table class="silver">
<tr align="center">
<td><a href=/admin?action=$ret->{extra_id}&auth=$ret->{user_id}>$ret->{image}</a></td>
<td align="left" class="dot">
Time: $com->{time} | Title: $com->{title}<br/>
<blockquote>
<b>$com->{body}</b>
</blockquote>
</td>
<td><a href="/admin?action=v_pics&auth=$com->{profile_id}"><img src="$img->{url}" width="80" border="0"></a></td>
</tr>
<tr><td align="right"><a href=/admin?action=v_comment_pic&pid=$com->{im_id}>add quip</a></td></tr>
</table>
BOX
}

sub v_quips_pic {
my($ag, $cf, $ret, $r) = @_;
my $hr = { tbl =>{}, };
my $quips_boxs;
my $we_got_quips;
my %seen_it;
my $img = my_dbValue("SELECT * from images where im_id=$ag->{pid}", my_dbh($cf), $r );
 
my $img_prof_id = my_struc( my_dbValuesHash("SELECT profile_id from comments where im_id=$ag->{pid} and flag=2",
                            my_dbh($cf), $r)
                     , $hr);
my $img_comm_id = my_struc( my_dbValuesHash("SELECT com_id from comments where im_id=$ag->{pid} and flag=2 ORDER BY time DESC",
                            my_dbh($cf), $r)
                     , $hr);


  if( ref($img_prof_id) ) {
   
      $we_got_quips = 1;
         foreach my $com ( @{ $img_comm_id->{tbl}{com_id} } ) {
                
                    my $cid  =  my_dbValue("SELECT * from comments where  com_id=$com", my_dbh($cf), $r);
                    if ( ref($cid) ) {
                     my $uid  =  my_dbValue("SELECT * from profile where user_id=$cid->{profile_id}", my_dbh($cf), $r);
                          $quips_boxs .= &my_img_quips_box( $uid, $cf, $cid );
                     }
        }
 

         unless($we_got_quips){
         $quips_boxs = "We don't got quips for $img->{descr}...how about adding some!";
       }           
  } else {
   $quips_boxs = "Not no ref from my_struc";
  }


  #v_pic_box( $ret, $cf, 80, undef, $quips_boxs )
  $r->print( t_box( $quips_boxs ) );
}

sub my_quips {
my($ag, $cf, $ret, $r) = @_;
my $hr = { tbl =>{}, };
my $quips_boxs = undef;
my $we_got_quips = undef;
my %seen_it = undef;
my $img = my_dbValue("SELECT * from images where im_id=$ag->{pid}", my_dbh($cf), $r );
 
my $img_prof_id = my_struc( my_dbValuesHash("SELECT profile_id from comments where user_id=$ret->{user_id}",
                            my_dbh($cf), $r)
                     , $hr);
my $img_comm_id = my_struc( my_dbValuesHash("SELECT com_id from comments where user_id=$ret->{user_id} ORDER BY time DESC",
                            my_dbh($cf), $r)
                     , $hr);


  if( ref($img_prof_id) ) {
   
      $we_got_quips = 1;
         foreach my $com ( @{ $img_comm_id->{tbl}{com_id} } ) {
                
                    my $cid  =  my_dbValue("SELECT * from comments where  com_id=$com", my_dbh($cf), $r);
                    if ( ref($cid) ) {
                     my $uid  =  my_dbValue("SELECT * from profile where user_id=$cid->{profile_id}", my_dbh($cf), $r);
                          $quips_boxs .= &my_img_quips_box( $uid, $cf, $cid );
                     }
        }
 

         unless($we_got_quips){
         $quips_boxs = "We don't got quips for $img->{descr}...how about adding some!";
       }           
  } else {
   $quips_boxs = "We don't got quips!";
  }


$r->print( t_box( $quips_boxs ) );
}


sub v_mk_suggestion {
my($ag, $cf, $ret, $r) = @_;
my $sug = &v_suggestion_box( $ag, $cf, $ret, $r );
$r->print( t_box( $sug ) );

}

sub my_request_verdict {

my ($ag, $cf, $ret, $r) = @_;

     if( $ag->{verdict} eq 'Accept') {
      my_dbValue("UPDATE friends set status=2 where friend_id=$ret->{user_id} and user_id=$ag->{uid}", my_dbh($cf), $r);
         $r->print( t_box("<h3>$ag->{alias} has been added to your list of friends. Bliss you!</h3>") );
      my_dbValue("INSERT INTO friends VALUES (DEFAULT, $ret->{user_id}, $ag->{uid}, 2, 1) ", my_dbh($cf), $r); 

     } elsif ($ag->{verdict} eq 'Decline') {
       my_dbValue("UPDATE friends set status=0  where friend_id=$ret->{user_id} and user_id=$ag->{uid}", my_dbh($cf), $r); 
       $r->print(t_box("<h3>You have declined $ag->{alias} as a frined!</h3>") );   
      } elsif ($ag->{verdict} eq 'Block') {
      my_dbValue("UPDATE friends set flag=0 where friend_id=$ret->{user_id} and user_id=$ag->{uid}", my_dbh($cf), $r );     
        &er_notice("BLOCK NOTICE: User = $ret->{user_id} has blocked $ag->{alias}, with user_id = $ag->{uid}");
         $r->print("<h3<You have blocked $ag->{alisa} from requestion your friendship...</h3>");
     } else {
        &er_notice("There was an error with my_request_verdict");
     }
my_dbValue("UPDATE session SET note= note - 1 where user_id=$ret->{user_id}", my_dbh($cf), $r);
}

sub my_comment_verdict {

my ($ag, $cf, $ret, $r) = @_;

     if( $ag->{verdict} eq 'Accept') {
      my_dbValue("UPDATE comments set flag=2 where com_id=$ag->{com_id}", my_dbh($cf), $r);
         $r->print( t_box("<h3>$ag->{alias}'s comment has been accepted</h3>") );
      #my_dbValue("INSERT INTO friends VALUES (DEFAULT, $ret->{user_id}, $ag->{uid}, 2, 1) ", my_dbh($cf), $r); 

     } elsif ($ag->{verdict} eq 'Decline') {
       my_dbValue("UPDATE comments set flag=0  where com_id=$ag->{com_id}", my_dbh($cf), $r); 
       $r->print(t_box("<h3>You have declined $ag->{alias}'s comment!</h3>") );   
      } elsif ($ag->{verdict} eq 'Block') {
      my_dbValue("UPDATE friends set flag=0 where friend_id=$ag->{uid} and user_id=$ret->{user_id}", my_dbh($cf), $r );     
      &er_notice("BLOCK NOTICE: User = $ret->{user_id} has blocked $ag->{alias}, with user_id = $ag->{uid}");
       $r->print("<h3<You have blocked $ag->{alias} from commenting on your posts.</h3>");
     } else {
        &er_notice("There was an error with my_request_verdict");
     }
my_dbValue("UPDATE session SET comment= comment - 1 where user_id=$ret->{user_id}", my_dbh($cf), $r);
}



sub v_profiles {
my($ag, $cf, $ret, $r) = @_;
$r->print( my_content( my_dbh($cf), $cf->{sql}, \&my_box)  );
}

sub my_edit    {
my ($ag, $cf, $ret, $r) = @_;
&my_links($ag, $cf);
$r->print( &t_box("Edit Profile Helper, i'm out for lunch, so try me later :-P") );
}

sub my_v_blogs    {
my ($ag, $cf, $ret, $r) = @_;
$r->print( my_content( my_dbh($cf), "SELECT * FROM blogs WHERE user_id=$ret->{user_id} ORDER BY time DESC" , \&my_blog_box ) );
}

sub v_blogs    {
my ($ag, $cf, $ret, $r) = @_;
$r->print( my_content( my_dbh($cf), "SELECT * FROM blogs  WHERE user_id=$ret->{user_id} AND flag=\'all\' ORDER BY time DESC" , \&v_blogs_box ) );
}

sub v_pics    {
my ($ag, $cf, $ret, $r) = @_;
$r->print( my_content( my_dbh($cf), "SELECT * FROM images WHERE user_id=$ret->{user_id} AND flag=\'all\'" , \&v_pics_box ) );
}

sub my_v_pics    {
my ($ag, $cf, $ret, $r) = @_;
$r->print( my_content( my_dbh($cf), "SELECT * FROM images WHERE user_id=$ret->{user_id}" , \&my_pics_box ) );
}

sub v_blogs_list    {
my ($ag, $cf, $ret, $r) = @_;
$r->print( my_content(
           my_dbh($cf), "SELECT blog_id, time, user_id, title, category FROM blogs WHERE flag=\'all\' ORDER BY time DESC"
           , \&v_blogs_list_box ) );
}

sub v_top_blogs {
my ($ag, $cf, $ret, $r) = @_;
$r->print(t_box("<h2><div align=left class=blue>Latest Blogs</div></h2>") );
$r->print( my_content(
           my_dbh($cf), "SELECT blog_id, user_id, title, category FROM blogs WHERE flag=\'all\' ORDER BY time DESC LIMIT 5"
           , \&v_blogs_list_box) );
}

sub v_pics_list    {
my ($ag, $cf, $ret, $r) = @_;
$r->print( my_content( my_dbh($cf), "SELECT * FROM images WHERE flag=\'All\'" , \&v_pics_list_box ) );
}


sub v_blog    {
my ($ag, $cf, $ret, $r) = @_;
$r->print( v_blog_box( my_dbValue( "SELECT * FROM blogs WHERE blog_id=$ag->{bid}", my_dbh($cf), $r ), my_dbh($cf) ) );
}

sub my_req_req  {
my ($ag, $cf, $ret, $r) = @_;

my $check_stat = my_dbValue("SELECT status from friends where friend_id=$ag->{auth} and user_id=$ret->{user_id}", my_dbh($cf), $r);
  if($check_stat->{status} eq '1') {
   $r->print("<h3>$ret->{first}, your request is still pending. Have patience!</h3>");
  
  } elsif ( $check_stat->{status} eq '2') {
   $r->print("<h3>Hey $ret->{first}, this member is already a Joyfriend of yours!</h3>");
  } else {

  $r->print( my_req_box( my_dbValue( "SELECT * FROM profile WHERE user_id=$ag->{auth}", my_dbh($cf), $r ) , $cf  ) );

 }

}

sub my_friends {

my($ag, $cf, $ret, $r) = @_;
my $hr = {tbl =>{} , };
my $joy_friends = undef;

my $friends = my_struc( my_dbValuesHash("SELECT friend_id from friends where user_id=$ret->{user_id} and status=2",
                        my_dbh($cf), $r) , $hr);
if( ref($friends) ) {
 $r->print("<table align=center><tr>");
my $i = 0;
   foreach( @{$friends->{tbl}{friend_id} } ) {
    $joy_friends = 1 if $_; $i++;
    #$r->print( my_frn_content( my_dbh($cf), "SELECT * from profile where user_id=$_", \&my_friends_box) );
    $r->print( my_friends_box( my_dbValue("SELECT * FROM profile where user_id=$_ LIMIT 24", my_dbh($cf), $r ) , $cf, 1 , 90)  );
    $r->print("</tr><tr>") if $i == 8;
      if ($i == 8 ) { $i = 0; }
    }
    $r->print("</tr></table>");
}
unless($joy_friends) {
$r->print( t_box("<h3>It looks like you haven't added any friends yet! Start the fun by Requesting Joyfriends...</h3>") );

}

}

sub v_friends {

my ($ag, $cf, $ret, $r) = @_;
my $hr = {tbl =>{}, };
my $have_friends = undef;
my $friends = my_struc( my_dbValuesHash("SELECT friend_id from friends where user_id=$ag->{auth} and status=2",
                    my_dbh($cf), $r)
                    , $hr );
 
if(ref($friends) ) {
    $r->print("<table  align=center><tr>");
my $i = 0;
    foreach( @{ $friends->{tbl}{friend_id} } ) {
     $have_friends = 1 if $_; $i++;  
      #$r->print( my_frn_content( my_dbh($cf), "SELECT * from profile where user_id=$_", \&my_friends_box ) );
     $r->print( my_friends_box( my_dbValue("SELECT * FROM profile where user_id=$_ LIMIT 24", my_dbh($cf), $r ) , $cf, 1 , 90)  );
      $r->print("</tr><tr>") if $i == 8;
      if ($i == 8 ) { $i = 0; }  
     }
     $r->print("</tr></table>");
  }
  unless($have_friends) {
  $r->print(t_box("<h3>It looks like no Joyfriends have been added yet!</h3>"));
  }


}

sub my_requests {
my ($ag, $cf, $ret, $r) = @_;
my $made_requests = undef;
my $hr = { tbl => {}, };
my $frn_req = my_struc( my_dbValuesHash("SELECT friend_id from friends where user_id=$ret->{user_id} and status=1",
                     my_dbh($cf), $r)
                  , $hr );
my $friends_table;
  if( ref($frn_req) ) {
    $r->print("<table  align=center><tr>");
    foreach (@{ $frn_req->{tbl}{friend_id} } ) {
     $made_requests = 1 if $_ ;
     #$r->print(  my_frn_content( my_dbh($cf), "SELECT * from profile where user_id=$_" , \&my_friends_box ) );
     $r->print( my_friends_box( my_dbValue("SELECT * FROM profile where user_id=$_", my_dbh($cf), $r ) , $cf, 1 , 90)  );
    }
     $r->print("</tr></table>");
  }

  unless($made_requests){
     $r->print( t_box("<h3>$ret->{first}, you do not have any pending requests!</h3>") );
  
  }

}

sub new_request_ck {

my ($ag, $cf, $ret, $r) = @_;
my $requests = undef;

  if( $ag ) {
     $r->print( t_box("<div class=blue> Accept or Deny new friend!</div>") );
  
         $requests = 1 if  $ag ;  
  
     $r->print( &check_request_box( my_dbValue("SELECT * FROM profile where user_id=$ag->{uid}", my_dbh($cf), $r )  ) );
  }
  
   unless($requests) {
    $r->print( t_box("<h3>No new requests to check!<h3>") );
  }

}

sub ck_requests {

my ($ag, $cf, $ret, $r) = @_;
my $requests = undef;
my $hr = { tbl => {}, } ;
my $frn_req = my_struc( my_dbValuesHash("SELECT user_id from friends where friend_id=$ret->{user_id} and status=1",
              my_dbh($cf), $r )
             , $hr);
  if( ref($frn_req) ) {
    $r->print( t_box("<div class=blue>Click, then [ Accept or Deny ] new friend!</div>") );
      foreach ( @{ $frn_req->{tbl}{user_id} } ) {
         $requests = 1 if  $_ ;  
       
           $r->print( &check_all_requests_box( my_dbValue("SELECT * FROM profile where user_id=$_", my_dbh($cf), $r )  ) );
       }
  
    #my_dbValue("UPDATE session SET note=0 where user_id=$ret->{user_id}", my_dbh($cf), $r);
   }
   unless($requests) {
    $r->print( t_box("<h3>No new requests to check!<h3>") );
  }

}



sub ck_comments {

my ($ag, $cf, $ret, $r) = @_;
my $requests = undef;
my $hr = { tbl => {}, } ;
my $fr_com = my_struc( my_dbValuesHash("SELECT com_id from comments where user_id=$ret->{user_id} and flag=1",
              my_dbh($cf), $r ) , $hr);
            
  if( ref($fr_com) ) {

      $r->print( t_box("<div class=blue>Click, then [ Accept or Deny ] new comment!</div>") );
      foreach ( @{ $fr_com->{tbl}{com_id} } ) {
        my $com = my_dbValue("SELECT com_id, profile_id, time, title, body FROM comments WHERE com_id=$_ and user_id=$ret->{user_id}", my_dbh($cf) , $r);
         $requests = 1 if $_ ;  
           $r->print( &check_all_comments_box( my_dbValue("SELECT * FROM profile where user_id=$com->{profile_id}", my_dbh($cf), $r ), $cf, $com, 80  ) );
       }
  
   }
   unless($requests) {
    $r->print( t_box("<h3>No new comments to check!<h3>") );
  }

}

sub comment_ck {

my ($ag, $cf, $ret, $r) = @_;
my $requests = undef;
            
  if( $ag ) {
 
       my $com = my_dbValue("SELECT com_id, profile_id, time, title, body FROM comments WHERE com_id=$ag->{com_id} and user_id=$ret->{user_id}", my_dbh($cf) , $r);
       $requests = 1 if $com ;
           
       $r->print( &check_comment_box( my_dbValue("SELECT * FROM profile where user_id=$com->{profile_id}", my_dbh($cf), $r ), $cf, $com, 80  ) );

  
   }
   unless($requests) {
    $r->print( t_box("<h3>No new comments to check!<h3>") );
  }

}


sub v_pic    {
my ($ag, $cf, $ret, $r) = @_;
$r->print( v_pic_box( my_dbValue( "SELECT * FROM images WHERE im_id=$ag->{pid}", my_dbh($cf), $r ) ) );
}

sub my_icon {
my ($ag, $cf, $ret, $r) = @_;
my $db_val = my_dbValue( "SELECT descr, user_id, url from images WHERE im_id=$ag->{pid}", my_dbh($cf), $r);

  if ( ref($db_val) ) {
   my_dbValue( "Update profile set image=\'$db_val->{url}\' WHERE user_id=$db_val->{user_id}", my_dbh($cf), $r) ;
   $r->print( t_box("Your icon is now set to:  $db_val->{descr}") );
  } else {
   $r->print( t_box("Sorry, there was an error, please notify bliss [at] mplib.org. Thanks!") );
   &er_notice("The my_icon functoin didn't work, no ref was returned", $r );
  }
}

sub my_im_private {
my ($ag, $cf, $ret, $r) = @_;

my $db_val = my_dbValue( "SELECT descr, user_id FROM images WHERE im_id=$ag->{pid}", my_dbh($cf), $r);

    if( ref($db_val) ) {
        my_dbValue( "UPDATE images SET flag=\'Private\' WHERE im_id=$ag->{pid}", my_dbh($cf), $r);
       $r->print( t_box("Your image setting is now set to Private which is as good as delete; No one can see it but you!"));
        $r->print( t_box("We have a policy not to delete anything from your private database, just in case..."));
    } else {
        $r->print( t_box("Sorry, there was an error, please notify bliss [at] mplib.org. Thanks!"));
        &er_notice("The function my_im_private didn't work, no ref was returned from my_dbValue", $r );
    }
}

sub my_im_all {
my ($ag, $cf, $ret, $r) = @_;
my $db_val = my_dbValue( "SELECT descr, user_id FROM images WHERE im_id=$ag->{pid}", my_dbh($cf), $r);
  
   if(ref($db_val)){
    my_dbValue("UPDATE images SET flag=\'All\' WHERE im_id=$ag->{pid}", my_dbh($cf), $r);
        $r->print(t_box("Your image setting is now set to All, which means everyone can see it!"));
        $r->print(t_box("If you change your mind, just click on the make Private button and it will make it Private!"));
   } else {
        $r->print(t_box("Sorry, there was an error, please notify bliss [at] mplib.org. Thanks!"));
       &er_notice("The function my_im_all didn't work, no ref was returned from my_dbValue", $r);
   }

}
sub my_blog { 
my ($ag, $cf, $ret, $r) = @_;
my $location = "http://www.mplib.org/perl/blog.pl";    
$r->headers_out->set(Location => $location);
$r->status(302);
return Apache::Const::REDIRECT;
}

sub my_images { 
my ($ag, $cf, $ret, $r) = @_;
my $location = "http://www.mplib.org/perl/upload.pl";    
$r->headers_out->set(Location => $location);
$r->status(302);
return Apache::Const::REDIRECT;
}

sub my_music { 
my ($ag, $cf, $ret, $r) = @_;
my $location = "http://www.mplib.org/perl/music.pl";    
$r->headers_out->set(Location => $location);
$r->status(302);
return Apache::Const::REDIRECT;
}

sub my_style   {
my ($ag, $cf, $ret, $r) = @_;
&my_links($ag, $cf, $ret, $r);
$r->print( &t_box( "Temple Style Helper, but i had to get some ice cream, so try me later >:-P" ) );
}

sub my_cancel  {
my ($ag, $cf, $ret, $r) = @_;

my $box =<<"BOX";

<form action=$cf->{url_perl}?action=Cancel method="POST">
<table width=90%>
<tr><td class="blue"><h3>Enter The Super Secret Magic Word, please!</h3></td></tr>
<tr>
<td>Magic Word:<input type="text" name="magic" size="30" value=""></a></td></tr>

<tr><td><input type="submit" name="change" value="Kill Joy">
<input type="hidden" name="action" value="cancel"></td>
</tr>
</table>
</form>
BOX
if($ret->{extra_id} == 1) {
   if($ag->{change}) {
        if($ag->{magic} =~ /[Pp][lease|LEASE][!.?]*/) {
             $r->print(t_box("<div class=dash>You got the magic word right, pooperzYOU! Okay,
                     we'll cancel your profile, but we're very sad to see you leave :'( </b></div>"));
             $r->print(t_box("<div class=silver>Just to make sure you're really the person who created this account, please fill out our suggestion box, and give us the Super Secret Magic Word as the subject + your email and we will cancel your account ASAP! Until then your account is temporarily not visible to the public.</div>" ) ); my $hr = { extra_id => 0, };
             &update_table($hr,$cf, $ret, 'profile');
            } else {   
              $r->print("<div class=silver><font color=red>$ret->{alias}, that's NOT the magic word! ;-p hahahah...</font><div>" );
             $r->print($box);
           }

  } else {

  $r->print( $box );
  }

} else {
$r->print(t_box("$ret->{alias}, your profile is temporarily on hold, because a request to Cancel Profile was initated from your Log in session!"));

}

}

sub my_linksOne {
my ($ag, $cf )= @_;
return <<"BOX";
<div id="joyfriends"><a href="$cf->{url_perl}?action=joyfriends">Library Friends</a><br/><div>
<div id="edit"><a href="$cf->{url_perl}?action=edit">Edit My Profile </a><br/></div>
<div id="images"><a href="/perl/upload.pl">Upload New Images</a><br/></div>
<div id="ViewImages" ><a href="$cf->{url_perl}?action=my_v_pics">View My Images </a><br/></div>
<!-- div id="music"><a href="/perl/music.pl">Upload New Media</a><br/></div -->
<div id="my_request"><a href="$cf->{url_perl}?action=my_requests">Check Pending Requests</a><br/><div>
<div id="ck_request"><a href="$cf->{url_perl}?action=ck_requests">Check New Friend Request</a><br/></div>
BOX
}

sub my_linksTwo {
my ($ag, $cf )= @_;
return <<"BOX";
<div id="my_quips"><a href="$cf->{url_perl}?action=my_quips">View All Quips</a><br/></div>
<div id="ck_comments"><a href="$cf->{url_perl}?action=ck_comments">Check For New Quips</a><br/></div>
<div id="blog">      <a href="/perl/blog.pl">Create New Blog</a><br/></div>
<div id="my_vBlog"><a href="$cf->{url_perl}?action=my_v_blogs"> View My Blogs </a><br/></div>
<!-- div id="style"   ><a href="$cf->{url_perl}?action=style"> Style My Profile   </a><br/></div -->
<div id="cancel"  ><a href="$cf->{url_perl}?action=cancel"> Cancel My Profile    </a><br/></div>
BOX
}

sub my_actsOne {
my ($ret, $cf) = @_;
return <<"BOX";
<div id="v_pics" ><a href="$cf->{url_perl}?action=v_pics&auth=$ret->{user_id}"   >My Images </a><br/></div>
<!-- div id="v_prof" ><a href="$cf->{url_perl}?action=v_prof&auth=$ret->{user_id}"   >Profile </a><br/></div -->
<div id="v_video"><a href="$cf->{url_perl}?action=v_friends&auth=$ret->{user_id}">Friends </a><br/></div>
BOX
}

sub my_actsTwo {
my ($ret, $cf) = @_;
return <<"BOX";
<div id="v_blogs" ><a href="$cf->{url_perl}?action=v_blogs&auth=$ret->{user_id}" >Blogs   </a><br/></div>
<!-- div id="v_music"><a href="$cf->{url_perl}?action=v_media&auth=$ret->{user_id}"  >Media   </a><br/></div -->
<div id="v_request"><a href="$cf->{url_perl}?action=mk_req&auth=$ret->{user_id}" >Request <br/>Friendship</a><br/></div>
BOX
}

sub edit {
my ($ag, $cf, $ret, $r) = @_;
my ($value, $seen, $form, $check_value, $input, $new_input, $first, $last) = "";
my $prf = &prf($cf, $ret->{user_id});

 if($ag->{change} eq 'ReEdit') {
     $value = 'Submit';   
                foreach my $k (sort keys %$ag) {
           next if $k =~ /action|edit|change|seen/ ;
                $first = qq| <tr><td> First Name : </td><td><input type="text" name="$k" id="$k" size="30" value="$ag->{$k}"></td></tr> | if $k eq 'first';
               $last = qq|  <tr><td> Last Name : </td><td><input type="text" name="$k" id="$k" size="30" value="$ag->{$k}"></td></tr> | if $k eq 'last';
                $input .= qq| <tr><td> $k : </td><td><input type="text" name="$k" id="$k" size="30" value="$ag->{$k}"></td></tr> | unless $k =~ /first|last/;
          }
     $input = $first . $last . $input;
    } else {
     $value = 'Preview';
               foreach my $k(sort keys %$prf) {
           next if $k =~ /user_id|extra_id|date|password|image/;
                $first = qq| <tr><td> First Name : </td><td><input type="text" name="$k" id="$k" size="30" value="$prf->{$k}"></td></tr> | if $k eq 'first';
               $last  = qq| <tr><td> Last Name : </td><td><input type="text" name="$k" id="$k" size="30" value="$prf->{$k}"></td></tr> | if $k eq 'last';
               $input .= qq| <tr><td> $k : </td><td><input type="text" name="$k" id="$k" size="30" value="$prf->{$k}"></td></tr> | unless $k =~ /first|last/;
          }  
     $input = $first . $last . $input;
   }
       
$form =<<"INITBOX";
<form action="$cf->{url_perl}" method="POST">
<table>
$input
<tr><td><input type="submit" name="change" value="$value"></td></tr>
<tr><td><input type="hidden" name="action" value="edit"></td></tr>
<tr><td><input type="hidden" name="seen" value=""></td></tr>
</table>
</form>
INITBOX


if( $ag->{change} eq 'Preview' ) {

           foreach my $k (sort keys %$ag) {
          next if $k =~ /action|edit|change/ ;
          $ag->{seen} = 1 if $k eq 'seen';
                $first = qq| <tr><td> First Name : </td><td>$ag->{$k}</td></tr> | if $k eq 'first';
               $last = qq|  <tr><td> Last Name : </td><td>$ag->{$k}</td></tr> | if $k eq 'last';
                $new_input .= qq|<tr><td>$k:</td><td> $ag->{$k}</td></tr> | unless $k =~ /first|last|seen/;
          $hidden .= qq| <input type="hidden" name="$k" value="$ag->{$k}"> |;    
           }

$new_input = $first . $last . $new_input;

$check_value =<<"CHECKVALUEBOX";
<h2 class="blue">Please check that these are the values you want!</h2>
<form action="$cf->{url_perl}" method="POST">
<table>
$new_input
<tr><td><input type="submit" name="change" value="ReEdit"></td><td><input type="submit" name="change" value="Save"></td></tr>
<tr><td><input type="hidden" name="action" value="edit"></td></tr>
<tr><td>
$hidden
</td></tr>
</table>
</form>
CHECKVALUEBOX
}

   if ( $ag->{change} ) {
         if ($ag->{change} eq 'Save' || $ag->{change} eq 'Submit') {
            $r->print( t_box( qq{ <h2 class="blue">Your new values have been saved!</h2>} ) );
            &update_table($ag, $cf, $ret, 'profile');
         } elsif ($ag->{change} eq 'Preview' ) {
           $r->print( t_box( "$check_value" ) );
         } elsif ($ag->{change} eq 'ReEdit') {
           $r->print( t_box("$form") ) ;
         }
   }  else {
       $r->print( t_box( qq{<h2 class="blue">$ret->{first}, please enter your new values below to change your profile.</h2>} ) );
       $r->print( t_box( qq{<a href="$cf->{usr_perl}?action=save_pwd"><input type="button" name="" value="I want to change my Password!"></a>} ) );
       $r->print( t_box( "$form" ) ) ;
   }


}

sub edit_blog {
my ($ag, $cf, $ret, $r) = @_;
my ($value, $seen, $form, $check_value, $input, $new_input, $first, $last) = undef;
my $prf = &my_dbValue("SELECT * from blogs where blog_id=$ag->{bid}", my_dbh($cf));
my $date = scalar localtime;

 if($ag->{change} eq 'ReEdit') {
     $value = 'Submit';   
                foreach my $k (sort keys %$ag) {
           next if $k =~ /action|edit|change|seen/ ;
                #$ag->{time} = $date if $k eq 'time';
                $input .= qq| <tr><td class=silver> <b>$k :</b><input type="text" name="$k" id="$k" size="30" value="$ag->{$k}"></td></tr> | if $k =~ m/title|category/g;
          $input .= qq| <tr><td class=silver><TEXTAREA  name="$k" id="$k" rows="20" cols="60">$ag->{$k}</TEXTAREA></td><td></td></tr> | if $k =~ /body/;
           $input .= qq| <tr><td><input type="hidden" name="$k" id="$k" size="30" value="$ag->{$k}"></td><td></td></tr> | if $k =~ /user_id|blog_id/;
                $input .= qq| <tr><td class=silver><b> $k :</b><input type="text" name="$k" id="$k" size="30" value="$ag->{$k}"></td></tr> | unless $k =~ /body|user_id|blog_id|title|category/;
               }
    } else {
     $value = 'Preview';
               foreach my $k (sort keys %$prf) {
                next if $k =~ /time|flag|stat/ ;
                $prf->{time}  =~ s/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\.\d{5,6}$/$1 /g  if $k eq 'time';
                $input  .= qq| <tr><td class=silver> <b>$k : </b><input type="text" name="$k" id="$k" size="30" value="$prf->{$k}"></td></tr> | if $k =~ m/title|category/g;
          $input  .= qq| <tr><td class=silver><TEXTAREA  name="$k" id="$k" rows="20" cols="60">$prf->{$k}</TEXTAREA></td><td></td></tr> | if $k =~ /body/;
           $input  .= qq| <tr><td class=silver><input type="hidden" name="$k" id="$k" size="30" value="$prf->{$k}"></td><td></td></tr> | unless $k =~ /body/;
                #$input .= qq| <tr><td><b> $k :</b><input type="text" name="$k" id="$k" size="30" value="$prf->{$k}"></td></tr> | unless $k =~ /body|user_id|blog_id|flag|stat|title|category|time/;
               }  
   }
my $header = q{<h2 class="blue">Flags for viewing options: all, friends, private |  Stat of blog: draft, post</h2><i class=bot>Enter the "flag" and "stat" values lower case letters</i>} if $ag->{seen} == 1 ;       
$form =<<"INITBOX";
<form action="$cf->{url_perl}" method="POST">
$header
<table>
$input
<tr><td><input type="submit" name="change" value="$value"></td></tr>
<tr><td><input type="hidden" name="action" value="edit_blog"></td></tr>
<tr><td><input type="hidden" name="seen" value=""></td></tr>
</table>
</form>
INITBOX


if( $ag->{change} eq 'Preview' ) {

           foreach my $k (sort keys %$ag) {
          next if $k =~ /action|edit|change/ ;
          $ag->{seen} = 1 if $k eq 'seen';
                $new_input .= qq|<tr><td class=silver><b>$k </b> $ag->{$k}</td></tr> | unless $k =~ /user_id|seen|blog_id|body|flag|stat/;
          $new_input .= qq|<tr><td class=silver><blockquote>$ag->{$k}</blockquote></td><td></td></tr> | if $k =~ /body/;
          $hidden .= qq| <input type="hidden" name="$k" value="$ag->{$k}"> |;    
           }
 

$check_value =<<"CHECKVALUEBOX";
<h2 class="blue">Please check that these are the values you want!</h2>
<form action="$cf->{url_perl}" method="POST">
<table>
$new_input
<tr>
<td class="silver"><b>Viewing Option:</b>
<input type="radio" name="flag" value="all" />All <input type="radio" name="flag" value="friends" />Friends <input type="radio" name="flag" value="private" checked="checked" />Private</td>
</tr>
<tr><td class="silver"><b>NOTE: defaults are "private" & "draft":</b><input type="radio" name="stat" value="draft" checked="checked" />Draft <input type="radio" name="stat" value="post" />Post</td>
</TR>
<tr><td class=silver><input type="submit" name="change" value="ReEdit"><input type="submit" name="change" value="Save"></td></tr>
<tr><td class=silver><input type="hidden" name="action" value="edit_blog"></td></tr>
<tr><td>
$hidden
</td></tr>
</table>
</form>
CHECKVALUEBOX
}

   if ( $ag->{change} ) {
         if ($ag->{change} eq 'Save' || $ag->{change} eq 'Submit') {
            $r->print( t_box( qq{ <h2 class="blue">Your have successfully edited your blog!</h2>} ) );
            &update_blog_table($ag, $cf, $ret, 'blogs');
         } elsif ($ag->{change} eq 'Preview' ) {
           $r->print( t_box( "$check_value" ) );
         } elsif ($ag->{change} eq 'ReEdit') {
           $r->print( t_box("$form") ) ;
         }
   }  else {
       $r->print( t_box( qq{<h2 class="blue">$ret->{first}, please edit your blog</h2>} ) );
       $r->print( t_box( "$form" ) ) ;
   }


}



sub save_pwd {
my ($ag, $cf, $ret, $r) = @_;

my $form =<<"BLANKBOX";
<form action="$cf->{url_perl}" method="POST">
<table>
<tr><td>New Password:</td><td><input type="password" name="password"></td></tr>
<tr><td>Retype:</td>   <td><input type="password" name="new_password" ></td></tr>
<tr><td><input type="hidden" name="action" value="save_pwd"></td></tr>
<tr><td><input type="submit" name="change" value="Save"></td></tr>
</table>
</form>
BLANKBOX

    if( $ag->{change} eq 'Save' ) {
         if ( $ag->{password} eq $ag->{new_password} )  {

                $r->print( t_box( qq{<h2 class="blue">$ret->{first}, your new password is saved</h2>} ) );
                $r->print( t_box( qq{<a href="$cf->{usr_perl}?action=edit"><font color="green">Change profile information</font><a>} ) );
               &my_dbValue("UPDATE profile set password='$ag->{password}' where user_id=$ret->{user_id}", my_dbh($cf) );
 
          } else {

                $r->print( t_box( qq{<div class="silver"><font color="red">$ret->{first}, your passwords didn't match, please try again</font></div>} ) );
                $r->print( t_box( qq{<a href="$cf->{usr_perl}?action=edit"><font color="green">Change profile information?</font><a>} ) );
                $r->print( t_box( $form ) ) ;
          }

    } else {
                $r->print( t_box( qq{<h2 class="blue">$ret->{first}, please enter a new password!</h2>} ) );
                $r->print( t_box( qq{<a href="$cf->{usr_perl}?action=edit"><font color="green">Change profile information</font><a>} ) );
                $r->print( t_box( $form ) );
    }

}


sub test_old {
my ($ag, $cf, $ret, $r) = @_;

    if($ag->{name}) {
    $r->print(t_box( "we got $ag->{name}" ) );
    } elsif ($ag->{profile}) {
    $r->print(t_box( "We got $ag->{profile}!" ) );
    } else {
    $r->print("hi $ret->{alias}");
    $r->print( t_box( prf($cf, 11)->{alias} ) );
    }
}

###########################################################################################
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#     HELPER FUNCTIONS: t_box, my_dbh, my_content, my_dbValue, my_dbValuesHash            #
#     my_struc, my_getCookie (no longer used, using CGI::Cookie instead)                  #
#     AUTOLOADER, my_frn_content, var_pars, my_simpleTmp, my_cl, prf returns profile      #
#     given the cf variable and a profile id                                              #
#                                                                                         #
###########################################################################################


sub prf {
my ($cf, $id) = @_;
my $profile = my_dbValue("select * from profile where user_id=$id", my_dbh($cf) );
   if( ref($profile) ) {
   return $profile;
   } else { 
   &er_notice("sub prf didn't return the profile needed for $cf->{tble}{user_id}[0]");
   }
}

sub update_table {
my($ag, $cf, $ret, $tbl) = @_;
   if( ref($ag) ){
         foreach my $k (%$ag ) {
         next if $k =~ /action|edit|change|seen/ ;
         my_dbValue("UPDATE $tbl set $k='$ag->{$k}' where user_id=$ret->{user_id}", my_dbh($cf) );
         }
    
   }else {
    &er_notice("sub update_profile didn't get ag ref needed for my_dbValue to update user:$cf->{tbl}{user_id}[0]  profile");
   }
}

sub update_blog_table {
my($ag, $cf, $ret, $tbl) = @_;
   if( ref($ag) ){
         foreach my $k (%$ag ) {
         next if $k =~ /action|edit|change|seen|blog_id|time/ ;
         my_dbValue("UPDATE $tbl set $k='$ag->{$k}' where blog_id=$ag->{blog_id}", my_dbh($cf) );
         }
    
   }else {
    &er_notice("sub update_profile didn't get ag ref needed for my_dbValue to update user:$cf->{tbl}{user_id}[0]  profile");
   }
}

sub my_blog_test { 
my ($ag, $cf, $ret, $r) = @_;
   
my_initializeValues ( $ag, $cf, $ret, $r);
#my_printForm($ag, $cf, $ret, $r);

}

sub var_pars { #takes the query sting and give a reference to a hash
my $qs = shift;
my @qr = split(/&/, $qs);
my %qs;
    foreach my $i (0..$#qr) {
    $qr[$i] =~ s/\+/ /g;
    $qr[$i] =~ s/%(..)/pack("c", hex($1))/ge;
    my($k, $v) = split(/=/, $qr[$i],2);
    $qs{$k}=$v;
    }
return \%qs;

} #end of var_pars sub

sub my_cl {
my $pr = shift;

   $pr =~ s/'/ /g;
   $pr =~ s/\?/ /g;
   $pr =~ s/<script.*<\/script>/[WARNING SCRIPT REMOVED]/gm; 

return $pr;  
}

sub my_simpleTmp {  # Simple templating muncher!
my $conf = shift;
  foreach(@_){   
  s/<:(\w+):>/$conf->{$1}/g;
  print $_;
 }
}
#my @out = map { s/<:(\w+):>/$conf->{$1}/g , $_ } @_ ;

sub t_box {
my $tmp = shift;
 return "<table width=90% align=center><tr><td><B>$tmp</B></td></tr></table>";
}

sub my_sessionID { # takes 6 paramaters: Cookie name, random_text, email, user_id, extra_id, in/out!
     my ( $name, $rand, $email, $user_id, $goup_id, $in_out) = @_;
    my $values = [ $rand, $email, $user_id, $group_id, $in_out];
    return CGI::Cookie->new(-name  => $name,
                                    -value => $values,
                    -expires =>'+1M' );

  #$r->err_headers_out->add('Set-Cookie' => $cookie);
  #$r->headers_out->set(Location => $location);

}

sub my_dbh {  # needs Hash Ref for database, host, user and password
my $cf = shift;
return DBI->connect("dbi:Pg:dbname=$cf->{database};host=$cf->{host}", $cf->{user}, $cf->{pwd}, { PrintError => 1 } )
or die "Can't connect to PgSQL: $DBI::errstr ($DBI::err)\n";
}


sub my_dbValue {   # takes an SQL statement dbh handle
my ($stmt, $dbh, $r) = @_;
my $rt;
my %check;
$dbh->{pg_direct} = 0;
my $sth = $dbh->prepare($stmt);

#if($DBI::err){ $r->print( t_box("$DBI::errstr") ) if $cf->{DEBUG}; }

    my $ret = $sth->execute();

#if($DBI::err){ $r->print( t_box("$DBI::errstr") ) if $cf->{DEBUG}; }

if($stmt =~ /^\s*select/i){
    $rt = 1;
    my $rl_names = $sth->{NAME}; # ref to array col names
        while(my @results = $sth->fetchrow){
            if($DBI::err){
            #$r->print("$DBI::errstr") if $cf->{DEBUG};
            last;
            }

            foreach my $field_name (@$rl_names){
            my $name = shift @results;
            #$r->print("<p>$field_name - $name " ) if $cf->{DEBUG};
                        $check{$field_name} = $name;

            }

        }
}

    if($DBI::err){

    #$r->print( t_box( "There was an ERROR! Please email the admin at mplib.org!" ) );
        #&er_notice( "The my_dbValue function's dbi didn't work, error $DBI::err ", $r);
    } else {



        $sth->finish;
        $dbh->commit;

    }

return \%check if $rt == 1;
}

sub AUTOLOAD {
print t_box("We're still working on this feature, try back later!");
#    if ($AUTOLOAD =~ /.*::(.*)/ ){
#          my $element = $1;
#         *$AUTOLOAD = sub { shift->{$element} };
#        }
#goto &$AUTOLOAD;
}

sub my_content { #> ADDED BOXES OF PROFILES PgSQL CODE
my ($dbh, $stmt, $code, $r) = @_;
my $sth = $dbh->prepare($stmt);
if($DBI::err){ my $DBerror = "$DBI::errstr"; }
    my $retst = $sth->execute();
if (!$retst){
$DBerror = "<B>You are not registered!</b>";
}
my %data;
my $row = 1;   
if($DBI::err){ $r->print( t_box($DBerror) ) if $cf->{DEBUG}; }
if($stmt =~ /^\s*select/i){
    my $rl_names = $sth->{NAME}; # ref to array col names
        while(my @results = $sth->fetchrow){
           
            if($DBI::err){
            $r->print( t_box($DBI::err) ) if $cf->{DEBUG};
            last;
            }
             foreach my $field_name (@$rl_names){
             my $name = shift @results;
             $data{$row}{$field_name} = $name;
                         $check{$field_name} = $name;
            }
                #if($check{'user_id'} eq $baked{'sessionID'}[2]) {
                #    $fname  = $check{first};
                #    $lname  = $check{last};
                #}

            $row++;
        }
    $sth->finish;
}
#$dbh->commit;
#>         PgSQL ENDS
#>         Main page creation!

my @boxes;
my $rows;
my $content;
my $i;

if($DBerror){ 
 $r->print( t_box($DBerror) ) if $cf->{DEBUG};
 &er_notice( "There db function of my_content is not working, error $DBerror", $r);
} else {

    foreach my $d (sort keys %data) {
     push @boxes, $code->( $data{$d}, $dbh );
    }
  
    $content = "<table width=90% align=center valign=top><tr align=center>";
   
    for($i = 0; $i <= $#boxes;) {
        for (0..4) {
            $rows .=  "<td align=center valign=top>$boxes[$i]</td>" if $boxes[$i];
            $i++;
        }
    $rows .= '</tr></table><table width=90% align=center valign=top><tr align=center>';
        #$j = 0; my $j = 0; $j < 5 ; $j++
    }

     $content .=  $rows . "</tr></table><p></p>";
           
}

return $content;
}

sub my_frn_content { #> ADDED BOXES FOR FRIENDS
my ($dbh, $stmt, $code, $r) = @_;
my $sth = $dbh->prepare($stmt);
if($DBI::err){ my $DBerror = "$DBI::errstr"; }
    my $retst = $sth->execute();
if (!$retst){
$DBerror = "<B>You are not registered!</b>";
}
my %data;
my $row = 1;   
if($DBI::err){ $r->print( t_box($DBerror) ) if $cf->{DEBUG}; }
if($stmt =~ /^\s*select/i){
    my $rl_names = $sth->{NAME}; # ref to array col names
        while(my @results = $sth->fetchrow){
           
            if($DBI::err){
            $r->print( t_box($DBI::err) ) if $cf->{DEBUG};
            last;
            }
             foreach my $field_name (@$rl_names){
             my $name = shift @results;
             $data{$row}{$field_name} = $name;
                         $check{$field_name} = $name;
            }


            $row++;
        }
    $sth->finish;
}


my @boxes;
my $rows;
my $i;
if($DBerror){
 
 $r->print( t_box($DBerror) ) if $cf->{DEBUG};
 &er_notice( "There db function of my_content is not working, error $DBerror", $r);
} else {


    foreach my $d (sort keys %data) {
     push @boxes, $code->( $data{$d} );
    }
  
    my $content;
   
    for( $i = 0; $i <= $#boxes;) {
        for (0..7) {
            $rows .=  "$boxes[$i]" if $boxes[$i];
            $i++;
        }
    $rows .= '<td/><td>';
        #$j = 0; my $j = 0; $j < 5 ; $j++
    }

     $content .=  $rows . "</td>";
           
}
return  $content;

}



###############################################################
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> #
#                                                             #
#    The my_struc function takes 2 hash refs,                 #
#                                                             #
# the data_hs_ref1 + hs_ref2 and returns                      #
# hs_ref2 with every col of a table as an array ref like so:  #    
#         $hr_ref2->{tbl}{column_name}[value] or              #
#         @{$hr_ref2->{tbl}{column_name}} the whole column    #
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
###############################################################

sub my_struc {
my ($data, $hs, $r) = @_;


    foreach my $i (sort keys %$data ) {
          foreach my $j (keys %{$data->{$i}}   ) {
                push @{$hs->{tbl}{$j}} , $data->{$i}{$j};
              }
    }

    foreach my $i (keys %{$hs->{tbl}} ) {
          #$r->print( t_box("Row = $i") ) if $cf->{DEBUG};
          foreach ( @{$hs->{tbl}{$i}}  ) {
          #$r->print(  "<blockquote><B>$i</B>  =  $_</blockquote><br/>" ) if $cf->{DEBUG};
          }
    }

return $hs;
}

###############################################
#>>> my_dbValuesHash >>>>>>>>>>>>>>>>>>>>>>>>>#
#                                             #
# returns all the values in a hash of hashs   #
# with the first hash as an index for each row
# works well with my_struc  function          #
#                                             #
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
###############################################

sub my_dbValuesHash {

my ($stmt, $dbh, $r) = @_;
my $sth = $dbh->prepare($stmt);
if($DBI::err){ my $DBerror = "$DBI::errstr"; }
    my $retst = $sth->execute();
if (!$retst){
$DBerror = "<B>You are not registered!</b>";
}
my %data;
my $row = 1;   
if($DBI::err){
$r->print( t_box($DBerror) ) if $cf->{DEBUG};
&er_notice("The my_dbValuesHash is not working there was a db error $DBerror, $DBI::err, $DBI::errstr" , $r);
}
if($stmt =~ /^\s*select/i){
    my $rl_names = $sth->{NAME}; # ref to array col names
        while(my @results = $sth->fetchrow){
           
            if($DBI::err){
            $r->print( t_box($DBI::err) ) if $cf->{DEBUG};
            last;
            }
             foreach my $field_name (@$rl_names){
             my $name = shift @results;
             $data{$row}{$field_name} = $name;
                         $check{$field_name} = $name;
            }
                #if($check{'user_id'} eq $baked{'sessionID'}[2]) {
                #    $fname  = $check{first};
                #    $lname  = $check{last};
                #}

            $row++;
        }
    $sth->finish;
}
#$dbh->commit;
#>         PgSQL ENDS
#>         Main page creation!

#my @boxes;
#my $rows;
#my $content;

if($DBerror){ 
 $r->print( t_box($DBerror) ) if $cf->{DEBUG};
} else {

#    foreach my $d (sort keys %data) {
#     push @boxes, $code->( $data{$d} );
#    }
#    $content = "<table width=90% align=center valign=top><tr align=center>";
#   
#    for(my $i = 0; $i < $#boxes;) {
#        for ($j = 1; $j < 6; $j++) {
#            $rows .=  "<td align=center valign=top>$boxes[$i]</td>" if $boxes[$i];
#            $i++;
#        }
#    $rows .= '</tr></table><table width=90% align=center valign=top><tr align=center>';
#        $j = 0;
#    }
#  $content .=  $rows . "</tr></table><p></p>";
           
return \%data;
}

}


##############################################
sub my_getCookie {
my $cookies = shift;
my $size;
my @values;
my %baked;
#>> Get Cookies
foreach my $name (keys %$cookies){

                       $size = length($cookies->{$name}->value);
                       $baked{$name} = [] unless exists $baked{$name};
                       @values = $cookies->{$name}->value;
               for (my $i=0; $i <= $size; $i++){
                       push @{$baked{$name}}, $values[$i];
                     
               }

}

return \%baked;
#>> Cookie values are stored in array[n], $baked->{name_of_cookie}[values]

}
#################################################################
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>##
#                                                              ##
#  NOT USED: TESTING registry scripts being moved inside the   ##
#   the main apache handler, but buggy, still NOT WORKING      ##
#                                                              ##
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>##
#################################################################

sub my_initializeValues {
  my ($ag, $cf, $ret, $r ) = @_ ;
my ($title, $date, $body,
   $flag_group, $flag, $user_id,
   $category, $stat_group, $stat,
   $butt_val, $hidden, $review ) ;
                                 
        $butt_val = $ag->{'sendit'};
        $review   = $ag->{'review'};
        $title    = my_cl( $ag->{'title'} );
        $body     = my_cl( $ag->{'body'} );
        $flag     = my_cl( $ag->{'flag'} );
        $category = my_cl( $ag->{'category'} );
        $stat     = $ag->{'stat'};

       if($butt_val =~/Edit Data/) {$review = "";}
       if(($butt_val =~/Submit Data/) && ($review >0)) {
       my $sql = "INSERT INTO blogs VALUES ( DEFAULT, NOW(), '$title', '$body', '$baked{sessionID}[2]','$flag', '$category', '$stat')";
       #&my_dbValue($sql, my_dbh($cf), $r);
       &my_printThanks;
       }
      
       $title    = &my_textField("title", 200, 30, $title);
       $category = &my_textField("category", 100, 20, $category);

       if(!$review) {
                $flag_group = CGI::radio_group( -name =>'flag',
                                          -default =>'Private',
                                          -values =>['All','Friends','Private'],
                                       );
                $stat_group = CGI::radio_group( -name =>'stat',
                                          -default =>'Draft',
                                          -values =>['Draft','Post'],
                                         
                                       );

                $buttons = CGI::submit( -name=>"sendit",
                               -value => "Submit My Data");
                $hidden = ""; #Clear $hidden
              
       } else {

                $flag_group = CGI::radio_group( -name =>'flag',
                                          -default =>'$flag',
                                          -values =>['All','Friends','Private'],
                                       );
                $stat_group = CGI::radio_group( -name =>'stat',
                                          -default =>'$stat',
                                          -values =>['Draft','Post'],
                                         
                                       );
                $hidden .= CGI::hidden( -name=>"review",
                                  -value =>"$review");
                $buttons = CGI::submit( -name=>"sendit",
                                  -value=> "Edit Data");
                $buttons .= CGI::submit( -name=>"sendit",
                               -value =>"Submit Data");
              
              
       }

$r->print( &my_printForm($title, $date, $body, $flag_group, $flag, $user_id, $category, $stat_group, $stat, $butt_val, $hidden, $review) ) unless $button =~ /Submit Data/;
}


sub my_printThanks {

print t_box( "<b>Your blog titled: $title -  has been saved in your JoyBlog Database!</b>", $r);

}


sub my_printForm {
my ($title, $date, $body,
   $flag_group, $flag, $user_id,
   $category, $stat_group, $stat,
   $butt_val, $hidden, $review )
   =  @_ ;

my $mydate = scalar localtime;     
return <<HTML;

       <FORM NAME="blog.pl" METHOD="GET">
       <INPUT TYPE="HIDDEN" NAME="review" VALUE="1">
       $hidden
       <TABLE width=90% align=center>
       <TR><td colspan=2 align=left class="blue">Enter your data</td></TR>
       <TR>
          <TD colspan=2 class=silver>Date:  $mydate <INPUT TYPE="HIDDEN" NAME="date" VALUE="$mydate"> </TD>
       </TR>
       <TR>
          <TD class=silver>Title:  $title  Category: $category</td>
       </TR>
        <TR>
        <TD colspan=2 align=left class=silver><TEXTAREA NAME="body" rows="20" cols="60">$body</TEXTAREA></TD>
       </TR>
       <TR>
          <TD colspan=2 align=left class=silver>Who can view your blog: $flag_group</TD>
       </TR>
        <TR>
          <TD colspand=2 align=left class=silver>NOTE: defaults are set to "private" & "draft": $stat_group</td>
       </TR>
    <TR>
           <TD align =left class=silver> $buttons </TD>
       </TR>
       </TABLE>
       </FORM>
      
HTML
}

sub my_textField {
       my($name, $max, $size, $value, $hidden, $review) = @_;
       my $field;
       $hidden .= CGI::hidden( -name=>$name, -value=>$value);

       if(!$review){
               $field = CGI::textfield( -name=> $name,
                       -id=> $name,
                       -maxlength   =>$max,
                       -size =>$size,
                       -value =>$value);
       } else {
        $field = $value;
       }
       return($field);
}





###################################################################################
###################################################################################
#                  HTML SUBS: SET CLICK TABS, LOGIN, CSS                         ##
#                  BODY OF HTML PAGE WITH AJAX & GOOGLE                          ##
###################################################################################
###################################################################################
#>>    This sub make visible the Tabs on the main page, based on the what the user has clicked

sub set_click {
my ($q, $cf) = @_;
if($q->{action}    =~ /(v_blog).*/)   {$cf->{click}{Blogs}    = 'click' ;}
elsif($q->{action} eq 'v_care_list')  {$cf->{click}{CareBox}  = 'click' ;}
elsif($q->{action} eq 'Suggestion')   {$cf->{click}{Suggestion}     = 'click' ;}
elsif($q->{action} eq 'v_monks_list') {$cf->{click}{Memes}    = 'click' ;}
elsif($q->{action} =~ /(v_pic).*/)    {$cf->{click}{Pics}     = 'click' ;}
elsif($q->{action} eq 'Profiles' )    {$cd->{click}{Profiles} = 'click' ;}
else { $cf->{click} = undef;}
}

sub my_login {
my ($cf, $msg) = @_;
return <<"HTML";

<table width=90% valign=top align=center>
<tbody><tr><td align=left>
<form action="$cf->{url_perl}" method="post" onsubmit="return checkLogin();">
  <font size=1 color=black>email</font>
  <input type="text" name="email" size="12" id="eml">
  <font size=1 color=black>pwd</font>
  <input type="password" name="password" id="pwd" size="12"> 
  <input type="submit" name="login" value="Sign In">
</form></td>
<td align=left>  $msg  </td></tr>
</tbody>
</table>


HTML
}

sub my_html {
my $cf = shift;
my $html = <<"END";

<table width=90% align=center class="topbot">
<tbody><tr align=center>
<!----- START of LEFT COLUM --->
<td valign=top class="rightdot">

<script language="javascript" src="http://www.thefreedictionary.com/_/WoD/js1.aspx?type=&target=_top"></script>
</div>
<!--end of Word of the Day-->
<br>
<!--Article of the Day by TheFreeDictionary.com-->
<!-- div style="width:350px;position:relative;background-color:;padding:4px">
<div style="font:bold 12pt '';color:#000000">Article of the Day</div>
<style>
#ArticleOfTheDay {width:100%;border:1px #000000 solid;background-color:}
#ArticleOfTheDay H3 {margin-top:0px;font:bold 12pt '';color:#000000}
#ArticleOfTheDay TD {font:normal 10pt '';color:#000000}
#ArticleOfTheDay A {color:#0000FF}
</style --><b><font color="gray">Article of the Day</font></b>
<script language="javascript"
src="http://www.thefreedictionary.com/_/WoD/js1.aspx?type=article&target=_top"></script>
</div>
<!--end of Article of the Day-->
<!--This Day in History by TheFreeDictionary.com-->

<!-- div style="width:350px;position:relative;background-color:;padding:4px">
<div style="font:bold 12pt '';color:#000000">This Day in History</div>
<style>
#TodaysHistory {width:100%;border:1px #000000 solid;background-color:}
#TodaysHistory H3 {margin-top:0px;font:bold 12pt '';color:#000000}
#TodaysHistory TD {font:normal 10pt '';color:#000000}
#TodaysHistory A {color:#0000FF}
</style --><b><font color="gray">This Day in History</font></b>
<script language="javascript"
src="http://www.thefreedictionary.com/_/WoD/js1.aspx?type=history&target=_top"></script>
</div>
<!--end of This Day in History-->

<!--Today's Birthday by TheFreeDictionary.com-->
<!-- div style="width:350px;position:relative;background-color:;padding:4px">
<div style="font:bold 12pt '';color:#000000">Today's Birthday</div>
<style>
#TodaysBirthday {width:100%;border:1px #000000 solid;background-color:}
#TodaysBirthday H3 {margin-top:0px;font:bold 12pt '';color:#000000}
#TodaysBirthday TD {font:normal 10pt '';color:#000000}
#TodaysBirthday A {color:#0000FF}
</style --><b><font color="gray">Today's Birthday</font></b>
<script language="javascript"
src="http://www.thefreedictionary.com/_/WoD/js1.aspx?type=birthday&target=_top"></script>
</div>
<!-- end of Today's Birthday-->

</td>
<!--  -----------END OF LEFT COLUMN -->

<!-- ----------- START OF RIGHT COLUMN  ------------ -->
<td valign="top">

<!--Quotation of the Day by TheFreeDictionary.com-->
<!-- div style="width:350px;position:relative;background-color:;padding:4px">
<div style="font:bold 12pt '';color:#000000">Quotation of the Day</div>
<style>
#QuoteOfTheDay {width:100%;border:1px #000000 solid;background-color:}
#QuoteOfTheDay TD {font:normal 10pt '';color:#000000}
#QuoteOfTheDay A {color:#0000FF}
</style --><b><font color="gray">Quotation of the Day</font></b>
<script language="javascript"
src="http://www.thefreedictionary.com/_/WoD/js1.aspx?type=quote&target=_top"></script>
</div>
<!--end of Quotation of the Day-->

<!-- Google Ajax -->
<div id="searchcontrol"/></div>

<!--dictionary lookup box by TheFreeDictionary.com-->
<style>#dictionarybox TD, INPUT, SELECT {font-size:10pt;}</style>
<form action="http://www.thefreedictionary.com/_/partner.aspx" method=get target="_top" name=dictionary
style="display:inline;margin:0">

<table id=dictionarybox cellspacing=0 cellpadding=3 style="border:0px #999999 solid;font-family:;width:230px;background-color:;color:#000000"><tr>
<td bgcolor="#FFFFFF" style="border-bottom:1px #000000 solid"><img src="http://img.tfd.com/Help.gif" width=25 height=25></td>
<td bgcolor="#FFFFFF" style="border-bottom:1px #000000 solid" colspan=2 nowrap><a
style="text-decoration:none;color:#000000" href="http://www.thefreedictionary.com"><div style="font-size:12pt;color:#999999"><b>Online Reference</b></div>
<div style="font-size:8pt">Dictionary, Encyclopedia & more</div></a></td></tr>
<tr><td align=right>Word:</td><td colspan=2><input name=Word value="" size=26></td></tr>
<tr><td align=right>Look in:</td><td colspan=2 style="font-size:8pt;text-align:left" id="boxsource_td"><style>#boxsource_td A {color:#000000;text-decoration:none}</style>
<!--[if IE]><style>#boxsource_td INPUT {height:12pt}</style><![endif]-->
<input type=radio name=Set value="www" checked><a href="http://www.thefreedictionary.com">Dictionary & thesaurus</a><br>
<input type=radio name=Set value="computing-dictionary"><a href="http://computing-dictionary.thefreedictionary.com">Computing Dictionary</a><br>

<input type=radio name=Set value="medical-dictionary"><a href="http://medical-dictionary.thefreedictionary.com">Medical Dictionary</a><br>
<input type=radio name=Set value="legal-dictionary"><a href="http://legal-dictionary.thefreedictionary.com">Legal Dictionary</a><br>
<input type=radio name=Set value="financial-dictionary"><a href="http://financial-dictionary.thefreedictionary.com">Financial Dictionary</a><br>
<input type=radio name=Set value="acronyms"><a href="http://acronyms.thefreedictionary.com">Acronyms</a><br>
<input type=radio name=Set value="idioms"><a href="http://idioms.thefreedictionary.com">Idioms</a><br>
<input type=radio name=Set value="encyclopedia"><a href="http://encyclopedia.thefreedictionary.com">Wikipedia Encyclopedia</a><br>
<input type=radio name=Set value="columbia"><a href="http://columbia.thefreedictionary.com">Columbia Encyclopedia</a></td></tr><tr><td align=right>by:</td>
<td><select name=mode><option value="">Word<option value="?s">Starts with<option value="?e">Ends with<option value="?d">Mentions</select></td>

<td align=right><input type=submit name=submit value="Look it up"></td></tr></table></form>
<!--end of dictionary lookup box-->

<!--Hangman by TheFreeDictionary.com-->
<div style="width:350px;position:relative;background-color:;padding:4px">
<div style="font:bold 12pt '';color:#999999">Hangman</div>
<style>
#Hangman {border:0px #000000 solid;background-color:;height:120px}
</style>
<iframe id=Hangman src="http://www.thefreedictionary.com/_/WoD/hangman.aspx?#,x000000,x0000FF,10pt,''" width="100%" scrolling="no" frameborder="0"></iframe>
</div>
<!--end of Hangman-->

<!--In the News by TheFreeDictionary.com-->
<!-- div style="width:350px;position:relative;background-color:;padding:4px">
<div style="font:bold 12pt '';color:#000000">In the News</div>
<style>
#InTheNews {width:100%;border:1px #000000 solid;background-color:}
#InTheNews H3 {margin-top:0px;font:bold 12pt '';color:#000000}
#InTheNews TD {font:normal 10pt '';color:#000000}
#InTheNews A {color:#0000FF}
</style --><b><font color="gray">In the News</font></b>

<script language="javascript"
src="http://www.thefreedictionary.com/_/WoD/js1.aspx?type=news&target=_top"></script>
</div>
<!--end of In the News-->

<!--Match Up by TheFreeDictionary.com-->
<div style="width:350px;position:relative;background-color:;padding:4px">
<div style="font:bold 12pt '';color:#999999">Match Up</div>
<style>
#MatchUp {width:100%;border:0px #999999 solid;background-color:}
#MatchUp TD {font:normal 10pt '';color:#000000}
#MatchUp A {color:#0000FF}
#tfd_MatchUp INPUT.tfd_txt {border:0px black solid;height:16pt;font-size:10pt;width:100px;cursor:pointer;margin-top:2px;margin-right:4px;text-align:center}
</style>
<form name=SynMatch method=get action="http://www.thefreedictionary.com/_/MatchUp.aspx" style="display:inline;margin:0" target="_top">
    <table align=center id=MatchUp>
    <tr><td>
    <script language="javascript"
    src="http://www.thefreedictionary.com/_/WoD/js1.aspx?type=matchup"></script>
    Match each word in the left column with its synonym on the right. When finished, click Answer to see the results. Good luck!<br><br><center>

    <input type=button value="Clear" onclick="tfd_mw_clear()">&nbsp;<input type=submit value="Answer" onclick="this.form.res.value=tfd_mw_answers"></center>
    </td>
    </tr>
    </table>
    </form>
    </div>
<!--end of Match Up-->
<!-- END OF TR on main TABLE
</td>
</tr>

<!-- START OF FOOTER TABLE -->
<!-- footer starts -->
<tr valign="center" colspan="2"><td coldspan="2"><a href="$cf->{url_perl}">Sign in</a> | <a href="http://mail.google.com/a/mplib.org/"> Joymail</a> | <a href="http://www.google.com/calendar/hosted/mplib.org/"> Calendar </a> | <a href="http://criticaltolerance.org"> CT</a> | <a href="http://www.dailykos.com">Kos</a> | <a href="http://www.bbc.com">BBC</a> | <a href="http://www.google.com">Google</a> <p>Designed by <a href="mailto:$cf->{admin_email}">CT::Projects - Bliss you!</a>
</td><td align=left><a href="http://www.perl.org"><img  src="/images/perlpowered.png" alt="The World's Greatest Programming Tool" border=0></a>
</td></tr></tbody>
</table>
<!-- footer ends -->

<!-- END OF INNER BODY TABLE -->
</td></tr></tbody>
</table>
</body>
</html>
END
}

sub my_css {
my $cf = shift;
return <<"CSS";
<html><title>$cf->{title}</title>
<style type="text/css">
<!--
H1, H2, {color:#000066; font-family: verdana, arial, sans-serif;}
H3, H4, H5, H6 {color: black; font-family: verdana, arial, sans-serif;}
P {color: black; font-family: Verdana, Arial, Sans-Serif; font-size: 12px;}
P.list {color: black; font-size: 10px; text-align: left; margin: 0.5em; width: 100px;}
P.listcenter {color: black; font-size: 11px; text-align: center; margin: 0.5em; width: 100px;}
BODY {background-color:#ffffff; background-attachment: fixed; color:navy ; margin-top: 0em; margin-left: 0em; font-size: 13px; line-height:18px}
TH, TD {margin-top: 2em; margin-left: 0; margin-right: 0; margin-bottom: 2em; font-family: Verdana, Arial, Sans-Serif; font-size: 12px;}
UL {margin-left: 0.5em; margin-right: 0; margin-bottom: 0.5em; margin-top: 1em;}
LI {list-style-type: none; color: black; font-family: Verdana, Arial, Sans-Serif; font-size: 11px; width: 430px; text-align: justify; margin-left: 20px; margin-top: 0.7em;}
LI.leftmenu {color: black; font-family: Verdana, Arial, Sans-Serif; font-size: 11px; list-style-type: none; margin-top: 0.2em; margin-left: 0; margin-right: 0; width: 80px; text-align: left;}
LI.quick {color: black; font-family: Verdana, Arial, Sans-Serif; font-size: 9px; width: auto; text-align: left;}
A:link    {text-decoration: none; color:333399; font-weight: bold;}
A:hover   {text-decoration: none; color:660066;}
A:visited {text-decoration: none; color:666666; font-weight: bold;}
A:visited:hover {color:6666FF;}
INPUT, SELECT {font-family: Verdana, Arial, Sans-Serif; font-size: 11px;}
HR {width: 450px; margin-left: 0;}
IMG.featureicon {float: left;}
IMG.rightmenu {margin-top: 4px;}
TD {background:#FFFFFF;}
TR {background:#FFFFFF;}
TABLE {background-color:#FFFFF; margin:0px; padding:1px;}
TD:hover.bgg {background:#CCCCCC;}
TD:hover.bgb {background:#9999FF;}
TH { background:#9999CC; font-family: Verdana; color:#FFFFFF;} 
TH.blue {background:#CCCCFF; font-family: Verdana; color:#FFFFFF; }
.blue   {background:#CCCCFF; font-family: Verdana; color:#FFFFFF; border:1px solid silver;}
.silver {background:#FFFFFF; font-family: Verdana; color: black; border:1px solid silver;  margin:  1px; padding: 2px;}
.double {background:#FFFFFF; font-family: Verdana; color: black; border:3px double silver; margin:  1px; padding: 2px;}
.dot    {background:#FFFFFF; font-family: Verdana; color: gray;  border:1px  dotted silver;  margin:  3px; padding: 2px;}
.topdot {background:#FFFFFF; font-family: Verdana; color: gray;  border-top:1px dotted silver;  margin:  3px; padding: 2px;}
.topbot {background:#FFFFFF; font-family: Verdana; color: gray;  border-top:1px solid silver;  border-bottom:1px solid silver; margin:  3px; padding: 2px;}
.botlr  {background:#FFFFFF; font-family: Verdana; color: gray;  border-right:1px solid silver; border-left:1px solid silver;  border-bottom:1px solid silver; margin:  3px; padding: 2px;}
.lefrit {background:#FFFFFF; font-family: Verdana; color: gray;  border-left:1px dotted silver;  border-right:1px dotted silver; margin:  2px; padding: 2px;}
.leftdot {background:#FFFFFF; font-family: Verdana; color: gray;  border-left: 1px dotted silver;  margin:  3px; padding: 2px;}
.rightdot {background:#FFFFFF; font-family: Verdana; color: gray;  border-right:1px dotted silver;  margin:  3px; padding: 2px;}
.bottomdot {background:#FFFFFF; font-family: Verdana; color: gray;  border-bottom:1px dotted silver;  margin:  3px; padding: 2px;}
.bottom {background:#FFFFFF; font-family: Verdana; color: gray;  border-bottom:1px solid silver;  margin:  3px; padding: 2px;}
.dash   {background:#FFFFFF; font-family: Verdana; color: black; border:1px dashed silver; margin:  3px; padding: 2px;}
.blog   {background:#FFFFFF; font-family: Sans-Serif; color: black; font-size: 14px; border:1px dashed silver; margin: 3px; padding: 2px}
.menu { font-size: 11px; text-align: center; color: #CCCCFF; background:#FFFFFF; border-bottom:0px solid white; border-top:1px solid silver; border-left:1px solid silver; border-right:1px solid silver; border-left:1px solid silver; padding: 4px;}
.menu a { font-size: 11px; text-align: center; text-decoration: none; color: #ffffff; background: #CCCCFF; padding: 4px; border-bottom:0px solid white;}
.menu  a:hover {color:pink; background: #ffffff; border-top:1px solid silver; border-bottom:0px solid white; border-right:1px solid silver; border-left:1px solid silver; margin:  0px; padding: 4px;}
.menu2 { font-size: 11px; text-align: center; color: #FFFFFF; background:#CCCCFF; border-bottom:0px solid white; padding: 4px;}
.menu2 a { font-size: 11px; text-align: center; text-decoration: none; color: #ffffff; background: #CCCCFF; padding: 4px; border-bottom:0px solid white;}
.menu2 a:hover {color:pink; background: #ffffff; border-top:1px solid silver; border-bottom:0px solid white; border-right:1px solid silver; border-left:1px solid silver; margin:  0px; padding: 4px;}
.click a {color:black; background: #ffffff; border-top:1px solid silver; border-bottom:0px solid white; border-right:1px solid silver; border-left:1px solid silver; margin:  0px; padding: 4px;}
-->
</style>
CSS
}

sub my_google {
my $data = <<'HTML';
<form action="http://www.google.com/search?hl=en&q=" method="get">
  <Font size=4 color=blue> Google</font>
  <input type="text" name="query" size="20">
  <input type="submit" value=" GoogleIt ">
 
</form>
HTML
}


1;


__END__

#foreach my $i(sort keys %$ses ) {
#  foreach my $j (keys %{$ses->{$i}}   ) {
#          push @{$cf->{ses}{$j}} , $ses->{$i}{$j};
#  }
#}
#
#foreach my $i (keys %{$cf->{ses}} ) {
#  #$r->print( t_box("Row = $i") );
#  foreach ( @{$cf->{ses}{$i}}  ) {
#  $r->print(  "<blockquote><B>$i</B>  =  $_</blockquote><br/>" );
#  }
#}
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#my $prof = my_struc( &my_dbValuesHash( "select email, password from profile where user_id=18", $dbh, $r), $hs, $cf, $r );
#
#my $emails = join " ", sort {$a cmp $b} @{$prof->{tbl}{email}};
#my $passwords  = join " ",  sort {$a cmp $b} @{$prof->{tbl}{password}};
#
#$r->print(  t_box($emails) );
#$r->print(  t_box($passwords) );
#
