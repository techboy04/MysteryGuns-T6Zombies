#include maps\mp\_utility;
#include maps\_utility;
#include maps\_effects;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_ai_brutus;
#include maps\mp\zombies\_zm_afterlife;
#include maps\mp\zm_alcatraz_classic;


main()
{
	if(getDvarInt("enable_mysteryguns") == 1)
	{
		replacefunc(maps\mp\zombies\_zm_ai_brutus::wait_on_box_alarm, ::wait_on_box_alarm_new);
		replacefunc(maps\mp\zombies\_zm_ai_brutus::get_best_brutus_spawn_pos, ::get_best_brutus_spawn_pos_new);
		replacefunc(maps\mp\zm_alcatraz_classic::fake_kill_player, ::fake_kill_player_new);
	}
}

wait_on_box_alarm_new()
{
    while ( true )
    {
        self.zbarrier waittill( "randomization_done" );
        level.num_pulls_since_brutus_spawn++;

        if ( level.brutus_in_grief )
            level.brutus_min_pulls_between_box_spawns = randomintrange( 7, 10 );

        if ( level.num_pulls_since_brutus_spawn >= level.brutus_min_pulls_between_box_spawns )
        {
            rand = randomint( 1000 );

            if ( level.brutus_in_grief )
                level notify( "spawn_brutus", 1 );
            else if ( rand <= level.brutus_alarm_chance )
            {
                if ( flag( "moving_chest_now" ) )
                    continue;

                if ( attempt_brutus_spawn( 1 ) )
                {
                    if ( level.next_brutus_round == level.round_number + 1 )
                        level.next_brutus_round++;

                    level.brutus_alarm_chance = level.brutus_min_alarm_chance;
                }
            }
            else if ( level.brutus_alarm_chance < level.brutus_max_alarm_chance )
                level.brutus_alarm_chance = level.brutus_alarm_chance + level.brutus_alarm_chance_increment;
        }
		wait 0.1;
    }
}

get_best_brutus_spawn_pos_new( zone_name )
{

}

fake_kill_player_new( n_start_pos )
{

}