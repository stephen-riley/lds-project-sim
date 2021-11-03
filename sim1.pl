$| = 1;

use strict;
use warnings;
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Clone 'clone';
use Getopt::Long;
use Term::ProgressBar::Simple;


my $SIM_ITERS = 100;
my $BATTLE_ITERS = 1000;

GetOptions(
    "sim-iterations:i" => \$SIM_ITERS,
    "battle-iterations:i" => \$BATTLE_ITERS,
);

die "Must specify --sim-iterations and --battle-iterations to run\n" unless $SIM_ITERS && $BATTLE_ITERS;

my %presidents;
my %pres;
my %winners;

# read all the data and populate the %pres list
my $h = <DATA>;
chomp $h;
my @headers = split( /\t/, $h );

while( <DATA> ) {
    chomp;

    my %f;
    @f{@headers} = split( /\t/ );
    $presidents{$f{President}} = \%f;
    $presidents{$f{President}}->{"survived_$_"} = 0 for( 1..4 );
}

my $progress = Term::ProgressBar::Simple->new( 4 * $SIM_ITERS );

foreach ( 1..$SIM_ITERS ) {
    %pres = %{ clone \%presidents };

    my @results;
    @results = conduct_round( 1, 21 );
    @results = conduct_round( 2, 8 );
    @results = conduct_round( 3, 8 );
    @results = conduct_round( 4, 7 );

    my $winner = $pres{ ( keys %pres )[0] };
    # say "Winner: " . uc( $winner->{President} );
    $winners{$winner->{President}}++;
}

say "\n";

say "Battle iterations:\t$BATTLE_ITERS";
say "Simulation runs:\t$SIM_ITERS";

say "";

