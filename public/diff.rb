#!/usr/bin/ruby -w

# svn-diff : CGI for viewing SVN diffs

require 'cgi'

SVN  = "/usr/bin/svn"
DIFF = "/usr/bin/diff"
# REPO = "svn://MODIFY_THIS/TO/POINT/TO/YOUR/REPO"
# REPO = "svn:///var/svn/mmgl/trunk"
REPO = 'file:///var/svn/mmgl/trunk'
#
# globals
#

$anchor = 0
$last_op = ' '
$left = []
$right = []

#
# helper for building the next row in the diff
#

def getDiffRow()
  anchor = ""
  result = ""
  if $left.length > 0 or $right.length > 0
    if $last_op != ' '
      if $left.length == 0
        clazz = " class='a'"
      elsif $right.length == 0
        clazz = " class='r'"
      else
        clazz = " class='m'"
      end
      anchor << <<EOF
<a name="#{$anchor}"/><a href="##{$anchor-1}">&uarr;&uarr;</a> <a href="##{$anchor+1}">&darr;&darr;</a>
EOF
      $anchor += 1
    else
      clazz = ""
    end
    result = <<EOF
<tr#{clazz}><td>#{anchor}</td><td>#{$left.join("\n")}</td><td>#{$right.join("\n")}</td></tr>
EOF
  end
  result
end

#
# build the diff
#

def getDiff(repo, file, rev1, rev2)
  result = ""

  diff = `#{SVN} diff -r #{rev1}:#{rev2} #{repo}/#{file}@#{rev1} --diff-cmd #{DIFF} -x '-w -U 10000'`.split("\n")
  raise "svn diff failed" if $? != 0
  
  index = diff.shift
  equals = diff.shift
  header1 = diff.shift
  if header1 =~ /^---/
    result << "<p><a href='#0' style='text-decoration:none'>&darr;&darr;</a></p>\n"
    result << "<table class='diff' width='80%'>"
    result << "<tr height='2'><td/><td width='48%'/><td width='48%'/></tr>"
    
    # skip header2 and range
    diff.shift
    diff.shift
    
    diff.each do |line|
      op = line[0,1]
      line = line[1..-1]
      
      if (($last_op != ' ' and op == ' ') or ($last_op == ' ' and op != ' '))
        result << getDiffRow
        $left.clear
        $right.clear
      end
      
      # truncate and escape
      line[62..-1] = "..." if line.length > 65
      line = CGI.escapeHTML(line)

      case op
      when ' '
        $left.push(line)
        $right.push(line)
      when '-' then $left.push(line)
      when '+' then $right.push(line)
      end
      $last_op = op
    end

    result << getDiffRow
    result << "</table>"      
  else
    result = "<div class='error'>#{header1}</div>"
  end

  <<EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>#{file}, rev #{rev1}:#{rev2}</title>
        <style type="text/css">
          body {
            font : 11pt verdana;
            background : white;
          }
          .error {
            color : red; 
          }
          .diff {
            font-size : 9pt;
            font-family : "lucida console", "courier new", monospace;
            white-space : pre;
            border : 1px solid black;
            border-collapse : collapse;
            line-height : 110%;
          }  
          .diff td {
            border : none;
            padding : 0px 10px;
            margin : 0px;
          }
          .diff td a {
            text-decoration: none;
          }
          .a { background : #bbffbb; }
          .r { background : #ffbbbb; }
          .m { background : #bbbbff; }
        </style>
    </head>
    <body>
        <h3>Subversion diff on #{file}, rev #{rev1}:#{rev2}</h3>
#{result}
    </body>
</html>
EOF
end


#
# main - handles either command line or CGI
#

cgi = CGI.new
begin
  if cgi.server_software
    file = cgi.params['file']
    rev = cgi.params['rev']
    raise "bad file param" if !file || file.length == 0
    raise "bad rev param" if !rev || rev.length == 0
    file = file[0]
    rev = rev[0]
  else
    file = ARGV.shift
    rev = ARGV.shift
  end

  raise "bad file param" if file.length == 0
  raise "bad rev param" if rev.length == 0

  rev = rev.to_i
  cgi.out("status" => "OK") {
    getDiff(REPO, file, rev - 1, rev)
  }
rescue StandardError => e
  cgi.out("status" => "SERVER_ERROR") {
    <<EOF
<html>
  <body style="color:red">
    <p>error : #{e.message}</p>
<pre>#{e.backtrace.collect { |x| CGI.escapeHTML(x) }.join("\n")}
</pre>
  </body>
</html>
EOF
  }
end

