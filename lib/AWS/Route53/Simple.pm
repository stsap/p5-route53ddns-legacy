package AWS::Route53::Simple;

use strict;
use warnings;
use 5.6.1;  # for "use constant"
use Digest::SHA qw(hmac_sha1 hmac_sha256);
use HTTP::Request;
use LWP::UserAgent;
use MIME::Base64 qw(encode_base64);
use URI;
use JSON;
use XML::Simple;
use Data::Dumper;

use constant DEFAULTS => {
    BASEURL => "amazonaws.com",
    SERVICE => "route53",
    REGION => "us-east-1",
    SIGNATUREMETHOD => "HmacSHA256",
    SIGNATUREVERSION => 2,
    VERSION => "2013-04-01",
    RETURNTYPE => "RAW"
};

use constant ACTIONS => {
    "CreateHostedZone" => {
        "Method" => "POST",
        "ActionPath" => "hostedzone/__ZoneID__",
        "Required" => {
            "ZoneID" => 1,
            "Content" => 1
        }
    },
    "GetHostedZone" => {
        "Method" => "GET",
        "ActionPath" => "hostedzone/__ZoneID__",
        "Required" => {
            "ZoneID" => 1
        }
    },
    "ListHostedZones" => {
        "Method" => "GET",
        "ActionPath" => "hostedzone",
        "Required" => {}
    },
    "DeleteHostedZone" => {
        "Method" => "DELETE",
        "ActionPath" => "hostedzone/__ZoneID__",
        "Required" => {
            "ZoneID" => 1
        }
    },
    "ChangeResourceRecordSets" => {
        "Method" => "POST",
        "ActionPath" => "hostedzone/__ZoneID__/rrset",
        "Required" => {
            "ZoneID" => 1,
            "Content" => 1
        }
    },
    "ListResourceRecordSets" => {
        "Method" => "GET",
        "ActionPath" => "hostedzone/__ZoneID__/rrset",
        "Required" => {
            "ZoneID" => 1
        }
    },
    "GetChange" => {
        "Method" => "GET",
        "ActionPath" => "change/__ChangeID__",
        "Required" => {
            "change" => 1,
            "ChangeID" => 1
        }
    },
    "CreateHealthCheck" => {
        "Method" => "POST",
        "ActionPath" => "healthcheck",
        "Required" => {
            "Content" => 1
        }
    },
    "GetHealthCheck" => {
        "Method" => "GET",
        "ActionPath" => "healthcheck/__HealthCheckID__",
        "Required" => {
            "HealthCheckID" => 1
        }
    },
    "ListHealthChecks" => {
        "Method" => "GET",
        "ActionPath" => "healthcheck"
    },
    "DeleteHealthCheck" => {
        "Method" => "DELETE",
        "ActionPath" => "healthcheck/__HealthCheckID__",
        "Required" => {
            "HealthCheckID" => 1
        }
    }
};

## @cmethod [public] [$] new(@params)
# @param params [%] initialize parameters
# - AccessKey => AWS API Access Key
# - SecretAccessKey => AWS API Secret Access Key
# - baseUrl => AWS API base url
# - Service => AWS Service name.
# - Action => API Action name.
# - SignatureMethod => AWS API Authenticating method(HmacSHA256/HmacSHA1)
# - SignatureVersion => AWS API Authenticating version.
# - Version => AWS API Version
# - ReturnType => API Returning data type
# - debug => debug mode
# @return [$] AWS::Route53::Simple instance
sub new {
    my $class = shift;
    my %params = (
        "AccessKey" => "",
        "SecretAccessKey" => "",
        # http://docs.aws.amazon.com/Route53/latest/APIReference/
        "Action" => "",
        # PERL | JSON | RAW(xml)
        "ReturnType" => "",
        "SignatureMethod" => "",
        "SignatureVersion" => "",
        "Version" => "",
        "Service" => "",
        "use_ntp" => "",
        "debug" => 0,
        @_
    );
    my $self = bless(\%params, $class);
    $self->_setProperties();
    return $self;
}

## @method [public] [$] setAction(@params)
# @alias action
# set the Route53 API Action
# @param action [$] action name
# @return [$] AWS::Route53::Simple instance
# @see http://docs.aws.amazon.com/Route53/latest/APIReference/
sub setAction {
    $_[0]->_setAction($_[1]);
    return $_[0];
}
sub action {
    $_[0]->_setAction($_[1]);
    return $_[0];
}