say join( "\t", 'Name', 'Round 1 %', 'Round 2 %', 'Round 3 %', 'Round 4 %' );
foreach my $p ( sort final_sort values %presidents ) {
    print $p->{President};
    print "\t" . ( 100 * ( $p->{"survived_$_"} // 0 ) / $SIM_ITERS ) . '%' for ( 1..4 );
    print "\n";
}

sub final_sort {
    my $r;

    $r = $b->{survived_1} <=> $a->{survived_1};
    return $r unless $r == 0;
    $r = $b->{survived_2} <=> $a->{survived_2};
    return $r unless $r == 0;
    $r = $b->{survived_3} <=> $a->{survived_3};
    return $r unless $r == 0;
    $r = $b->{survived_4} <=> $a->{survived_4};
    return $r unless $r == 0;
    return $a->{President} cmp $b->{President};
}

sub conduct_round( $round, $attrition ) {
    $progress++;

    battle( $round );
    my @losers = @{ [ sort { $a->{r} <=> $b->{r} } values %pres ] }[ 0 .. ( $attrition-1) ];
    # say "Eliminated in round $round:";
    foreach my $p ( sort { $a->{r} <=> $b->{r} } @losers ) {
        # say sprintf( '%-20s %4d %4d    %.3f', $p->{President}, $p->{w}, $p->{l}, $p->{r} );
        delete $pres{$p->{President}};
    }
    $presidents{$_->{President}}->{"survived_$round"}++ foreach values %pres;

    # say "";
    return @losers;
}


sub battle( $round ) {
    my %wins;
    my %losses;

    # foreach iter:
    #   copy the list of all presidents
    #   while true:
    #       pick a pres at random
    #       pick another pres at random
    #       they fight
    #       record winner
    #       winner does NOT return to pool

    foreach my $iter ( 1..$BATTLE_ITERS ) {
        my @presidents = map { $_->{President} } values %pres;

        while( @presidents > 1 ) {
            my $first_index = int( rand( scalar( @presidents ) ) );
            my $first = splice( @presidents, $first_index, 1 );

            my $second_index = int( rand( scalar( @presidents ) ) );
            my $second = splice( @presidents, $second_index, 1 );

            my $score_1 = $pres{$first}->{"Round $round"};
            my $score_2 = $pres{$second}->{"Round $round"};

            my $result = rand( $score_1 + $score_2 );

            my $winner;

            if( $result <= $score_1 ) {
                $wins{$first}++;
                $losses{$second}++;
                $winner = $first;
            } else {
                $wins{$second}++;
                $losses{$first}++;
                $winner = $second;
            }

            # say "Iteration $iter: Picked $first ($score_1) vs $second ($score_2): " . uc( $winner ) . " WINS";
        }
    }

    foreach my $p ( sort keys %pres ) {
        my $w = $wins{$p};
        my $l = $losses{$p};
        my $ratio = 1.0 * $w / ( $w + $l );
        $pres{$p}->{w} = $w;
        $pres{$p}->{l} = $l;
        $pres{$p}->{r} = $ratio;
    }
}



__DATA__
Order	President	Age Entering Office	Age (years)	Age (norm)	Height	Height (norm)	Weight	Weight (norm)	Physical Robustness	Cognitive Competency	Decision Making	Social Awareness	Relationship Awareness	Martial Acumen	Round 1	Round 2	Round 3	Round 4
1	Washington	57Y, 68D	57	4.2	74	8.3	175	3.1	6.5	9.2	9.5	9.3	8.4	9	93.3	94.7	89.0	72.3
2	Adams the Elder	61Y, 125D	61	5.3	67	2.5	150	2.1	5.5	1.5	4.8	1	1.7	0	32.9	33.2	28.9	24.2
3	Jefferson	57Y, 325D	57	4.2	74.5	8.8	174	3.1	7.3	2.6	7.2	8.6	9.2	7	77.0	78.2	74.8	60.5
4	Madison	57Y, 353D	57	4.2	64	0.0	100	0.0	7	2.5	1.8	6.1	8.4	7	51.1	54.8	47.2	35.1
5	Monroe	58Y, 310D	58	4.4	72	6.7	189	3.7	5	8.5	9.2	3.2	9.2	9	80.5	82.4	77.6	64.6
6	Adams the Younger	57Y, 236D	57	4.2	67.5	2.9	175	3.1	8.1	0.9	4.4	2.3	2.2	0	37.0	38.3	35.1	29.7
7	Jackson	61Y, 354D	61	5.3	73	7.5	140	1.7	1.5	2.7	5.5	3.1	0.7	10	45.4	48.4	50.7	47.7
8	Van Buren	54Y, 89D	54	3.3	66	1.7	164	2.7	5.5	7.5	7.5	3.5	3.5	0	53.3	52.6	44.3	33.7
9	Harrison the Elder	68Y, 23D	68	7.2	68	3.3	162	2.6	0.5	7.5	0.5	4.7	3.3	9	50.4	51.3	45.6	37.0
10	Tyler	51Y, 6D	51	2.5	72	6.7	160	2.5	3.3	7.5	7.5	1.1	1	5	49.3	50.7	51.5	47.4
11	Polk	49Y, 123D	49	1.9	68	3.3	174	3.1	5.5	7.5	8.2	9.3	7.8	5	75.7	75.9	66.9	49.8
12	Taylor	64Y, 100D	64	6.1	68	3.3	170	2.9	2.1	7.3	8.1	3.3	1.7	9	59.3	61.8	56.5	48.5
13	Fillmore	50Y, 183D	50	2.2	69	4.2	174	3.1	7.2	7.5	2.1	8.8	1.6	4	55.4	57.0	53.6	43.9
14	Pierce	48Y, 101D	48	1.7	70	5.0	144	1.8	2.4	1.7	2.1	5	1.1	4	31.1	31.7	32.6	28.3
15	Buchanan	65Y, 315D	65	6.4	72	6.7	198	4.1	6.3	8.8	1.7	0.9	0.9	7	52.2	55.3	55.8	52.5
16	Lincoln	52Y, 20D	52	2.8	76	10.0	180	3.3	7.2	4.9	9.8	8.8	9.5	7	86.0	86.8	83.9	68.5
17	Johnson, A.	56Y, 107D	56	3.9	70	5.0	174	3.1	4.8	5.5	0.5	0.8	1.1	4	34.6	36.4	37.3	35.0
18	Grant	46Y, 311D	46	1.1	68	3.3	156	2.3	6.7	3.3	8.2	2.1	5	9	53.8	59.7	59.5	53.0
19	Hayes	54Y, 151D	54	3.3	68.5	3.8	175	3.1	7.4	7.5	4	2.5	2.3	9	54.7	60.3	59.9	54.7
20	Garfield 	49Y, 105D	49	1.9	72	6.7	184	3.5	8.3	7.5	0.9	9.1	0.8	9	59.6	64.4	66.3	59.2
21	Arthur	51Y, 349D	51	2.5	74	8.3	224	5.2	2.6	7.5	4.5	7.5	5.8	5	66.2	64.4	61.6	49.4
22,24	Cleveland x2	47Y, 351D	47	1.4	71	5.8	260	6.7	4	7.1	3.7	5.1	4.3	0	53.0	50.3	46.6	36.2
23	Harrison the Younger	55Y, 196D	55	3.6	66	1.7	160	2.5	6.7	8.1	6.8	1.7	3.8	8	58.5	63.4	59.1	51.4
25	McKinley	54Y, 34D	54	3.3	67	2.5	199	4.1	5.3	7.5	7.5	9.2	8	8	78.9	80.6	70.9	53.7
26	Teddy Roosevelt	42Y, 322D	42	0.0	70	5.0	210	4.6	8.2	1.5	5.5	9.3	8.9	10	69.1	74.0	72.5	59.2
27	Taft	51Y, 170D	51	2.5	71.5	6.3	340	10.0	0.5	1.8	1.2	2.8	4.1	0	35.9	31.9	30.2	23.0
28	Wilson	56Y, 66D	56	3.9	71	5.8	170	2.9	0.7	6.5	0.8	3.2	5.5	0	41.3	37.1	32.5	23.4
29	Harding	55Y, 122D	55	3.6	72	6.7	173	3.0	0.7	8.8	2.1	5.5	1.7	0	45.7	41.4	37.4	28.8
30	Coolidge	51Y, 29D	51	2.5	70	5.0	148	2.0	4.3	1.5	3.2	9.8	5.1	0	47.8	45.1	39.4	26.8
31	Hoover	54Y, 206D	54	3.3	71.5	6.3	187	3.6	6.9	8.8	1.1	0.9	2.1	0	43.5	43.2	42.7	38.1
32	Franklin Roosevelt	51Y, 33D	51	2.5	74	8.3	188	3.7	0.5	8.8	9.9	9.5	7.6	0	76.9	70.3	61.4	43.1
33	Truman	60Y, 339D	60	5.0	69	4.2	167	2.8	4.1	9.1	9.2	2.8	3.8	7	66.9	68.8	63.1	53.3
34	Eisenhower	62Y, 98D	62	5.6	70.5	5.4	171	3.0	4	7.7	7.7	5.5	8.8	9	78.1	79.4	72.2	57.7
35	Kennedy	43Y, 236D	43	0.3	73	7.5	173	3.0	1.7	6.9	3.3	9.3	7.3	9	65.1	65.4	64.2	51.4
36	Johnson (LBJ)	55Y, 27D	55	3.6	75.5	9.6	200	4.2	5.6	2.7	1	0.8	8.7	2	47.1	45.9	47.3	40.5
37	Nixon	56Y, 11D	56	3.9	71.5	6.3	175	3.1	3.3	2.8	1	3.8	1.8	2	34.8	33.9	33.6	28.8
38	Ford 	61Y, 26D	61	5.3	72	6.7	190	3.8	7.8	3.1	2.4	1.8	4.7	7	51.1	54.8	55.7	50.7
39	Carter	52Y, 111D	52	2.8	69.5	4.6	190	3.8	6.9	2.3	1	0.8	2.1	5	33.5	37.3	39.7	37.9
40	Reagan	68Y, 348D	68	7.2	73	7.5	185	3.5	5.5	4.2	5.4	9.3	9.3	3	76.3	73.4	64.1	46.9
41	Bush the Elder	64Y, 222D	64	6.1	71.5	6.3	191	3.8	4.9	8.8	8.6	8.5	6	9	85.3	86.5	79.0	63.7
42	Clinton	46Y, 154D	46	1.1	74	8.3	223	5.1	5	2.8	2.4	9.4	0.5	0	44.9	42.8	43.4	35.5
43	Bush the Younger	54Y, 198D	54	3.3	74	8.3	196	4.0	9.7	6.5	3.7	7.2	5.8	2	67.7	67.8	65.4	54.0
44	Obama	47Y, 169D	47	1.4	73	7.5	180	3.3	7.1	9.9	8.1	8.8	7.4	0	78.9	76.1	69.3	52.8
45	Trump	70Y, 220D	70	7.8	75	9.2	239	5.8	4.7	7.8	1.8	1.8	4.1	0	55.7	52.1	48.7	40.8
46	Biden	78Y, 61D	78	10.0	71.5	6.3	178	3.3	1.3	0.9	1	1.8	1.9	0	32.4	28.6	23.8	18.6