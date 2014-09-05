use Test::More tests => 40;

use CGI::Test;

my $BASE = "http://server:18/cgi-bin";

my $ct = CGI::Test->new(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
);

ok 1, defined $ct;

my $page = $ct->GET("$BASE/getform");
ok 2, $page->is_ok;
ok 3, length $page->raw_content;
ok 4, $page->content_type =~ m|^text/html\b|;

my $forms = $page->forms;
ok 5, @$forms == 1;

my $form = $forms->[0];

my @names;
my $rg = $form->radio_groups;
ok 6, ref $rg && (@names = $rg->names) && 1;		# ok(x, 1, undef)
ok 7, @names == 1;

my $r_groupname = $names[0];
ok 8, $rg->is_groupname($r_groupname);
my @buttons = $rg->widgets_in($r_groupname);
ok 9, @buttons == 3;

my $cg = $form->checkbox_groups;
ok 10, ref $cg && (@names = $cg->names) && 1;
ok 11, @names == 2;

my $c_groupname = "skills";
ok 12, $cg->is_groupname($c_groupname);
@buttons = $cg->widgets_in($c_groupname);
ok 13, @buttons == 4 && $cg->widget_count($c_groupname) == 4;

ok 14, @{$form->inputs} == 4;		# 1 of each (field, area, passwd, file)
ok 15, @{$form->buttons} == 4;
ok 16, @{$form->menus} == 2;
ok 17, @{$form->checkboxes} == 5;

my $months = $form->menu_by_name("months");
ok 18, defined $months;
ok 19, !$months->is_popup;
ok 20, $months->selected_count == 1;
ok 21, @{$months->option_values} == 12;
ok 22, $months->is_selected("Jul");
ok 23, !$months->is_selected("Jan");

my $color = $form->menu_by_name("color");
ok 24, defined $color;
ok 25, $color->is_popup;
ok 26, $color->is_selected("white");		# implicit selection
ok 27, $color->selected_count == 1;
ok 28, $color->option_values->[0] eq "white";
ok 29, !$color->is_selected("black");

my @menus = $form->widgets_matching(sub { $_[0]->is_menu });
ok 30, @menus == 2;
my @radio = $form->radios_named("title");
ok 31, @radio == 3;

require URI;
ok 32, URI->new($form->action)->path eq "/cgi-bin/getform";
ok 33, $form->method eq "GET";
ok 34, $form->enctype eq "application/x-www-form-urlencoded";

my @submit = grep { $_->name !~ /^\./ } $form->submit_list;
ok 35, @submit == 2;

@buttons = $cg->widgets_in("no-such-group");
ok 36, @buttons == 0;
ok 37, 0 == $cg->widget_count("no-such-group");

my $new = $form->checkbox_by_name("new");
ok 38, defined $new;
ok 39, $new->is_checked;
ok 40, $new->is_standalone;