## @method [public] [$] getActions()
# @alias actions
# describes the parameters that can be specified in the action method
sub getActions { return $_[0]->_getActions(); }
sub actions { return $_[0]->_getActions(); }

## @method [public] [$] setSignatureMethod(@params)
# @alias signatureMethod
# set the Route53 authenticate signature method.
# @param method [$] signature method name(HmacSHA1 / HmacSHA256)
# @return [$] AWS::Route53::Simple instance
sub setSignatureMethod {
    $_[0]->_setSignatureMethod($_[1]);
    return $_[0];
}
sub signatureMethod {
    $_[0]->_setSignatureMethod($_[1]);
    return $_[0];
}

## @method [public] [$] setSignatureVersion(@params)
# @alias signatureVersion
# set the Route53 authenticating API version
# @param version [$] authenticating api version(ex. 2)
# @return [$] AWS::Route53::Simple instance
sub setSignatureVersion {
    $_[0]->_setSignatureVersion($_[1]);
    return $_[0];
}
sub signatureVersion {
    $_[0]->_setSignatureVersion($_[1]);
    return $_[0];
}

## @method [public] [$] setVersion(@params)
# @alias version
# set the Route53 API Version
# @param version [$] api version(ex. 2013-04-01)
# @return [$] AWS::Route53::Simple instance
sub setVersion {
    $_[0]->_setVersion($_[1]);
    return $_[0];
}
sub version {
    $_[0]->_setVersion($_[1]);
    return $_[0];
}

## @method [public] [$] setReturnType(@params)
# @alias returnType
# Specifies the format of the value that is returned by the execution of the "post" method
# @param type [$] XML or RAW|JSON|PERL
# @return [$] AWS::Route53::Simple instance
sub setReturnType {
    $_[0]->_setReturnType($_[1]);
    return $_[0];
}
sub returnType {
    $_[0]->_setReturnType($_[1]);
    return $_[0];
}

## @method [public] [$] setBaseUrl(@params)
# @alias baseUrl
# set the AWS API base url
# @default amazonaws.com
# @param url [$] AWS API base url
# @return [$] AWS::Route53::Simple instance
sub setBaseUrl {
    $_[0]->_setBaseUrl($_[1]);
    return $_[0];
}
sub baseUrl {
    $_[0]->_setBaseUrl($_[1]);
    return $_[0];
}

## @method [public] [$] setService(@params)
# @alias service
# set the AWS Service name.
# @default route53
# @param service [$] service name
# @return [$] AWS::Route53::Simple instance
sub setService {
    $_[0]->_setService($_[1]);
    return $_[0];
}
sub service {
    $_[0]->_setService($_[1]);
    return $_[0];
}

## @method [public] [$] send(@params)
# send request for Amazon Route53 API
# @param req [$] (Optional) HTTP::Request instance
# @param params [$] request parameters hashref
# - ZoneID => request parameter.
# - ChangeID => request parameter.
# - HealthCheckID => request parameter.
# - Content => (Optional) request body content(XML).
# - request => (Optional) an HTTP::Request instance.
#               It is used in the request as such HTTP::Request object if specified.
# @param content [$] request body xml string
# @return [$]
sub send {
    my ($self, $params) = @_;
    my $req;

    if (not defined($params->{"request"}) or not exists($params->{"request"}) or not $params->{"request"}) {
        $self->_validateCredentials();
        $self->_validateAction();
        $req = $self->_request($params);
        if ($self->{"debug"}) {
            warn Dumper($req);
        }
    } else {
        $req = $params->{"request"};
    }

    $self->_validateReturnType();

    my $ua = LWP::UserAgent->new();
    my $res = $ua->request($req);
    if (not $res->is_success) {
        my $error = ($self->{"debug"}) ?
            $res->content: XML::Simple::XMLin($res->content)->{"Error"}->{"Message"};
        die($error);
    }

    if ($self->{"ReturnType"} =~ /^PERL$/msxi) {
        return XML::Simple::XMLin($res->content);
    } elsif ($self->{"ReturnType"} =~ /^JSON$/msxi) {
        return JSON::encode_json(XML::Simple::XMLin($res->content));
    } else {
        return $res->content;
    }
}


