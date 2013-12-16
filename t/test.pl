#!/usr/bin/perl

use Data::Dumper;
use DBI;
use JSON qw/encode_json decode_json/;

#==============================================================================
#  Lib Section 
#==============================================================================
{
	my  $DBH;
 	my  $EXT;
	sub getconnection{
		unless ($DBH){
			$DBH = DBI->connect('dbi:SQLite:dbname=:memory:');
		}
		return $DBH;
	}
	sub query{
		my $sql   = shift;
		my $param = shift;
		my $dbh = &getconnection();
		if($param){
			my $sth = $dbh->prepare($sql) or die $!;
			$sth->execute(@$param) or die $dbh->errstr();
		}else{
			$dbh->do($sql);
		}
	}
	sub select{
		my $sql   = shift;
		my $param = shift;
		my $dbh = &getconnection();
		my $sth = $dbh->prepare($sql) or die $!;
		$sth->execute(@$param) or die $sth->errstr;;
		my @data;
		while(my $row = $sth->fetchrow_hashref){
			push @data,$row;
		}
		return \@data;
	}
	sub find{
		my $sql   = shift;
		my $param = shift;
		my $jsons = shift;
		my $res = &select($sql,$param);
		my $line = $res->[0];
		for(@$jsons){
			$line->{$_} = decode_json($line->{$_}) if $line->{$_};
		}
		return $line;
	}
	sub load_extension{
		my $path = shift;
		unless($EXT->{$path}){
			my $dbh = &getconnection();
			$dbh->sqlite_enable_load_extension(1);
			$dbh->sqlite_load_extension($path) or die $dbh->errstr();
			$EXT->{$path}++;
		}
	}
	sub disconnect{
		$dbh->disconnect if $dbh;
	}

}

#==============================================================================
#  Data Section 
#==============================================================================
my $employee = {'tarou'=>{
		name => 'tarou',
		age  => 46,
		projects => ['prj a','prj b', 'prj c'],
		company  => {
			dept     => 1,
			position => 'manager'
		}
	},'jirou'=>{
		name => 'jirou',
		age  => 40,
		projects => ['prj a','prj b', 'prj c'],
		company  => {
			dept     => 2,
			position => 'manager'
		}
	},'saburou'=>{
		name => 'saburou',
		age  => 32,
		projects => ['prj a','prj b'],
		company  => {
			dept     => 1,
			position => 'project manager'
		}
	},'shirou'=>{
		name => 'shirou',
		age  => 32,
		projects => ['prj c'],
		company  => {
			dept     => 4,
			position => 'project manager'
		}
	},'gorou'=>{
		name => 'gorou',
		age  => 28,
		projects => ['prj a','prj b'],
		company  => {
			dept     => 3,
			position => 'project leader'
		}
	},'rokurou'=>{
		name => 'rokurou',
		age  => 24,
		projects => ['prj c'],
		company  => {
			dept     => 4,
			position => 'programer'
		}
	},'nanarou'=>{
		name => 'nanarou',
		age  => 22,
		projects => ['prj a','prj b'],
		company  => {
			dept     => 3,
			position => 'tester'
		}
	}};

#==============================================================================
#  Init Section 
#==============================================================================

&query("create table employee(
	empid INTEGER primary key AUTOINCREMENT,
	name text,
	attr text
)");
&query("create table dept(
	deptid int primary key ,
	name text
)");
our $dept = {
	1 => 'development group',
	2 => 'sales',
	3 => 'dev 1',
	4 => 'dev 2'
};
for(sort keys %$dept){
	&query("insert into dept values(?,?)",[$_,$dept->{$_}]);
}
for (sort keys %$employee){
	&query("insert into employee (name,attr) values(?,?)",[$_,encode_json($employee->{$_})]);
}
### load extension
&load_extension('parse_json.so');

#==============================================================================
#  Test Section 
#==============================================================================

use Test::More tests => 7;
### 1.select column parse number 
{	
	my $name = "tarou";
	my $emp = $employee->{$name};
	my $res = &find("select parse_json(attr,'age') as col1 from employee where name = ?",[$name]);
	is($emp->{age},$res->{col1},"select column parse number");
}
### 2.select column parse text
{	
	my $name = "tarou";
	my $emp = $employee->{$name};
	my $res = &find("select parse_json(attr,'name') as col1 from employee where name = ?",[$name]);
	is($emp->{name},$res->{col1},"select column parse text");
}
### 3.select deep column parse integer
{	
	my $name = "tarou";
	my $emp = $employee->{$name};
	my $res = &find("select parse_json(attr,'company.dept') as col1 from employee where name = ?",[$name]);
	is($emp->{company}->{dept},$res->{col1},"select deep column parse integer");
}
### 4.select deep column parse text
{	
	my $name = "tarou";
	my $emp = $employee->{$name};
	my $res = &find("select parse_json(attr,'company.position') as col1 from employee where name = ?",[$name]);
	is($emp->{company}->{position},$res->{col1},"select deep column parse text");
}
### 5.join parse column
{	
	my $res = &select("select a.name from employee a inner join dept b on cast(parse_json(a.attr,'company.dept') as INTEGER)  = b.deptid where b.name = ?",['dev 1']);
	is_deeply([{name => 'gorou'},{name=>'nanarou'}],$res,"join parse column with cast");
}
### 6.join parse column
{	
	my $name = "tarou";
	my $emp = $employee->{$name};
	my $res = &find("select parse_json(a.attr,'company.position') as position from employee a inner join dept b on cast(parse_json(a.attr,'company.dept') as INTEGER) = b.deptid where a.name = ?",[$name]);
	is($emp->{company}->{position},$res->{position},"join parse column and parse value");
}
### 7.select parse null column 
{	
	my $name = "tarou";
	my $emp = $employee->{$name};
	my $res = &find("select parse_json(attr,'xxxx') as col1 from employee where name = ?",[$name]);
	is(undef,$res->{col1},"select parse null column");
}

