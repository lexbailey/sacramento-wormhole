#!/usr/bin/perl
die "Please specify exactly one argument, the file to run.\n" unless @ARGV == 1;
$filename = $ARGV[0];
open(PROGFILE, $filename) or die "Cannot open file\n";
chomp(my @proglines = <PROGFILE>);

$curline = 0;

sub synerror{
    ($message) = @_;
    die "Syntax error in " . $proglines[$curline] . ":\n$message\n";
}
sub get_range{
    ($args) = @_;
    if($args =~ /^[\t ]*(\d+)\.\.(\d+)(.*)$/){
        return ($1, $2, $3)
    }
    else{synerror("Expected range when parsing $args")}
}

sub get_number{
    ($args) = @_;
    if($args =~ /^[\t ]*(\d+)(.*)$/){
        return ($1, $2)
    }
    else{synerror("Expected number when parsing $args")}
}

sub assert_empty{
    ($str) = @_;
    synerror("Trailing data after arguments: $str") unless ($str=~/^[\t ]*$/)
}

sub debug{
    print "$_\n" for @_
}

sub swh_copy{
    ($args) = @_;
    ($start, $end, $args) = get_range($args);
    ($after, $args) = get_number($args);
    assert_empty($args);
    $start -=1;
    $end -=1;
    if ($after-1 < $curline){ $curline += $end-$start+1}
    splice @proglines, $after, 0, @proglines[$start..$end];
}

sub swh_append{
    ($args) = @_;
    ($to, $args) = get_number($args);
    ($from, $args) = get_number($args);
    assert_empty($args);
    $to -=1;
    $from -=1;
    $proglines[$to] .= $proglines[$from];
}

sub swh_delete{
    ($args) = @_;
    ($start, $end, $args) = get_range($args);
    assert_empty($args);
    $start -=1;
    $end -=1;
    if ($end < $curline){$curline -= ($end-$start)+1}
    elsif ($start < $curline){$curline = $start}

    splice @proglines, $start, $end-$start+1;
}

sub eval_expr{
    #TODO don't just accept any old perl bullshit
    return eval shift
}

sub expr_line{
    $proglines[$curline] = eval_expr($proglines[$curline])
}

sub executeline{
    ($line) = @_;
    #print("\n\nAbout to execute line number: $curline\n");
    if ($line =~/([^ ]+) +(.*)$/){
        $command = $1;
        $args = $2;
        if ($command eq "copy"){swh_copy($args)}
        elsif ($command eq "append"){swh_append($args)}
        elsif ($command eq "delete"){swh_delete($args)}
        else{expr_line()}
    }
    else{expr_line()}
    $curline += 1;
    #debug(@proglines);
    #print("Next line is: $curline\n");
}

while ($curline < @proglines){
    executeline($proglines[$curline]);
}

debug(@proglines)