## @method [private] [$] _request(@params)
# generate HTTP::Request Instance
# @param params [$] parameters hashref
# - ZoneID => 
# - ChangeID => 
# - HealthCheckID => 
# - Content => 
# @return $ => HTTP::Request instance
sub _request {
    my $self = shift;
    my $params = shift;

    $params->{"method"} = ACTIONS->{$self->{"Action"}}->{"Method"};

    $params->{"Content"} = (not $params->{"Content"}) ? $self->{"Content"}: $params->{"Content"};
    $self->_validateRequestParameters($params);

    my $path = ACTIONS->{$self->{"Action"}}->{"ActionPath"};
    my @pathParams = $path =~ /__[^_]*__/msxg;
    foreach (@pathParams) {
        next if (not $_);
        (my $key = $_) =~ s/__//msxg;
        $path =~ s/$_/$params->{$key}/msx;
    }

    my $req = HTTP::Request->new(
        $params->{"method"},
        $self->_createURI({withScheme => 1})."/".$self->{"Version"}."/".$path
    );
    $req->header(
        "date" => $self->_timestamp(),
        "X-Amzn-Authorization" => "AWS3-HTTPS ".join(",",
            "AWSAccessKeyId=".$self->{"AccessKey"},
            "Algorithm=".$self->{"SignatureMethod"},
            "Signature=".$self->_createSignedParam()
        )
    );
    $req->content($params->{"Content"});
    return $req;
}

## @method [private] [$] _createSignedParam(@params)
# Generate AWS signature
# @return [$] hashed signature string
sub _createSignedParam {
    return encode_base64(($_[0]->{"SignatureMethod"} eq DEFAULTS->{"SIGNATUREMETHOD"}) ?
        hmac_sha256($_[0]->_timestamp(), $_[0]->{"SecretAccessKey"}):
        hmac_sha1($_[0]->_timestamp(), $_[0]->{"SecretAccessKey"})
    );
}

## @method [private] [$] _timestamp(@params)
# Generate time string that represents the current
# @param opts [\%] options hashref
# - use_ntp [$] 1=get times from NTP
# - ntp_server [$] the case of use_ntp is true, specify an NTP server that you want to see.
# @return [$] time string
sub _timestamp {
    my $self = shift;
    my $opts = shift;
    my $use_ntp = $self->{"use_ntp"} || $opts->{"use_ntp"};
    my @times = gmtime();
    if ($use_ntp) {
        my $server = $self->{"ntp_server"} || $opts->{"ntp_server"};
        my %ntp;
        eval {
            eval("use Net::NTP;");
            %ntp = get_ntp_response($server);
        };
        die($@) if ($@);
        @times = gmtime($ntp{"Transmit Timestamp"});
    }
        exit;
    my @weekdays = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my ($s, $m, $h, $d, $M, $Y, $wd) = (@times)[0..6];
    my $format = "%s, %02d %s %4d %02d:%02d:%02d GMT";
    return sprintf($format, $weekdays[$wd], $d, $months[$M], $Y += 1900, $h, $m, $s);
}

## @method [private] [$] _createURI(@params)
# Generate AWS API request uri
# @param param [\\%] parameters hash reference
# - withScheme => put the scheme to return value
# @return [$] URI string
sub _createURI {
    my $self = shift;
    my $param = shift;
    my $uri = URI->new("https://".join(".", $self->{"Service"}, $self->{"baseUrl"}));
    return ($param->{"withScheme"}) ? $uri->as_string: $uri->host;
}

## @method [private] _validateReturnType()
# check the specified return type
sub _validateReturnType {
    my $self = shift;
    if (not $self->{"ReturnType"}) {
        die("return type is required.");
    }
    if (not grep({$self->{"ReturnType"} =~ /$_/msxi} qw(PERL JSON RAW XML))) {
        die("unknown return type: ".$self->{"ReturnType"});
    }
}

## @method [private] _validateAction()
# check the specified action
sub _validateAction {
    my $self = shift;
    if (not $self->{"Action"}) {
        die("action is required.");
    }
    if (not grep({$self->{"Action"} eq $_} keys(%{ACTIONS()}))) {
        die("unknown action: ".$self->{"Action"});
    }
}

## @method [private] _validateRequestParameters(@params)
# check the specified request parameters
# @param params [\\%] request parameters hash reference
sub _validateRequestParameters {
    my $self = shift;
    my $params = shift;
    foreach (keys(%{ACTIONS->{$self->{"Action"}}->{"Required"}})) {
        if (ACTIONS->{$self->{"Action"}}->{"Required"}->{$_}) {
            die("parameter $_ is required.") if (not $params->{$_});
        }
    }
}

