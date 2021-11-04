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
    # @results = conduct_round( 1, 21 );
    # @results = conduct_round( 2, 8 );
    # @results = conduct_round( 3, 8 );
    @results = conduct_round( 4, 7 );

    my $winner = $pres{ ( keys %pres )[0] };
    # say "Winner: " . uc( $winner->{President} );
    $winners{$winner->{President}}++;
}

say "\n";

say "Battle iterations:\t$BATTLE_ITERS";
say "Simulation runs:\t$SIM_ITERS";

say "";

say join( "\t", 'Name', 'Round 4 %' );
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
Order	President	Age Entering Office	Age (years)	Age (norm)	Height	Height (norm)	Weight	Weight (norm)	Physical Robustness	Cognitive Competency	Decision Making	Social Awareness	Relationship Awareness	Martial Acumen	Character (rd 1 and 2)	Character (rd 3 and 4)	Round 1	Round 2	Round 3	Round 4
1	Washington	57Y, 68D	57	4.2	74	8.3	175	3.1	6.5	9.2	9.5	9.3	8.4	9	6	4	104.1	103.7	94.2	76.7
5	Monroe	58Y, 310D	58	4.4	72	6.7	189	3.7	5	8.5	9.2	3.2	9.2	9	1	9	82.3	83.9	89.3	74.5
16	Lincoln	52Y, 20D	52	2.8	76	10.0	180	3.3	7.2	4.9	9.8	8.8	9.5	7	7	3	98.6	97.3	87.8	71.8
18	Grant	46Y, 311D	46	1.1	68	3.3	156	2.3	6.7	3.3	8.2	2.1	5	9	6	4	64.6	68.7	64.7	57.4
20	Garfield 	49Y, 105D	49	1.9	72	6.7	184	3.5	8.3	7.5	0.9	9.1	0.8	9	7	3	72.2	74.9	70.2	62.5
23	Harrison the Younger	55Y, 196D	55	3.6	66	1.7	160	2.5	6.7	8.1	6.8	1.7	3.8	8	8	2	72.9	75.4	61.7	53.6
25	McKinley	54Y, 34D	54	3.3	67	2.5	199	4.1	5.3	7.5	7.5	9.2	8	8	1	9	80.7	82.1	82.6	63.6
34	Eisenhower	62Y, 98D	62	5.6	70.5	5.4	171	3.0	4	7.7	7.7	5.5	8.8	9	8	2	92.5	91.4	74.8	59.9