## @method [private] _validateCredentials()
# check AccessKey and SecretAccessKey includes in the initial parameter
sub _validateCredentials {
    my $self = shift;
    foreach (qw(AccessKey SecretAccessKey)) {
        die($_." is requred.") if (not $self->{$_});
    }
}

## @method [private] _setAction(@params)
# set the Route53 API Action
# @param action [$] action name
# @see http://docs.aws.amazon.com/Route53/latest/APIReference/
sub _setAction { $_[0]->{"Action"} = $_[1]; }

## @method [private] _setReturnType(@params)
# Specifies the format of the value that is returned by the execution of the "send" method
# @param type [$] XML or RAW|JSON|PERL
sub _setReturnType { $_[0]->{"ReturnType"} = $_[1]; }

## @method [private] _setSignatureMethod(@params)
# Specifies the AWS Authenticating Method
# @param type [$] method name
sub _setSignatureMethod { $_[0]->{"SignatureMethod"} = $_[1]; }

## @method [private] _setSignatureVersion(@params)
# Specifies the AWS Authenticating version
# @param version [$] version name
sub _setSignatureVersion { $_[0]->{"SignatureVersion"} = $_[1]; }

## @method [private] _setVersion(@params)
# Specifies the AWS API Version
# @param version [$] version name
sub _setVersion { $_[0]->{"Version"} = $_[1]; }

## @method [private] _setBaseUrl(@params)
# Specifies the AWS API base url
# @param url [$] url
sub _setBaseUrl { $_[0]->{"baseUrl"} = $_[1]; }

## @method [private] _setService(@params)
# Specifies the AWS Service name.
# @param service [$] service name
sub _setService { $_[0]->{"Service"} = $_[1]; }

## @method [private] _getActions()
# describes the parameters that can be specified in the "action" method.
sub _getActions { return keys(%{ACTIONS()}); }

## @method [private] _setProperties()
# sets the class properties
sub _setProperties {
    my $self = shift;
    foreach (qw(baseUrl Service ReturnType Action SignatureMethod SignatureVersion Version)) {
        next if ($self->{$_});
        $self->{$_} = DEFAULTS->{uc($_)};
    }
}

## @method [private] _xmlRRS(@params)
# @param params [\%] parameters hash reference
# - Name [$] DNS Record Name.
# - Type [$] DNS Record Type [A|AAAA|NS|MX|CNAME...etc]
# - TTL [$] DNS Record ttl.
# - Value [$|@] DNS Record Value[s].
sub _xmlRRS {
    my $self = shift;
    my $params = shift;
    my @vals;
    if (ref($params->{"Value"}) eq "ARRAY") {
        map({ push(@vals, "<Value>".$_."</Value>"); } @{$params->{"Value"}});
    } else {
        push(@vals, "<Value>".$params->{"Value"}."</Value>");
    }
    return <<"XML";
<ResourceRecordSet>
<Name>$params->{"Name"}</Name>
<Type>$params->{"Type"}</Type>
<TTL>$params->{"TTL"}</TTL>
<ResourceRecords>
<ResourceRecord>
@{[join($/, @vals)]}
</ResourceRecord>
</ResourceRecords>
</ResourceRecordSet>
XML
}

sub _xmlChange {
    my $self = shift;
    my $params = shift;
    return <<"XML";
<Change>
<Action>$params->{"Action"}</Action>
@{[$self->_xmlRRS($params)]}
</Change>
XML
}

sub _xmlChanges {
    my $self = shift;
    my $params = shift;

    my @ret;
    map ({ push(@ret, $self->_xmlChange($_)); } @{$params});
    return <<"XML";
<ChangeBatch>
<Changes>
@{[join("", @ret)]}
</Changes>
</ChangeBatch>
XML
}

sub _createXML {
    my $self = shift;
    my $params = shift;
    return <<"XML";
<$self->{"Action"}Request xmlns="https://$self->{'Service'}.$self->{'baseUrl'}/doc/$self->{'Version'}/">
@{[$self->_xmlChanges($params)]}
</$self->{"Action"}Request>
XML
}

## @method [public] [$] param(@params)
# generate content XML
# @params params [\@] parameters hashref - arrayref
# @see _xmlRRS()
sub param {
    my $self = shift;
    my $params = shift;
    die("params type is must be ARRAYREF.") if (ref($params) ne "ARRAY");
    $self->{"Content"} = <<"XML";
<?xml version="1.0" encoding="UTF-8" ?>
@{[$self->_createXML($params)]}
XML
    return $self;
}

1;
